# ARM SVEの組み込み関数を使う（その４）

みなさん、山に登っていますか？＞直喩
僕はあまり登れていません。

ARM SVEの組み込み関数の使い方の解説を続けます。

* [その１：プレディケートレジスタ](https://qiita.com/kaityo256/items/71d4d3f6b2b77fd04cbb)
* [その２：レジスタへのロード](https://qiita.com/kaityo256/items/ac1e84f1c79fdf478630)
* [その３：gather/scatter](https://qiita.com/kaityo256/items/7ced2749875e2bab89e6)
* その４：水平演算

コードを以下に置いておきます。まだ開発中なので、記事を書きながら修正していくと思います。

[https://github.com/kaityo256/sve_intrinsic_samples](https://github.com/kaityo256/sve_intrinsic_samples)

コンパイルコマンドが長いので`ag++`という名前でaliasを張っています。詳細は「[その１](https://qiita.com/kaityo256/items/71d4d3f6b2b77fd04cbb)」を見てください。

## 水平演算について

SIMDによるベクトル演算は、複数のデータを保持するSIMDレジスタの、「要素ごと」の演算を実行します。例えば512ビットのレジスタなら倍精度実数(double)を8個保持できるため、それぞれのレジスタが`double a[8], b[8]`となっており、`c=a+b`は、

```cpp
double c[8];
for(int i=0;i<8;i++){
  c[i] = a[i]+b[i];
}
```

という演算を意味します。

さて、数値計算では、リダクション(reduction)と呼ばれる処理が頻出します。典型例が総和です。こんなイメージです。

```cpp
double sum(double *a, const int n){
  double s = 0.0;
  for(int i=0;i<n;i++){
    s += a[i];
  }
  return s;
}
```

このような計算を行うために、SIMDレジスタ内で総和をとったりする演算が用意されており、水平演算 (horizontal operations)と呼ばれます。本稿では、ARM SVEの水平演算をいくつか見てみます。

## 水平加算

水平加算とは、SIMDレジスタ内の要素の総和を返す演算です。ARM SVEには、スカラー演算と同じ結果を返すADDAと、ツリー型に和を取るADDVが用意されています。この二つは桁落ちの仕方が異なります。桁落ちの様子がわかりやすいように、$10^{-8}$と$10^8$が交互にならんだ8個のデータをSIMDレジスタにロードして、水平加算してみましょう。

```cpp
void add_vector() {
  const double a = 1e-8;
  const double b = 1e8;
  double d[8] = {a, b, a, b, a, b, a, b};
  svbool_t tp = svptrue_b64();
  svfloat64_t va = svld1_f64(tp, d);
  float64_t sum = svadda_f64(tp, 0.0, va);
  printf("adda = %.15f\n", sum);
  float64_t sum2 = svaddv_f64(tp, va);
  printf("addv = %.15f\n", sum2);
}
```

結果はこうなります。

```sh
adda = 400000000.000000000000000
addv = 400000000.000000059604645
```

ADDAは、素直に左から足していくのにたいして、ADDVは、ペアごとに足していきます。なので、ADDVはスカラーループと同じ結果が得られますが、ADDVは丸めによっては異なる結果を与えます。ADDAが素直なループ、ADDVがツリー型の和であることを確認するため、等価なスカラーコードを書いてみましょう。

```cpp
void add_scalar() {
  const double a = 1e-8;
  const double b = 1e8;
  double d[8] = {a, b, a, b, a, b, a, b};
  double sum = 0.0;
  for (int i = 0; i < 8; i++) {
    sum += d[i];
  }
  printf("adda = %.15f\n", sum);
  double s1 = d[0] + d[1];
  double s2 = d[2] + d[3];
  double s3 = d[4] + d[5];
  double s4 = d[6] + d[7];
  double s12 = s1 + s2;
  double s34 = s3 + s4;
  double sum2 = s12 + s34;
  printf("addv = %.15f\n", sum2);
}
```

実行結果はこうなります。

```sh
adda = 400000000.000000000000000
addv = 400000000.000000059604645
```

それぞれ、先ほどのADDA、ADDVを使った場合と同じ結果が得られたのがわかるかと思います。

