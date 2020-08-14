# 822823回マクロを展開するとGCCが死ぬ

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

```rb
puts "#include<cstdio>"

N = 10

N.times do |i|
  puts "#define A#{i} A#{i + 1}"
end

puts <<EOS
#define A#{N} 1
int main(){
  printf("%d\\n",A0);
}
EOS
```

実行はこんな感じ。

```sh
ruby test.rb > test.cpp
```

出てくるソースはこんな感じになります。

```cpp
#include<cstdio>
#define A0 A1
#define A1 A2
#define A2 A3
#define A3 A4
#define A4 A5
#define A5 A6
#define A6 A7
#define A7 A8
#define A8 A9
#define A9 A10
#define A10 1
int main(){
  printf("%d\n",A0);
}
```

プリプロセッサが最終的に`A0`を`1`に展開するには、マクロを10段展開してやる必要があります。

とりあえず`N=10000`にしてみましょうか。

```sh
$ ruby test.rb > test.cpp && time g++ test.cpp && ./a.out
g++ test.cpp  0.28s user 0.34s system 92% cpu 0.672 total
```

楽勝ですね。では`N=100000`では？

```sh
$ ruby test.rb > test.cpp && time g++ test.cpp && ./a.out
g++ test.cpp  0.20s user 0.67s system 85% cpu 1.021 total
1
```

まだ余裕っぽいです。ではさらに10倍では？

```sh
$ ruby test.rb > test.cpp && time g++ test.cpp && ./a.out                              [~]
g++: internal compiler error: Segmentation fault (program cc1plus)
Please submit a full bug report,
with preprocessed source if appropriate.
See <file:///usr/share/doc/gcc-7/README.Bugs> for instructions.
g++ test.cpp  5.64s user 30.31s system 76% cpu 46.807 total
```

GCCがICEで死にましたね。

## 二分探索

`N=10000`では死なず、`N=100000`では死にました。どこかに「死ぬギリギリ」のマクロ展開数があるはずですね。手抜き二分探索で調べてみましょう。

```rb
# frozen_string_literal: true

def check(n)
  open("test.cpp", "w") do |f|
    f.puts "#include<cstdio>"
    n.times do |i|
      f.puts "#define A#{i} A#{i + 1}"
    end

    f.puts <<EOS
#define A#{n} 1
int main() {
  printf("%d\\n", A0);
}
EOS
  end
  system("g++ test.cpp 2> /dev/null")
end

def binary_search
  s = 100000
  e = 1000000

  while s != e && s + 1 != e
    m = (s + e) / 2
    if check(m)
      puts "#{m} OK"
      s = m
    else
      puts "#{m} NG"
      e = m
    end
  end
end

binary_search
```

実行してみましょう.

```sh
$ ruby search.rb
550000 OK
775000 OK
887500 NG
831250 NG
803125 OK
817187 OK
824218 NG
820702 OK
822460 OK
823339 NG
822899 NG
822679 OK
822789 OK
822844 NG
822816 OK
822830 NG
822823 NG
822819 OK
822821 OK
822822 OK
```

822822段はOKで、822823段で死にました。

## まとめ

こうしてこの世界にまた一つ
新たなトリビアが生まれた。

「822823回マクロを展開するとGCCが死ぬ」

というわけで、皆さんマクロの多段展開をしたくなっても、80万回くらいまでにしておくのが良いと思います。

## これまでのコンパイラいじめの記録

* [printfに4285個アスタリスクをつけるとclang++が死ぬ](https://qiita.com/kaityo256/items/84d8ba352009e3a0fe42)
* [定数配列がからんだ定数畳み込み最適化](https://qiita.com/kaityo256/items/bf9712559c9cd2ce4e2c)
* [C++でアスタリスクをつけすぎると端末が落ちる](https://qiita.com/kaityo256/items/d54439246edc1cc58121)
* [整数を419378回インクリメントするとMacのg++が死ぬ](https://qiita.com/kaityo256/items/6b5715b213e955d44f55)
* [コンパイラは関数のインライン展開を☓☓段で力尽きる](https://qiita.com/kaityo256/items/b4dc66c92338c0b92552)
* [関数ポインタと関数オブジェクトのインライン展開](https://qiita.com/kaityo256/items/5911d50c274465e19cf6)
* [インテルコンパイラのアセンブル時最適化](https://qiita.com/kaityo256/items/e7b05eb9c2bfbbd434a7)
* [GCCの最適化がインテルコンパイラより賢くて驚いた話](https://qiita.com/kaityo256/items/72c1bf93a210e450308c)