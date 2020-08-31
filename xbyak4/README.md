# JITアセンブラXbyakを使ってみる（その４）

* [その１：Xbyakの概要](https://qiita.com/kaityo256/items/a9e6d32f20096d791817)
* [その２：数値計算屋のハマりどころ](https://qiita.com/kaityo256/items/948eb0c9a69d2f474614)
* その３：AAarch64向けの環境構築
* その４：Xbyakからの関数呼び出し←イマココ

## はじめに

全国のXbyakerの皆さんこんにちは。Xbyak初心者のkaityo256です。Xbyak初心者というか、わかっていないのはアセンブリだということがわかってきた今日この頃です。さて、本稿ではXbyakからの関数呼び出しについてまとめてみます。

## 関数呼び出し

### インラインアセンブラ

C++でインラインアセンブラや組み込み関数を使っている場合には、関数呼び出しについて考える必要はありません。そのままC++の枠組みで関数を呼べばよいからです。しかし、Xbyakから関数を呼ぶのはちょっとだけ注意が必要です。

以下のような関数を考えます。

```cpp
int add_one(int i){
  return i+1;
}
```

整数を受け取って1を加えて返す関数です。この関数を`add_one(12345)`と、引数に12345を入れて呼び、その返り値を表示したいとします。

これを(無意味ですが)インラインアセンブラから呼ぶのは、こんな感じになるでしょうか。

```cpp
#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

int main() {
  int i;
  __asm__(
      "mov $12345,%%edi\n\t"
      "call _Z7add_onei\n\t"
      "mov %%eax, %0\n\t"
      : "=m"(i)
      :
      :);
  printf("%d\n", i);
}
```

整数の第一引数は(Linuxなら)ediに入れます。返り値は`eax`に入ってくるので、それを`i`で受け取っています。C++では、関数名がマングリングされるため、名前(ラベル)で`call`するためには`_Z7add_onei`とする必要があります。一応コンパイル、実行してみましょうか。

```sh
$ g++ call.cpp
$ ./a.out
12346
```

さて、コンパイルされてしまったコードはラベルは消えてアドレスになってしまうため、Xbyakから参照できません(多分)。なので、関数のアドレスをレジスタに突っ込んで、間接的に`call`することを考えます。これも無理やりインラインアセンブラで書くならこんな感じでしょうか。

```cpp
#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

int main() {
  int i;
  size_t p = (size_t)add_one;
  __asm__(
      "mov $12345,%%edi\n\t"
      "movq %1,%%rax\n\t"
      "callq *%%rax\n\t"
      "mov %%eax, %0\n\t"
      : "=m"(i)
      : "m"(p)
      :);
  printf("%d\n", i);
}
```

関数のアドレスを一度変数`p`にうけて、それを`rax`に突っ込んで`callq *rax`の形で呼んでいます。コンパイル、実行してみましょう。

```sh
$ g++ call2.cpp
$ ./a.out
12346
```

できてそうですね。

### Xbyakからの呼び出し

この二番目の方法、つまり関数のアドレスを`rax`に突っ込んで`callq *rax`する方法を、そのままXbyakで実装してみましょう。

```cpp
#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)add_one);
    call(rax);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<int (*)(int)>();
  printf("%d\n", f(12345));
}
```

そのままですね。関数`add_one`のアドレスを`rax`に代入するのは、そのまま

```cpp
mov(rax, (size_t)add_one);
```

とかけます。`callq *rax`は、Xbyakでは`call(rax)`と書いて良いようです。引数を`edi`に代入するところはC++コンパイラがやってくれるので、Xbyakはそれをそのまま`add_one`に渡してやれば、結果が`eax`に返ってくるので、そのまま`ret`すれば、それが返り値になります。コンパイル、実行してみましょう。

```sh
$ g++ call_xbyak.cpp
$ ./a.out
12346
```

問題なく呼べました。

### Xbyakからの関数呼び出しの注意点

私がXbyakから関数呼び出しをしたいのは、主にprintfデバッグのためです。SIMD化していると「いまこの場所でこのSIMDレジスタの中身を実数値として確認したい」ということがよくあります。そのため、Xbyakから`printf`を呼びたいわけですが、そのためにこんなコードを書いてみましょう。

```cpp
#include <cstdio>
#include <xbyak/xbyak.h>

void call_puts(void) {
  puts("Hello");
}

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)call_puts);
    call(rax);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
```

`puts("Hello")`を呼ぶだけの関数`call_puts`を、Xbyakから呼ぼうとしています。コンパイル、実行してみましょう。


```sh
$ g++ call_puts.cpp
$ ./a.out
zsh: segmentation fault (core dumped)  ./a.out
```

SIGSEGVで死にました。これが死ぬかどうかは環境に依存します。WSLのUbuntuでは死にましたが、例えばCentOSでは問題なく実行できました。仕組みはよくわかってませんが、おそらくこれは関数`puts`がシェアードライブラリになっており、それがロードされているかどうかに依存しています。なので、Xbyakの作った関数を呼ぶ前に`puts`を呼んでおけば問題なく実行できます。

```cpp
#include <cstdio>
#include <xbyak/xbyak.h>

void call_puts(void) {
  puts("Hello");
}

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)call_puts);
    call(rax);
    ret();
  }
};

int main() {
  puts(""); // これを挿入
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
```

コンパイル、実行してみましょう。

```sh
$ g++ call_puts2.cpp
$ ./a.out

Hello
```

無意味な改行が一つ入ってしまいましたが、問題なく実行できました。

## SIMDレジスタの表示

