# JITアセンブラXbyakを使ってみる（その４）

* [その１：Xbyakの概要](https://qiita.com/kaityo256/items/a9e6d32f20096d791817)
* [その２：数値計算屋のハマりどころ](https://qiita.com/kaityo256/items/948eb0c9a69d2f474614)
* [その３：AAarch64向けの環境構築](https://qiita.com/kaityo256/items/012f858630f32672e05d)
* [その４：Xbyakからの関数呼び出し](https://qiita.com/kaityo256/items/74496f3d927339b12cfc)
* その５：XByakにおけるデバッグ←イマココ

## はじめに

全国のXbyakerの皆さんこんにちは。Xbyak初心者のkaityo256です。Xbyakを使ってて、これは組み込み関数やインラインアセンブラとは全く違うものだ、ということがようやくわかって来ました。本稿では、Xbyakにおけるデバッグについて書いてみたいと思います。

## 文字の出力

たまに話題になる「プログラムでHello Worldを出力できますか？」という問題があります。「文字出力」というのはプログラムの基本ですが、その動作原理は意外に奥が深かったりします[^puts]。プログラムで`puts`を実行して端末に文字が表示される際、どのようなプロセスを経るかはOSによって異なります。とりあえずLinuxでは、「全てはファイルである」というポリシーから、「標準出力」というファイルにデータを書き込むという処理をOSに依頼することになります[^1]。

[^puts]: よくTOKIO的に「どこまで使っていいの？」が話題になります。OSのシステムコールは使って良いのか？BIOSファンクションは？テキストVRAMに直接書き込むの？etc.

[^1]: OSがシステムコールを受け取ってから文字列が表示されるまでには、さらに複数のステップがあります。昔はテキストVRAMに書き込んだりしたのですが、今はフォントを読み込んで、画面のどこに表示されるのかを計算して……

具体的には、以下のような処理をすることになります。

* `rax`にシステムコール番号1をセットする(write)。
* `rdi`にファイルディスクリプタ番号1をセットする(標準出力)。
* `rsi`に文字列の先頭アドレスをセットする。
* `rdx`に文字数をセットする。
* `syscall`を呼ぶ。

これをXbyakで実装するとこんな感じでしょうか。以下はLinuxのシステムコールを使っているので、Linuxでしか動きません。

```cpp:hello.cpp
#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

const char *str = "Hello World!\n";

struct Code : Xbyak::CodeGenerator {
  Code() {
    int n = std::strlen(str);
    mov(rax, 1);
    mov(rdi, 1);
    mov(rsi, (size_t)str);
    mov(rdx, n);
    syscall();
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
```

実行するとこんな感じになります。なお、私の環境では`CPLUS_INCLUDE_PATH`にXbyakへのパスが通っています。

```sh
$ g++ hello.cpp
$ ./a.out
Hello World!
```

さて、ここまでのコードでは、単にグローバル変数を表示しているだけの静的なコードなのでXbyak的ではありません。次に、任意の桁数の数字を表示するコードを書いてみましょう。Xbyakは、実行時にコードを作ることができます。普通に組むなら、桁数をカウントし、例えばスタックに文字列をpushして、そのアドレスを表示、などとするのでしょうが、Xbyakなら`db`のような静的なディレクティブを動的に使うことができます。こんな感じです。

```cpp:num.cpp
#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    Xbyak::Label num;
    std::string s = std::to_string(i);
    int n = s.length();
    mov(rax, 1);
    mov(rdi, 1);
    mov(rsi, num);
    mov(rdx, n + 1);
    syscall();
    ret();
    L(num);
    for (int i = 0; i < n; i++) {
      db(s[i]);
    }
    db(0x0a);
  }
};

int main() {
  for (int i = 0; i < 10; i++) {
    Code c(1 << i);
    auto f = c.getCode<void (*)()>();
    f();
  }
}
```

2^nをn=1から9まで表示しています。実行するとこんな感じです。

```sh
$ g++ num.cpp
$ ./a.out
1
2
4
8
16
32
64
128
256
512
```

1桁から3桁の数字がちゃんと表示されていますね。

インラインアセンブラや組み込み関数は、あくまでC++のコードの一部をアセンブリで補完しているにすぎませんが、Xbyakの使用イメージは「C++を使ってアセンブリのコードを作る」つまりコードジェネレータになっています。いや、まんま`Xbyak::CodeGenerator`って書いてあるんですが、この「コードでコードを作っている」という感覚がわかるのに結構時間がかかりました。ここまでが長い前置きです。

## Xbyakでのデバッグ

さて、Xbyakでは動的にコードを生成し、実行することができます。それを利用してFizz Buzzを書いてみましょう。以下、意図的に冗長に書いています。

```cpp:fizzbuzz.cpp

```