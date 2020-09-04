# モーメント母関数

## 概要

「母関数」を使うと計算が非常に楽になることがある。ここでは確率におけるモーメント母関数について説明し、二項分布、ガウス分布、ポアソン分布のモーメント母関数を求めたあと、二項分布からガウス分布およびポアソン分布を導く。

## モーメントとは

ある確率変数$X$を考える。この確率変数の確率密度関数を$f(x)$とする。確率密度関数の定義は、離散ならば

$$
P(X=x) = f(x)
$$

であり、連続ならば

$$
P(X<x) = \int_{-\infty}^x f(x) dx
$$

である。離散確率変数$X$の関数$A$の期待値を以下のように定義する(連続版も同様)。

$$
\left< A\right> = \sum_x A f(x)
$$

ただし、和は$X$が取り得る値$x$全てについて取る。以下、確率変数$X$と、その値$x$を同一視する。この時、

$$
\left<(x-a)^n\right> = \sum_x (x-a)^n f(x)
$$

という量を、分布$f(x)$の、$a$のまわりの$n$次のモーメントと呼ぶ。例えば、平均値は$0$のまわりの一次のモーメントである。

$$
\bar{x} = \left< x \right>
$$

また、分散は平均値のまわりの二次のモーメントである。

$$
\sigma^2 = \left< (x-\bar{x}^2 \right>
$$


## モーメント母関数とは

確率変数$x$について、$e^{tx}$の期待値を考える。

$$
M(t) = \left<e^{tx}\right>
$$

これは$x$について和を取るので、$t$依存性のみ残る。この関数の性質を見てみよう。まず、両辺$t$で一回微分して$t=0$を代入する。

$$
\left. \frac{d M}{dt}\right|_{t=0} = \left< x \right> 
$$

これは$0$のまわりの1次のモーメントである。同様に二回微分して$t=0$を代入すると

$$
\left. \frac{d^2 M}{dt^2}\right|_{t=0} = \left< x^2 \right> 
$$

これは$0$のまわりの2次のモーメントである。以下、同様にすると、$M(t)$は以下のような関数であることがわかる。

$$
\begin{aligned}
M(t) &= 1 + \left<x\right>t + \left<x\right> \frac{t^2}{2!} + \cdots \\
&= \sum_{k=0} \left<x^k\right> \frac{t^k}{k!}
\end{aligned}
$$

つまり、$t$の多項式として展開すると、$t$の$k$次の項の係数に$k$次のモーメントが現れる。このように、多項式の係数に欲しい数列が現れるような関数を母関数(generating function)と呼ぶ。$M(t)$はモーメントの母関数なので、モーメント母関数と呼ばれる。

## モーメント母関数の導出

母関数を使うと計算が非常に楽になる。以下ではいくつかの分布についてモーメント母関数を求め、モーメントを求めてみよう。

### 二項分布

成功確率$p$の試行を$N$回繰り返した時、成功回数が$k$回であるような分布を二項分布(Binomial distribution)と呼ぶ。確率密度$f(k)$は

$$
f(k) =
\begin{pmatrix}
N\\
k
\end{pmatrix} p^k (1-p)^N
$$

である。この時、モーメント母関数は

$$
\begin{aligned}
M(t) &= \left<e^{tk} \right> \\
&= \sum_{k=0}^N
e^{tk}
\begin{pmatrix}
N\\
k
\end{pmatrix} p^k (1-p)^{N-k}\\
&=
\begin{pmatrix}
N\\
k
\end{pmatrix}
\left(e^{t} p\right)^k(1-p)^{N-k} \\
&= \left(1 -p + e^{t} p \right)^N
\end{aligned}
$$

と求まる。ただし、最後に二項定理

$$
(a + b)^N = \sum_{k=0}^N
\begin{pmatrix}
N\\
k
\end{pmatrix} a^k b^{N-k}
$$

を用いた。

さて、モーメント母関数が求まってしまえば、任意のモーメントが容易に求まる。一次のモーメント、すなわち期待値は

$$
\begin{aligned}
\bar{k} & \equiv \left< k \right> \\
&= \left. \frac{dM}{dt} \right|_{t=0} \\
&= \left. N(1-p+e^tp)^{N-1}e^tp \right|_{t=0} \\
&= Np
\end{aligned}
$$

二次のモーメントは

$$
\begin{aligned}
\left< k^2 \right> &= \left. \frac{d^2M}{dt^2} \right|_{t=0} \\
&= \left[ 
N(1-p+e^tp)^{N-1}e^tp+
N(N-1)(1-p+e^tp)^{N-1}e^{2t}p^2
 \right]_{t=0} \\
&= Np + N(N-1)p^2
\end{aligned}
$$

したがって分散は

$$
\begin{aligned}
\left< (k-\bar{k})^2 \right> &= \left<k^2 \right> - \left<k \right>^2\\
&= Np + N^2 p^2 - Np^2 - N^2p^2\\
&= Np(1-p)
\end{aligned}
$$

定義から「まとも」に計算するより断然楽だ。

### ガウス分布

以下の形の分布をガウス分布と呼ぶ。

$$
f(x) = C^{-1} \int_{-\infty}^\infty \exp{\left(-\frac{(x-\mu)^2}{2 \sigma^2}\right)} dx
$$

ただし$C$は規格化定数であり$\left< 1 \right> = 1$を満たすように選ぶ。

この分布のモーメント母関数を求めよう。

$$
\begin{aligned}
\left<e^{tx} \right> &= C^{-1} \int \exp{\left(tx-\frac{(x-\mu)^2}{2 \sigma^2}\right)} dx
\end{aligned}
$$

指数関数の中身を平方完成すると

$$
tx - \frac{(x-\mu)^2}{2 \sigma^2} =
-\frac{(x - \mu -t\sigma^2)^2}{2 \sigma^2} + \mu t + \frac{\sigma^2 t^2}{2}
$$

このうち、右辺第一項はガウス積分となって$C^{-1}$とキャンセルするので、

$$
M(t) = \left<e^{tx} \right> = \exp{\left( \mu t + \frac{\sigma^2 t^2}{2}\right)}
$$

これがガウス分布のモーメント母関数だ。モーメントも簡単に求まる。

$$
\left<x\right> = \left. \frac{dM}{dt} \right|_{t=0} = \mu
$$

$$
\left<x^2\right> = \left. \frac{dM^2}{dt^2} \right|_{t=0} = \mu^2 + \sigma^2
$$

したがって、分散は

$$
\left<x^2\right> - \left<x\right>^2 = \sigma2
$$

と求まる。

## ポアソン分布

単位時間あたりに平均$\lambda$回起きる事象が、単位時間あたりに$k$回起きる確率$f(k)$が

$$
f(k) = \frac{\lambda^k e^{-\lambda}}{k!}
$$

で表される時、この分布をポアソン分布と呼ぶ。

ポアソン分布のモーメント母関数を求めてみよう。

$$
\begin{aligned}
M(t) &= \left< e^{tk}\right> \\
&= \sum_{k=0}^\infty e^{tk} \frac{\lambda^k }{k!} \\
&= e^{-\lambda} \sum_{k=0}^\infty \frac{(\lambda e^t)^k}{k!} \\
&= e^{-\lambda} \exp{(\lambda e^{t})} \\
&= \exp{(\lambda (e^{t}-1))} 
\end{aligned}
$$

モーメントや分散も容易に求められる。

$$
\left< k \right> = \left. \frac{dM}{dt} \right|_{t=0} = \lambda
$$

$$
\left< k^2 \right> = \left. \frac{d^2M}{dt^2} \right|_{t=0} = \lambda + \lambda^2
$$

$$
\left<k^2\right> - \left< k \right>^2 = \lambda
$$

## 二項分布からの別の分布の導出

二項分布は、極限の取り方によってガウス分布やポアソン分布になる。それを見てみよう。

### ガウス分布の導出

確率$p$、試行回数$N$の二項分布は、平均$Np$、分散$Np(p-1)$になるのであった。$p=1/2$の時、成功回数$k$に対して

$$
x(k) = \frac{2 k - N}{\sqrt{N}}
$$

によって新しい確率変数$x$を導入すると、この変数は平均$0$、分散$1$になる。このまま$N$無限大の極限を取り、同じ平均、分散のガウス分布になることを示そう。

まず、確率変数$x$に対するモーメント母関数は、そのまま

$$
M(t) = \left<e^{tx} \right>
$$

とすれば良い(要証明)。計算しよう。

$$
\begin{aligned}
M(t) &= \left<e^{tx} \right> \\
&= \sum_{k=0}^N
\exp{\left(\frac{2kt - Nt}{\sqrt{N}} \right)}
\begin{pmatrix}
N\\
k
\end{pmatrix} p^k (1-p)^{N-k} \\
&= e^{-\sqrt{N}t}
\sum_{k=0}^N
\begin{pmatrix}
N\\
k
\end{pmatrix} e^{2kt/\sqrt{N}}p^k (1-p)^{N-k}\\
&= e^{-\sqrt{N}t}
\left(\frac{1}{2} + \frac{e^{2 t/\sqrt{N}}}{2} \right)^N \\
&= \left(\frac{e^{-t/\sqrt{N}}}{2}+\frac{e^{t/\sqrt{N}}}{2} \right)^N
\end{aligned}
$$

ここで、

$$
\frac{e^{-t/\sqrt{N}}}{2}+\frac{e^{t/\sqrt{N}}}{2} =1 + \frac{t^2}{2N} + O(N^{-2})
$$

と、指数関数の定義

$$
e^x = \lim_{N\rightarrow \infty} \left(1 + \frac{x}{N} \right)^N
$$

を使うと、$N$が大きい極限で

$$
\lim_{N\rightarrow \infty} M(t) = \exp{\left(\frac{t^2}{2} \right)}
$$

これは、平均0、分散1のガウス分布のモーメント母関数に他ならない。全てのモーメントが等しい分布は互いに等しい(要証明)なので、モーメント母関数が等しいならば、元の分布も等しい。こうして、二項分布のある種の極限としてガウス分布が得られることがわかった。

### ポアソン分布の導出

二項分布の試行回数$N$と、成功確率$p$の積$Np = \lambda$を固定したまま$N$を無限大にとると、ポアソン分布が導出される。二項分布のモーメント母関数は

$$
M(t) = (1- p + e^{t}p)^N = (1 + p(e^{t}-1))^N
$$

であった。$p = \lambda/N$であることから

$$
M(t) = \left[ 1+ 
\frac{\lambda (e^t-1)}{N}
\right]^N
$$

また指数関数の定義

$$
e^x = \lim_{N\rightarrow \infty} \left(1 + \frac{x}{N} \right)^N
$$

を使うと、$N$が大きい極限で

$$
\lim_{N\rightarrow \infty} M(t) = \exp{\left(\lambda (e^t-1)\right)}
$$

これはポアソン分布のモーメント母関数に他ならない。

## まとめ

二項分布、ガウス分布、ポアソン分布についてモーメント母関数を求め、モーメントを求めてみた。さらに、二項分布のある種の極限としてガウス分布、ポアソン分布が得られることをモーメント母関数を使って導出した。母関数は一見とっつきにくいが、母関数を使うと計算が非常に楽になることが多いので知っておくと便利だ。

母関数の応用に興味のある人は[第二種スターリング数の指数型母関数表示とその応用](https://qiita.com/kaityo256/items/06be5a8075e0c7924dbf)も参照されたい。
