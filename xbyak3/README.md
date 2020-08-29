# JITアセンブラXbyakを使ってみる（その３）

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

## SVEの確認

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



# 確認

docker run -it -u user 

AArch64でSVEが使えるか確認してみよう。まずはSVEの組み込み関数を使ってみる。

```cpp
#include <cstdio>
#include <arm_sve.h>

int main(){
  printf("%d\n",svcntd());
}
```

`svcntd`命令は、実行中の石でのSIMD長を教えてくれるものだ。SVE命令は頭に`sv`が付く。`cnt`はおそらくcountで、最後の`d`は`double`だと思う。要するにレジスタに入る`double`の数を教えてくれる。

コンパイル、実行してみよう。

```cpp
```

```sh
mkdir xbyak_test
cd xbyak_test
git init .
git submodule add -b master https://github.com/fujitsu/xbyak_aarch64.git
export CPLUS_INCLUDE_PATH=xbyak_aarch64
```

