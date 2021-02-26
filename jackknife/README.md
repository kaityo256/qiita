# Jackknife法とサンプル数バイアス

## はじめに

平均0、分散$\sigma^2$のガウス分布に従う確率変数$\hat{x}$を考えます。確率変数の2次と4次のモーメントはそれぞれ

$$
\left< \hat{x}^2 \right> = \sigma^2 
$$

$$
\left< \hat{x}^4 \right> = 3 \sigma^4
$$

です。したがって、以下のような量を考えると分散依存性が消えます。

$$
U \equiv \frac{\left< \hat{x}^4 \right>}{\left< \hat{x}^2 \right>^2} = 3
$$

これは尖度(kurtosis)と呼ばれ、ガウス分布で0とするような定義もありますが、本稿ではガウス分布で3となる上記の定義を用います。

実際に上記の量を計算して3になるか確認してみましょう。平均0、分散$\sigma^2$のガウス分布に従うN個の確率変数$\hat{x}_1, \hat{x}_2, \cdots, \hat{x}_N$を生成し、そこから

$$
\left< x^2 \right>_N = \frac{\sum_i x_i^2}{N}
$$

$$
\left< x^4 \right>_N = \frac{\sum_i x_i^4}{N}
$$

を計算します。そこから

$$
U_N = \frac{\left< x^4 \right>_N}{\left< x^2 \right>_N^2}
$$

を計算してみましょう。

まず、平均0、分散1の正規分布に従う乱数は`numpy.random.randn`で生成することができます。

```py
import numpy as np
import sympy
from matplotlib import pyplot as plt

x = np.random.randn(10000)
fig, ax = plt.subplots(facecolor='w')
n, bins, _ = ax.hist(x, bins=100)
```

![normal](normal.png)

ガウス分布になっていますね。では$N$個のデータを受け取って尖度を計算する関数`simple_estimator`を作って、$U_N$を計算します。$U_N$も確率変数になるので、それを`n_trials`回平均することで、$U_N$の期待値を計算し、$N$依存性を見てみましょう。

```py
def simple_estimator(r):
    r2 = r ** 2
    r4 = r ** 4
    return np.average(r4)/np.average(r2)**2

samples = np.array([16,32,64,128,256])
n_trials = 128**2
for n in samples:
    u = [simple_estimator(np.random.randn(n)) for _ in range(n_trials)]
    print(f"{n} {np.average(u)}")
```

結果はこんな感じになります。

```txt
16 2.665024406056554
32 2.8310461207614
64 2.9117517962292196
128 2.9536867076886937
256 2.974102994397855
```

明らかに$N$依存性が見えます。この依存性は何か、そしてどうやって回避するのかを検討するのが本稿の目的です。

## サンプル数依存性の起源

まず、先ほどの$N$依存性をプロットしてましょう。$N$が大きいほど$3$に近づいているので、$U_N$を$1/N$に対してプロットしてみます。

```py
samples = np.array([16,32,64,128,256])
y = []
n_trials = 128**2
for n in samples:
    u = [simple_estimator(np.random.randn(n)) for _ in range(n_trials)]
    y.append(np.average(u))
x = 1.0/samples
y_theory = [3.0 for _ in x]
fig, ax = plt.subplots()
plt.xlabel("1 / N")
plt.ylabel("U_N")
ax.plot(x,y,"-o",label="Simple")
ax.plot(x,y_theory,"-", label="3", color="black")
plt.show()
```

結果は以下の通りです。

![](simple.png)

きれいに$1/N$の依存性が見えます。これがどこから来ているか調べるため、2次のモーメント$\left< x^2 \right>_N$と4次のモーメント$\left< x^4 \right>_N$の$N$依存性を見てみましょう。2次のモーメントは1、4次のモーメントは3になるはずです。

```py
samples = np.array([16,32,64,128,256])
n_trials = 128**2
y = []
for n in samples:
    r2 = []
    r4 = []
    for _ in range(n_trials):
        r = np.random.randn(n)
        r2.append(np.average(r**2))
        r4.append(np.average(r**4))
    print(f"{n} {np.average(r2)} {np.average(r4)}")
```

結果はこうなります。

```txt
16 1.0069638341496114 3.052695056865599
32 1.0009326403631478 3.0048770596574004
64 1.0011522697373576 3.0051207850152353
128 1.0009699343712042 3.000195653356738
256 1.000964117125373 3.008657909674001
```

2次のモーメントは1、4次のモーメントは3であり、特に$N$依存性は見えません。

さて、尖度の定義は

$$
U \equiv \frac{\left< \hat{x}^4 \right>}{\left< \hat{x}^2 \right>^2} = 3
$$

でしたから、$\left< \hat{x}^2 \right>$から$1/\left< \hat{x}^2 \right>^2$を計算する必要があります。こいつの$N$依存性を見てみましょう。

```py
samples = np.array([16,32,64,128,256])
n_trials = 128**2
y = []
for n in samples:
    r2_inv2 = []
    for _ in range(n_trials):
        r = np.random.randn(n)
        r2_inv2.append(1.0/np.average(r**2)**2)
    print(f"{n} {np.average(r2_inv2)}")
```

```txt
16 1.5399741991666933
32 1.21947965805206
64 1.0998402893078216
128 1.0501167786713717
256 1.0252452060315502
```

$N$依存性が出てきました。つまり、$\left< \hat{x}^2 \right>$はちゃんと計算できているが、$1/\left< \hat{x}^2 \right>^2$の計算で変なバイアスが入るということです。これは、確率変数の期待値にバイアスがなくても、確率変数の期待値の(非線形)関数にはバイアスが入るからです。

## 確率変数の期待値の関数

確率変数$\hat{r}$を考えます。期待値は$\left<\hat{r}\right> = \bar{r}$、分散は$\left<(\hat{r}-\mu_r)^2\right> = \sigma^2_r$であるとしましょう。

この変数の期待値$\bar{r}$の関数$f(\bar{r})$を計算したいとします。いま、真の期待値$\bar{r}$は知らないので、この確率変数を$N$個観測して、その平均を期待値の推定値としましょう。

$$
\bar{r}_N \equiv \frac{1}{N}
$$