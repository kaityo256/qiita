# JITアセンブラXbyakを使ってみる（その３）

* [その１：Xbyakの概要](https://qiita.com/kaityo256/items/a9e6d32f20096d791817)
* [その２：数値計算屋のハマりどころ](https://qiita.com/kaityo256/items/948eb0c9a69d2f474614)
* [その３：AAarch64向けの環境構築](https://qiita.com/kaityo256/items/012f858630f32672e05d)←イマココ
* [その４：Xbyakからの関数呼び出し](https://qiita.com/kaityo256/items/74496f3d927339b12cfc)
* [その５：Xbyakにおけるデバッグ](https://qiita.com/kaityo256/items/78e3e59f879c99a12945)

## はじめに

「京コンピュータ」の次の国策スパコンである「富岳」のCPU「A64FX」は、アーキテクチャとして64ビットARMであるAArch64を採用しています。特に、HPC向けにSVE (Scalable Vector Extension)を初めて採用、実装したCPUであり、今後ARMがHPC向けのマーケットでどうなっていくのか興味があるところです。

さて、SVEは、その名の通り「スケーラブル」なSIMDで、ハードウェアのSIMD長が変わっても、同じ機械語のまま効率的に実行できるように設計されています。「富岳」のハードウェアとしてのレジスタは512ビットですが、それを意識せずにコードを実行できる、ということですが、それは裏を返せば「SIMD長が変わっても動作するようにコードを書かなければならない」ということでもあります。

さて、富岳で採用されているAArch64ですが、なんと富士通公式でXbyakが対応しています。というわけで、さっそくAArch64向けXbyakを使ってみましょう。しかし、「富岳」のノードはお高いので、よっぽど逸般の誤家庭でなければ実機はないことでしょう(Xbyakの開発者である光成さんには貸し出されているそうですが)。というわけで、プロセッサエミュレータであるQEMU上でAArch64向けコードを実行し、Xbyakの動作を確認してみましょう。

## Dockerによる環境構築

とりあえずDockerを使ってAArch64の開発環境を整えることにしましょう。ディストリビューションはなんでも良いのですが、GCCがARM向けの組み込み関数をフル実装したのは10.2からであり、それなりに新しいGCCでないと組み込み関数が使えません。GCCの最新版、しかもクロスコンパイラを自分でビルドするのはかなり面倒ですが、Archlinuxであれば、AArch64向けのGCCの10.1がパッケージとして利用可能なので、それを使うことにしましょう。他に必要なのはQEMUやgitです。まとめてインストールするDockerfileを作りましょう。

```Dockerfile
FROM archlinux
MAINTAINER kaityo256

ENV USER user
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN useradd -m ${USER}
RUN echo 'user:userpass' | chpasswd

RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm \
  aarch64-linux-gnu-gcc \
  git \
  vim \
  qemu \
  qemu-arch-extra

USER ${USER}
WORKDIR /home/${USER}
```

emacsが欲しい人は適宜追加してください。

Dockerfileを作ったら、ビルドしてログインしましょう。

```sh
docker build -t kaityo256/xbyak_aarch64_env .
docker run -it kaityo256/xbyak_aarch64_env
```

デフォルトで`user`という名前のユーザでログインします。

一応必要なものが入っているか確認しましょう。とりあえずAArch64向けのクロスコンパイラとQEMU、そしてGitとエディタが入っていればなんとかなります。

```sh
$ aarch64-linux-gnu-g++ --version
aarch64-linux-gnu-g++ (GCC) 10.2.0
Copyright (C) 2020 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

$ qemu-aarch64 --version
qemu-aarch64 version 5.1.0
Copyright (c) 2003-2020 Fabrice Bellard and the QEMU Project developers

$ git --version
git version 2.28.0

$ vim --version
VIM - Vi IMproved 8.2 (2019 Dec 12, compiled Aug 29 2020 00:50:37)
Included patches: 1-1523
Compiled by Arch Linux
(snip)
```

大丈夫そうですね。後のためにaliasを作っておきましょう。

```sh
alias ag++="aarch64-linux-gnu-g++ -static -march=armv8-a+sve -O2 "
alias vi=vim
```

コンパイラのコマンドが長いので`ag++`と別名を与えています。また、ライブラリのパスとかが面倒なので静的リンクしてしまっています(`-static`)。SVE命令を有効にするためのオプション`-march=armv8-a+sve -O2`もつけています。

## 環境の確認

## クロスコンパイル

まずはAArch64向けにクロスコンパイルできることを確認しましょう。適当なファイルを作ってコンパイルします。

```cpp
#include <cstdio>

int main(){
  puts("Hello AAarch64!");
}
```

```sh
ag++ hello.cpp
```

コンパイルしたら、`file`で確認してみましょう。

```sh
$ file a.out
a.out: ELF 64-bit LSB executable, ARM aarch64, version 1 (GNU/Linux), statically linked, BuildID[sha1]=6c11e3b56d6d7639ba2504c86380bd45f61f4e96, for GNU/Linux 3.7.0, not stripped
```

無事にARM aarch64向けのELFバイナリができたようです。QEMUで実行してみましょう。

```sh
$ qemu-aarch64 ./a.out
Hello AAarch64!
```

無事に実行できました。

## SVE

次に、SVE命令が実行できるか確認してみましょう。こんなコードを書きます。

```cpp
#include <cstdio>
#include <arm_sve.h>

int main(){
  printf("%d\n",svcntd());
}
```

GCCは新しいバージョンではSVEの組み込み関数に対応しており、`arm_sve.h`をインクルードすることで使えるようになります。SVE命令の組み込み関数、頭に「sv」というプレフィックスがついています。対応するニーモニックは`cntd`です。`cntd`は、ハードウェアに実装されているSIMDレジスタに、倍精度実数が何個入るかを返す関数で、おそらくcntはcount、dはdoubleのことだと思われます。これをコンパイルしてみましょう。

```sh
$ aarch64-linux-gnu-g++ -static sve.cpp
sve.cpp: In function 'int main()':
sve.cpp:5:26: error: ACLE function 'long unsigned int svcntd()' requires ISA extension 'sve'
    5 |     printf("%d\n",svcntd());
      |                          ^
sve.cpp:5:26: note: you can enable 'sve' using the command-line option '-march', or by using the 'target' attribute or pragma
```

そのままではSVE命令は使えないよ、と怒られます。SVE命令を使ったコードをコンパイルするためには、`-march=armv8-a+sve`と、アーキテクチャを指定してやる必要があります。もともとクロスコンパイラの名前が長い上に、いちいちこんな長いオプションをつけるのは鬱陶しいので、先ほど作ったalias「ag++」を使いましょう。

```sh
$ ag++ sve.cpp
$ qemu-aarch64 ./a.out
8
```

無事にコンパイル、実行できました。64ビットである倍精度実数は8個入る、つまりSIMDレジスタが512ビットであることがわかります。

## Xbyak_aarch64

## Xbyakの動作確認

では、いよいよXbyak_aarch64を使ってみましょう。git submoduleとして使います。注意点としては、本記事執筆時点(2020年8月30日)では、[fujitsu/xbyak_aarch64](https://github.com/fujitsu/xbyak_aarch64)のデフォルトブランチが`fjdev`になっており、そのままではうまくコンパイルできません。`master`を指定してsubmodule addしましょう。

```sh
mkdir xbyak_test
cd xbyak_test
git init .
git submodule add -b master https://github.com/fujitsu/xbyak_aarch64.git
export CPLUS_INCLUDE_PATH=xbyak_aarch64
```

最後に`CPLUS_INCLUDE_PATH`にxbyak_aarch64の場所を教えてやればXbyak_aarch64が使えるようになります。試してみましょう。

まずは単に1を返す関数です。AArch64の汎用レジスタは`x0`,`x1`, ... , `x30`です。これらは64ビットですが、`w0`, `w1`, ..., `w30`としてアクセスすると32ビットレジスタとしてアクセスすることができます。32ビットレジスタとして読みだすと、上位32ビットは0クリアされます。

関数の整数の返り値は`x0/w0`に入れます。なので、

```cpp
int func(){
  return 1;
}
```

を実装するには、`w0`に1を代入してやるだけです。

```cpp
#include <cstdio>
#include <xbyak_aarch64/xbyak_aarch64.h>

struct Code : Xbyak::CodeGenerator{
  Code (){
    mov(w0, 1);
    ret();
  }
};

int main(){
  Code c;
  auto f = c.getCode<int (*)()>();
  printf("%d\n",f());
}
```

コンパイル、実行してみましょう。

```sh
$ ag++ test.cpp
$ qemu-aarch64 ./a.out
1
```

問題なく実行できました。

次に、足し算をしてみましょう。AArch64では、整数の引数は`w0`, `w1`, ...と順番に入れられてくるため

```cpp
int func(int a, int b){
  return a+b;
}
```

を実行するためには、単に`w0`と`w1`の和を`w0`に入れてやればOKです。

```cpp
#include <cstdio>
#include <xbyak_aarch64/xbyak_aarch64.h>

struct Code : Xbyak::CodeGenerator{
  Code (){
    add(w0, w1, w0);
    ret();
  }
};

int main(){
  Code c;
  auto f = c.getCode<int (*)(int, int)>();
  printf("%d\n",f(3, 4));
}
```

これは[公式サンプル](https://github.com/fujitsu/xbyak_aarch64)を修正したもので、3+4を計算するものです。実行してみましょう。

```sh
$ ag++ test.cpp
$ qemu-aarch64 ./a.out
7
```

できたみたいですね。

## XbyakからSVEを使ってみる

ではSVE命令を使ってみましょう。まずは`cntd`です。こいつは返り値を好きな汎用レジスタに返すことができます。なので`x0`に入れてやれば、そのまま関数の返り値になります。

```cpp
#include <cstdio>
#include <xbyak_aarch64/xbyak_aarch64.h>

struct Code : Xbyak::CodeGenerator{
  Code (){
    cntd(x0);
    ret();
  }
};

int main(){
  Code c;
  auto f = c.getCode<int (*)()>();
  printf("%d\n",f());
}
```

実行してみましょう。

```sh
$ ag++ cntd.cpp
$ qemu-aarch64 ./a.out
8
```

できたみたいですね。

## まとめ

Dockerを使って64ビットARMであるAArch64の開発環境を整えて、Xbyak_aarch64の動作確認までしてみました。ハマりポイントとしては

* AArch64向けのクロスコンパイラGCCのGCC10以上が欲しいが、パッケージで簡単に入るのが(僕が知る限り)ArchLinuxしかない
* fujitsu/Xbyak_aarch64のデフォルトブランチが`fjdev`になっており、なんか動作がおかしいので、`master`を明示的に指定してやる必要がある

くらいでしょうか。

今回は環境構築と動作確認をしただけで、SVEを使った本格的なSIMD化やJITが効くようなコードの確認まではできませんでした。そのうち[できたらやります](https://dic.nicovideo.jp/a/%E8%A1%8C%E3%81%91%E3%81%9F%E3%82%89%E8%A1%8C%E3%81%8F%E3%82%8F)。

[続く](https://qiita.com/kaityo256/items/74496f3d927339b12cfc)
