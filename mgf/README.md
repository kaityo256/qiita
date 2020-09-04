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

