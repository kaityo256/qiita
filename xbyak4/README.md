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

```cpp:call.pp
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

```cpp:call2.cpp
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

```cpp:call_xbyak.cpps
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

```cpp:call_puts.cpp
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

SIGSEGVで死にました。これが死ぬかどうかは環境に依存します。WSLのUbuntuでは死にましたが、例えばCentOSでは問題なく実行できました。仕組みはよくわかっていないのですが、おそらくこれは関数`puts`がシェアードライブラリになっており、それがロードされていないのに呼び出されたのが原因な気がします。とりあえず、Xbyakの作った関数を呼ぶ前に`puts`を呼んでおけば問題なく実行できます。

```cpp:call_puts2.cpp
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

さて、数値計算屋としての本命です。なんかYMMレジスタをいじった時、その中身を知りたいとしましょう。例えば

```cpp
double a[] = {1.0, 2.0, 3.0, 4.0};
```

という配列があり、これを`vmovapd`でYMMレジスタにロードした時、レジスタに期待通り(4.0, 3.0, 2.0, 1.0)が入っているかどうか見たいとします。組み込み関数を使うならこんな感じのコードになるでしょう。

```cpp:ymm.cpp
#include <cstdio>
#include <x86intrin.h>

void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
}

double a[] = {1.0, 2.0, 3.0, 4.0};
int main() {
  __m256d va = _mm256_load_pd(a);
  print_m256d(va);
}
```

実行するとこんな感じになります。

```sh
$ g++ -march=native ymm.cpp
$ ./a.out
4.000000 3.000000 2.000000 1.000000
```

レジスタの下位を右に書いているので、C++の配列の順番とは逆になることに注意してください。これをXbyakを使って書いてみましょう。

```cpp:ymm_xbyak.cpp
#include <cstdio>
#include <x86intrin.h>
#include <xbyak/xbyak.h>

void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
}

double a[] = {1.0, 2.0, 3.0, 4.0};

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)a);
    vmovapd(ymm0, ptr[rax]);
    mov(rbx, (size_t)print_m256d);
    call(rbx);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
```

Xbyakのコードの中身はこんな感じです。

```cpp
    mov(rax, (size_t)a); // グローバル変数aのアドレスをraxに代入
    vmovapd(ymm0, ptr[rax]); // raxの指すアドレスからymmにvmovpadで値をロード
    mov(rbx, (size_t)print_m256d); // rbxにprint_m256の関数のアドレスを代入
    call(rbx); // rbx経由でprint_m256dをcall
```

`__m256d`とかがからんだ呼び出し規約を良く知りませんが(←調べろよ)、たぶん`ymm0`、`ymm1`と順番に入れるのでしょう。print_m256dは第一引数に`ymm0`を期待しているため、`ymm0`に`vmovapd`した後にそのまま`print_m256d`を`call`すれば、`ymm0`の中身が表示されるはずです。コンパイル、実行してみましょう。

```sh
$ g++ -march=natvie ymm_xbyak.cpp
$ ./a.out
4.000000 3.000000 2.000000 1.000000
```

できてそうですね。

## レジスタの転置

次はSIMD化屋さんはみんな大好き、レジスタの転置です。YMMレジスタ4つの行と列を転置しましょう。組み込み関数で書くならこんな感じになるでしょうか。

```cpp:transpose.cpp
#include <cstdio>
#include <x86intrin.h>

double a[] = {0.0, 0.1, 0.2, 0.3};
double b[] = {1.0, 1.1, 1.2, 1.3};
double c[] = {2.0, 2.1, 2.2, 2.3};
double d[] = {3.0, 3.1, 3.2, 3.3};

void transpose(void) {
  __m256d va = _mm256_load_pd(a);
  __m256d vb = _mm256_load_pd(b);
  __m256d vc = _mm256_load_pd(c);
  __m256d vd = _mm256_load_pd(d);
  __m256d tmp0 = _mm256_unpacklo_pd(va, vb);
  __m256d tmp1 = _mm256_unpackhi_pd(va, vb);
  __m256d tmp2 = _mm256_unpacklo_pd(vc, vd);
  __m256d tmp3 = _mm256_unpackhi_pd(vc, vd);
  __m256d r0 = _mm256_permute2f128_pd(tmp0, tmp2, 2 * 16 + 1 * 0);
  __m256d r1 = _mm256_permute2f128_pd(tmp1, tmp3, 2 * 16 + 1 * 0);
  __m256d r2 = _mm256_permute2f128_pd(tmp0, tmp2, 3 * 16 + 1 * 1);
  __m256d r3 = _mm256_permute2f128_pd(tmp1, tmp3, 3 * 16 + 1 * 1);
  _mm256_store_pd(a, r0);
  _mm256_store_pd(b, r1);
  _mm256_store_pd(c, r2);
  _mm256_store_pd(d, r3);
}

void show(void){
  printf("%f %f %f %f\n",a[0],a[1],a[2],a[3]);
  printf("%f %f %f %f\n",b[0],b[1],b[2],b[3]);
  printf("%f %f %f %f\n",c[0],c[1],c[2],c[3]);
  printf("%f %f %f %f\n",d[0],d[1],d[2],d[3]);
  puts("");
}

int main(){
  puts("Before");
  show();
  transpose();
  puts("After");
  show();
}
```

コンパイル、実行してみましょう。

```sh
$ g++ -march=native transpose.cpp
$ ./a.out
Before
0.000000 0.100000 0.200000 0.300000
1.000000 1.100000 1.200000 1.300000
2.000000 2.100000 2.200000 2.300000
3.000000 3.100000 3.200000 3.300000

After
0.000000 1.000000 2.000000 3.000000
0.100000 1.100000 2.100000 3.100000
0.200000 1.200000 2.200000 3.200000
0.300000 1.300000 2.300000 3.300000
```

無事に転置できてそうですね。

これを素直にXbyakで実装するとこうなるでしょう。

```cpp:transpose_xbyak.cpp
#include <cstdio>
#include <x86intrin.h>
#include <xbyak/xbyak.h>

double a[] = {0.0, 0.1, 0.2, 0.3};
double b[] = {1.0, 1.1, 1.2, 1.3};
double c[] = {2.0, 2.1, 2.2, 2.3};
double d[] = {3.0, 3.1, 3.2, 3.3};

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)a);
    mov(rbx, (size_t)b);
    mov(rcx, (size_t)c);
    mov(rdx, (size_t)d);
    vmovapd(ymm0, ptr[rax]);
    vmovapd(ymm1, ptr[rbx]);
    vmovapd(ymm2, ptr[rcx]);
    vmovapd(ymm3, ptr[rdx]);
    vunpcklpd(ymm4, ymm0, ymm1);
    vunpckhpd(ymm5, ymm0, ymm1);
    vunpcklpd(ymm6, ymm2, ymm3);
    vunpckhpd(ymm7, ymm2, ymm3);
    vperm2f128(ymm0, ymm4, ymm6, 2 * 16 + 0 * 1);
    vperm2f128(ymm1, ymm5, ymm7, 2 * 16 + 0 * 1);
    vperm2f128(ymm2, ymm4, ymm6, 3 * 16 + 1 * 1);
    vperm2f128(ymm3, ymm5, ymm7, 3 * 16 + 1 * 1);
    vmovapd(ptr[rax], ymm0);
    vmovapd(ptr[rbx], ymm1);
    vmovapd(ptr[rcx], ymm2);
    vmovapd(ptr[rdx], ymm3);
    ret();
  }
};

void show(void) {
  printf("%f %f %f %f\n", a[0], a[1], a[2], a[3]);
  printf("%f %f %f %f\n", b[0], b[1], b[2], b[3]);
  printf("%f %f %f %f\n", c[0], c[1], c[2], c[3]);
  printf("%f %f %f %f\n", d[0], d[1], d[2], d[3]);
  puts("");
}

int main() {
  puts("Before");
  show();
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
  puts("After");
  show();
}
```

コンパイル、実行してみます。

```sh
$ g++ -march=native transpose_xbyak.cpp
$ ./a.out
Before
0.000000 0.100000 0.200000 0.300000
1.000000 1.100000 1.200000 1.300000
2.000000 2.100000 2.200000 2.300000
3.000000 3.100000 3.200000 3.300000

After
0.000000 1.000000 2.000000 3.000000
0.100000 1.100000 2.100000 3.100000
0.200000 1.200000 2.200000 3.200000
0.300000 1.300000 2.300000 3.300000
```

できてそうです。

さて、コードを書いている最中に、YMMレジスタの中身を見たいとします。例えば`vunpcklpd`で`ymm0`と`ymm1`から`ymm4`を作りましたが、この`ymm4`の値を確認したいとしましょう。

`transpose_xbyak.cpp`に、デバッグ用の関数を追加します。

```cpp
void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
  exit(-1);
}
```

どうせ値を見たいだけなので、表示と同時に`exit`してしまいましょう。

値を見たいところで、`ymm0`に見たいレジスタをコピーし、`rax`に`print_m256d`のアドレスを代入して`call *rax`しましょう。

```cpp
struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)a);
    mov(rbx, (size_t)b);
    mov(rcx, (size_t)c);
    mov(rdx, (size_t)d);
    vmovapd(ymm0, ptr[rax]);
    vmovapd(ymm1, ptr[rbx]);
    vmovapd(ymm2, ptr[rcx]);
    vmovapd(ymm3, ptr[rdx]);
    vunpcklpd(ymm4, ymm0, ymm1);

    vmovapd(ymm0, ymm4);
    mov(rax, (size_t)print_m256d);
    call(rax);

(snip)
```

`rax`や`ymm0`の値が破壊されますが、どうせデバッグ目的でそこで実行を止めてしまうので気にしないことにします。実行してみましょう。

```sh
$ g++ -march=native transpose_xbyak.cpp
$ ./a.out
Before
0.000000 0.100000 0.200000 0.300000
1.000000 1.100000 1.200000 1.300000
2.000000 2.100000 2.200000 2.300000
3.000000 3.100000 3.200000 3.300000

1.200000 0.200000 1.000000 0.000000
```

二行目の1,3列目の要素と、1行目の1,3列目の要素が交互に並んでおり、ちゃんと`vunpcklpd`できてそうだな、とわかります。

## まとめ

Xbyakから関数呼び出しをして、SIMDレジスタの中身を表示するprintfデバッグをしてみました。昨今のスパコンは性能を出すにはSIMD化が必須ですが、SIMD化は面倒だし、そもそも「数値計算屋はどこまでやるべきか」を考えるといろいろ難しい問題です。「最適化」には様々なレベルがあります。「コンパイラに任せるよ」「コンパイルオプションくらいはいろいろ試すよ」「ディレクティブは入れるよ」「コンパイラの最適化レポートは読むよ」「コンパイラの吐いたアセンブリをチェックするよ」「自分で組み込み関数で書くよ」「もうほとんどアセンブリで書くよ」、etc。正直な話、物理現象を理解しつつ、シミュレーションの振る舞い(数値誤差や安定性等)にも気を付けて、さらにMPIやOpenMPを使った並列化もしながらハードウェアの中身もきっちりわかった上でSIMD化されたコードを書け、というはかなりの無茶振りだというのは想像できるかと思います。だからといって、「私アルゴリズム考える人」「私実装する人」と分業してしまうのも、あまり明るい未来は見えません。

組み込み関数を使うよりはアセンブリに近く、生のアセンブリを書くよりはいろいろ便利、Xbyakはそんなところに位置している気がします・・・が、まだ使いこなせる気がしません・・・。

(続く？)