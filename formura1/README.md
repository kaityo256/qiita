# 格子計算プログラム生成言語Formuraを使ってみる その1

## はじめに

プログラマは計算機に対して、「別に凝ったをやれとは言わないが、自明なことはやってくれよ」と思うものだ。例えば規則格子における差分法、特に陽解法は、式と差分方式さえ決まれば、(最適化とか考えなければ)後は自明なコーディングになる。さらに、領域分割による分散メモリ並列を考えた時、(効率とか考えなければ)やはり自明なだけで面倒なコーディングをする必要がある。

こういう「自明かつ面倒なコーディング」をやらなければいけなくなった時、「自動化したい」と思うのは自然な発想だ。[Formura](https://github.com/formura/formura)は、まさにそのような思想で作られた、格子計算プログラム生成言語(というかフレームワーク)である。

本稿では、このFormuraを使ってみる。

* [その1](https://qiita.com/kaityo256/items/8b6c9ca1abeeef64f414) インストールとコンパイルまで ←イマココ
* [その2](https://qiita.com/kaityo256/items/7ff1fb39986414654824) 一次元熱伝導方程式
* [その3](https://qiita.com/kaityo256/items/bfd327ecf4e79b8ab83d) 二次元熱伝導方程式
* [その4](https://qiita.com/kaityo256/items/2dd11363769cb5f29bc2) 反応拡散方程式(Gray-Scott系)

## インストール

Formuraは(おそらくオリジナルの作者の趣味で)Haskellで書かれている。なので実行にはHaskellが必要だ。例えばMacOSでbrewを使うなら

```sh
brew install haskell-stack
```

Linux系なら

```sh
curl -sSL https://get.haskellstack.org/ | sh 
```

とかで入ると思う。
次に、Formuraをダウンロードして、セットアップしよう。

```sh
git clone https://github.com/formura/formura.git
cd formura
stack install
```

最後の`stack install`は、初回実行時にかなり時間がかかる。もし、この途中で「libtinfo.soが見つからない」と怒られたら、libncursesを入れることで解決する可能性がある。僕の場合は

```sh
sudo yum install ncurses-devel
```

としてから、再度`stack install`したらいけた。

`formura`は、`$HOME/.local/bin`にインストールされるので、パスを通しておこう。

```sh
export PATH=$PATH:$HOME/.local/bin
```

パスが通ったか確認してみよう。

```sh
$ formura

Usage: formura FILES... [-o|--output-filename FILENAME] [--nc FILENAME]
               [-v|--verbose] [--ncopt ARG] [-f|--flag ARG] [--sleep SECOND]
  generate c program from formura program.
```

上記のようなメッセージが表示されたら正しくインストールされている。

## Formura言語の記述

Formuraは、数値計算、特に規則格子計算を記述する言語だ。その言語仕様は[公式リポジトリ](https://github.com/formura/formura)の「Download Formura Language Specification (pdf)」で参照できる。とりあえず必要なファイルは`*.yaml`ファイルと`*.fmr`ファイルだ。

YAMLファイルには、格子の情報を記述する。とりあえず格子間隔1、格子点64点の一次元系を定義しよう。後でGray-Scottのシミュレーションをする予定なので、`gs.yaml`というファイル名にしておく。

```yaml
length_per_node: [64.0]
grid_per_node: [64]
```

`length_per_node`が1ノードが担当する領域の長さ、`grid_per_node`が、1ノードが担当する領域のグリッド数だ。今回は1次元なのでそれぞれ要素数1のリストとして与えている。

さて、次に`gs.fmr`にFormura言語を記述する。拡張子は`fmr`とする。

```pascal
dimension :: 1
axes :: x

begin function u = init()
  double [] :: u = 0
end function

begin function u2 = step(u)
  u2 = u
end function
```

外見や、ベクトル、行列の扱いについてはFortran90ライクに見える。

最低限必要なのは

* 次元の宣言
* 軸の宣言
* 初期化関数 `init`
* 時間発展関数 `step`

の4種類だ。内容については次回説明するが、とりあえず

* `u`という一次元配列を用意して0で初期化する関数`init`
* `u`を受け取って、それをそのまま次のステップの値`u2`とする(つまり何もしない)時間発展関数`step`

を記述している。

YAMLとfmrファイルを作成したら、`formura`に食わせる。

```sh
$ formura gs.fmr
Generating code...
Generate:
  gs.c
  gs.h
  run
```

ソースコードであえる`gs.c`や`gs.h`、実行スクリプト`run`を吐く。

これを実行するための`main`関数を書こう。FormuraはC言語を吐くが、趣味でC++で書く。

```cpp
#include "gs.h"

int main(int argc, char **argv) {
  Formura_Navi n;
  Formura_Init(&argc, &argv, &n);
  Formura_Finalize();
}
```

先程作成された`gs.h`をインクルードした上で、`Formura_Init`で初期化、`Formura_Finalize`で終了する。MPIと似たインタフェースだ。

これをコンパイルする。

```sh
$ g++  main.cpp gs.c
```

C++とCのソースを混ぜてコンパイルしているので、たとえばclang++を使うと文句を言われるが、とりあえず気にしないことにする。

できたバイナリ`a.out`を実行してみる。

```sh
$ ./a.out
```

エラーなく実行できれば成功である。何もしないプログラムなので、何も表示されない。

## まとめ

格子計算プログラム生成言語Formuraをインストールし、使ってみた。まだインストールとコンパイルをしてみただけだが、次回以降、簡単なシミュレーションをしてみる予定である。

[その2](https://qiita.com/kaityo256/items/7ff1fb39986414654824)へ続く。

## 参考

* 公式リポジトリ [github.com/formura/formura](https://github.com/formura/formura)
* [やる気の出ない計算機科学シリーズ その1 初めてのFormura](https://qiita.com/hrontan/items/ae8b3d5f8e999525f4b9)
