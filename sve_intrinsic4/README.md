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

