
# MultiplicativeなLangevin方程式とIto/Stratonovich解釈

# はじめに

粒子が環境からランダムな力を受けるような運動を表現する運動方程式は、Langevin方程式と呼ばれる。例えば以下のようなものである。

$$
\dot{x} = -\gamma x + \sqrt{2D} \hat{R}
$$

右辺第一項は摩擦項、第二項は揺動項を表し、$\hat{R}$は

$$
\left<\hat{R}(t)\hat{R}(t') \right> = \delta(t-t') 
$$

$$
\int_t^{t+h} \hat{R}(t) dt = w(0, \sqrt{2h})
$$

を満たすような白色雑音である。ここで$w(0, \sqrt{2h})$は平均0、分散$2h$であるようなガウス分布である。

時刻$t$において$x_t$が$x < x_t < x + dx$の範囲にある確率を$F(x,t)dx$とすると、この方程式に対応するFokker–Planck方程式 (FPE)は、

$$
\frac{\partial F}{\partial t} = -\frac{\partial}{\partial x}
\left(
    -\gamma xF - D\frac{\partial F}{\partial x}
\right)
$$

となり、定常状態は

$$
F_\mathrm{eq} \propto  \exp(-\beta x^2/2)
$$

となる。ただし$\beta = \gamma /D$である。

この例のように揺動力が変数に依存しない場合、加法過程(additive process)と呼ばれ、特に難しいことはない。

しかし揺動力の振幅が変数に依存する場合、その確率過程をどのように解釈するかに任意性が生じる。揺動力が変数に依存する場合を乗法過程(Multiplicative process)と言うが、その解釈は大きく分けてIto解釈とStratonovich解釈があり、どちらの解釈を採用したかにより対応するFPEが異なるため注意が必要となる。

本稿では、Langevin方程式の数値解法と、どんな数値解法を採用したらどちらの解釈をしたことになるのかをまとめる。以下、いわゆる確率微分方程式で用いられるような表記(Wiener過程を$dz_t$で表現するなど)ではなく、Langevin方程式の形で表記するので注意されたい。

# Euler-Maruyama法

以下のようなLangevin方程式を考える。

$$
\dot{x}_t = f(x_t) + \sqrt{2D} \hat{R}(t)
$$

ただし、$D$は定数である。このLangevin方程式を数値的に積分したい。とりあえず形式的に両辺を積分してみよう。

$$
\int_t^{t+h} \dot{x}_t dt = \int_t^{t+h} \left(f(x_t) + a \hat{R}(t)\right)dt
$$

$h$の一次まで考えると、

$$
x_{t+h} - x_t = f(x_t) h +  \sqrt{2D} \int_t^{t+h} \hat{R} dt
$$

となる。

$$
\int_t^{t+h} \hat{R}(t) dt = w(0, 2h)
$$

であったから、

$$
x_{t+h} = x_t + f(x_t) h +  \sqrt{2D} w(0, 2h)
$$

として、次のステップの変数を現在のステップの変数で表現することができた。これをEuler-Maruyama法と呼ぶ。

# Ito解釈とStratonovich解釈

以下のようなLangevin方程式を考える。

$$
\dot{x} = f(x_t) + g(x_t) \hat{R}(t)
$$

これを数値積分するための、Euler法を適用したい。両辺を$t$から$t+h$まで時間積分すると

$$
\int_t^{t+h} \dot{x}_t dt = \int_t^{t+h}f(x_t)dt + \int_t^{t+h}g(x_t) \hat{R}(t) dt
$$

ここで、$\hat{R}(t)$はいたるところ微分不可能な関数なので、右辺第二項、

$$
\int_t^{t+h}g(x_t) \hat{R}(t) dt
$$

をどう解釈するかが問題となる。

## Ito解釈

単純な解釈は、$t$から$t+h$まで$g(x_t)$が定数だと思って、それに$\hat{R}(t)$がかかっているとするものである。すると、$g(x_t)$を積分の外に出せるため、

$$
\begin{aligned}
\int_t^{t+h}g(x_t) \hat{R}(t) dt & \sim g(x_t) \int_t^{t+h} \hat{R}(t) dt \\
&=  g(x_t) w(0, \sqrt{2h})
\end{aligned}
$$

となる。これをIto解釈と呼ぶ。Ito解釈に対応するFPEは

$$
\frac{\partial p}{\partial t} =
\frac{\partial}{\partial x}
\left(
f()
\right)
$$

Ito解釈に対応するEuler-Maruyama法は

$$
x_{t+h} = x_t + f(x_t) h + g(x_t) w(0, \sqrt{2h})
$$

となる。

## Stratonovich解釈

先程、積分区間を$g(x_t)$で代表させた。これを積分区間の始点と終点の値の平均で代表させてみよう。すなわち、

$$
\begin{aligned}
\int_t^{t+h}g(x_t) \hat{R}(t) dt &\sim \frac{g(x_{t+h}) + g(x_t)}{2} \int_t^{t+h} \hat{R}(t) dt\\
&= \frac{g(x_{t+h}) + g(x_t)}{2}  w(0, 2h)
\end{aligned}
$$

とする。これをStratonovich解釈と呼ぶ。Stratonovich解釈では、
