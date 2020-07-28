# 820000回マクロを展開するとGCCが死ぬ

## はじめに

Rui Ueyamaさんの[Cコンパイラ作成集中講座 (2020) 第14回](https://www.youtube.com/watch?v=dO4szb-hsrs)を聞いて知ったのですが、GCCは「同じマクロ」が定義された時に、マクロの再定義警告をしないんですね。例えばこんなコードです。

```cpp
#include <cstdio>

#define A 1
#define B 1

#define A 1 // No warning
#define B 2 // test.cpp:7:0: warning: "B" redefined

int main() {
  printf("%d %d\n", A, B);
}
```

AとBをそれぞれ再定義していますが、二回目の定義でAは同じなのにBは違う定義になっています。この時、GCCはBの再定義にだけ文句を言って、Aの再定義はスルーします。

```sh
$ g++ test.cpp
test.cpp:7:0: warning: "B" redefined
 #define B 2 // test.cpp:7:0: warning: "B" redefined

test.cpp:4:0: note: this is the location of the previous definition
 #define B 1
```

これ、マクロの等価判定は、単純に文字列の比較だけでやっており、既に定義済みのマクロを展開して比較してくれたりはしないようです。

```cpp
#include <cstdio>

#define A 1
#define B 1
#define A B // test.cpp:5:0: warning: "A" redefined

int main() {
  printf("%d\n", A);
}
```

これは、事実上はAは同じものに再定義されていますが、GCCは再定義とみなし、警告してきます。

で、ふと思ったんですよ。Cのマクロって単なる文字列展開で、その展開は多段にできますよね。これって、何段まで展開してくれるんでしょう？これってトリビアになりませんか？

このトリビアの種、つまりこういうことになります。

「コンパイラに多段のマクロ展開を食わせた時、☓☓段で力尽きる」

実際に調べてみた。

## マクロの多段展開

とりあえずマクロの多段展開をするC++コードを吐くRubyスクリプトでも書いてみましょうかね。

