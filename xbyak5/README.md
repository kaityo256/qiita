# JITアセンブラXbyakを使ってみる（その５）

* [その１：Xbyakの概要](https://qiita.com/kaityo256/items/a9e6d32f20096d791817)
* [その２：数値計算屋のハマりどころ](https://qiita.com/kaityo256/items/948eb0c9a69d2f474614)
* [その３：AAarch64向けの環境構築](https://qiita.com/kaityo256/items/012f858630f32672e05d)
* [その４：Xbyakからの関数呼び出し](https://qiita.com/kaityo256/items/74496f3d927339b12cfc)
* [その５：Xbyakにおけるデバッグ](https://qiita.com/kaityo256/items/78e3e59f879c99a12945)←イマココ

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

```cpp
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

```cpp
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

```cpp
#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

const char *fizz = "Fizz\n";
const char *buzz = "Buzz\n";
const char *fizzbuzz = "Fizz Buzz\n";

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    mov(rax, 1);
    mov(rdi, 1);
    if (i % 15 == 0) {
      mov(rbx, (size_t)&fizzbuzz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(fizzbuzz));
      syscall();
    } else if (i % 3 == 0) {
      mov(rbx, (size_t)&fizz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(fizz));
      syscall();
      ret();
    } else if (i % 5 == 0) {
      mov(rbx, (size_t)&buzz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(buzz));
      syscall();
      ret();
    } else {
      std::string s = std::to_string(i);
      int n = s.length();
      Xbyak::Label num;
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
  }
};

int main() {
  for (int i = 1; i < 30; i++) {
    Code c(i);
    auto f = c.getCode<void (*)()>();
    f();
  }
}
```

コンパイル、実行してみましょう。

```sh
$ g++ fizzbuzz.cpp
$ ./a.out
1
2
Fizz
4
Buzz
Fizz
7
8
Fizz
Buzz
11
Fizz
13
14
Fizz Buzz
zsh: segmentation fault (core dumped)  ./a.out
```

i=15を実行した直後にSIGSEGVで死にました。エラーがあるようです。さて、Xbyakはコードジェネレータなので、「C++で書いたコードにバグがあるため、バグのあるアセンブリコードが出力され、それが実行されてエラーになる」という多段構造になっています。なので、まずは「バグのあるアセンブリ」を確認したくなります。

Xbyakは、生成された機械語を出力する機能`Xbyak::CodeGenerator::dump`があります。使ってみましょう。

```cpp
int main() {
  Code c(15);
  c.dump();
}
```

実行するとこうなります。

```sh
$ ./a.out
B801000000BF01000000BB98B1610048
8B33BA0A0000000F05
```

慣れてる人は、この機械語だけ見て「あっ」とか思うのでしょうが、僕はアセンブリをみないとわかりません。

で、「Xbyakにアセンブリをダンプする機能無いですか？」と聞いたら、「[アセンブリを出力する機能は無いので、objdumpを使ってほしい](https://github.com/herumi/xbyak/issues/106)」という回答をいただけました。

機械語を読むのにobjdumpを使うというのは考えたのですが、ELFヘッダをつけないといけないかなと思ってました。そのまま読めるオプションがあるとは知りませんでした。

ポイントは以下の通りです。

* `Xbyak::CodeGenerator::getCode`を`(char*)`にキャストすれば機械語のバイト列(の先頭アドレス)が得られる
* `Xbyak::CodeGenerator::getSize`で命令のバイト数がわかる
* 機械語をバイナリのままファイルに保存する
* そのままではELFヘッダが無いので、`objdump`に、ファイル形式(binary)とアーキテクチャ(i386)を教えてやるオプション(`-D -b binary -m i386`)をつけて渡す

XbyakのCodeのインスタンスを受け取って、そのアセンブリを出力する関数はこんな感じにかけるでしょうか。

```cpp
void dump_asm(Xbyak::CodeGenerator &c) {
  char tempfile[] = "/tmp/dumpXXXXXX";
  int fd = mkstemp(tempfile);
  write(fd, (char *)c.getCode(), c.getSize());
  close(fd);
  char cmd[256];
  sprintf(cmd, "objdump -D -b binary -m i386 %s", tempfile);
  FILE *fp = popen(cmd, "r");
  if (fp == NULL) {
    return;
  }
  char buf[1024];
  while (fgets(buf, sizeof(buf), fp) != NULL) {
    printf("%s", buf);
  }
  remove(tempfile);
  pclose(fp);
}
```

上記は、単に適当にテンポラリファイルを作り、そこに機械語をバイナリで吐いて、`popen`でobjdumpを起動し、その出力をもらっているだけです。こんな風に使います。

```cpp
int main() {
  Code c(15);
  dump_asm(c);
}
```

実行結果はこんな感じです。

```sh
$ ./a.out

/tmp/dumpBlCtjb:     ファイル形式 binary


セクション .data の逆アセンブル:

00000000 <.data>:
   0:   b8 01 00 00 00          mov    $0x1,%eax
   5:   bf 01 00 00 00          mov    $0x1,%edi
   a:   48                      dec    %eax
   b:   bb a8 e1 e1 c7          mov    $0xc7e1e1a8,%ebx
  10:   18 7f 00                sbb    %bh,0x0(%edi)
  13:   00 48 8b                add    %cl,-0x75(%eax)
  16:   33 ba 0a 00 00 00       xor    0xa(%edx),%edi
  1c:   0f 05                   syscall
```

最後に`ret`をつけ忘れているのがエラーの原因ですね。

## まとめ

Xbyakのデバッグについて書いてみました。これまでgdbでおいかけてアセンブリを確認していたのですが、これでアセンブリが出力できるようになったので、print文デバッグができるようになりました。例に挙げたコードはわざとらしいですが、本質的には僕が入れたバグと同じです。つまり、いくつかの条件分岐において、あるパスには必要な命令が含まれていなかったのがバグの原因でした。

Xbyakは「コードジェネレーター」であり、C++でアセンブリを組み上げるためのツールです。なので、組み込み関数やインラインアセンブラとは全く違う哲学でコードを組む必要があります(静的なコードならJITを使う旨味が無いので)。そのあたりに慣れるのに時間がかかりました。

Xbyakにもだいぶ慣れてきた気がするので、そろそろ本質的なコードを書いてみたいですね。

(続く？)
