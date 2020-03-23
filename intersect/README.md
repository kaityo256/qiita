# はじめに

交点判定及び交点を求めるサンプルコード。

4つの点、$P_1$, $P_2$, $P_3$, $P_4$があるとしましょう。点$P_i$の座標を$(x_i, y_i)$とします。この時、線分$P_1 P_2$と$P_3 P_4$は交点を持つか、交点を持つならその交点の座標を知りたいとします。

## 二つの線分が交点を持つか判定

線分$P_1 P_2$を通る直線の式を求めましょう。この直線の傾き$a$は

$$
a = \frac{y_2 - y_1}{x_2 - x_1}
$$

です。これが点$(x_1, y_1)$を通るので、

$$
y - y_1 = \frac{y_2 - y_1}{x_2 - x_1} (x - x_1)
$$

が求める直線の式です。分母を払って整理すると

$$
(x_2 - x_1)(y - y_1) - (y_2 - y_1) (x-x_1) = 0
$$

となります。さて、この式の右辺を$f_{12}(x, y)$としましょう。点$P_3$と点$P_4$が、この直線を挟んで反対側にあるためには、

$f_{12}(x_3, y_3) > 0$　かつ $f_{12}(x_4, y_4) <0$ 

もしくは

$f_{12}(x_3, y_3) < 0$　かつ $f_{12}(x_4, y_4) >0$ 

つまり、$f_{12}(x,y)$に点を代入した時の符号が逆でなければいけません。つまり、

$$
f_{12}(x_3, y_3) f_{12}(x_4, y_4) < 0
$$

が成り立たなければなりません。同様に、線分$P_3 P_4$が作る直線の式を$f_{34}(x,y) = 0$とすると、

$$
f_{34}(x_1, y_1) f_{34}(x_2, y_2) < 0
$$

が成り立つ必要があります。

## 二つの線分の交点

4つの点、$P_1$, $P_2$, $P_3$, $P_4$があるとしましょう。いま、線分$P_1 P_2$と$P_3 P_4$が交差することがわかっているとして、その交点$X$を求めます。

線分$P_1 P_2$上の点$X$の座標は、パラメータ$t (0<t<1)$を用いて

$$
t
\begin{pmatrix}
x_1 \\
y_1
\end{pmatrix}
+
(1-t)
\begin{pmatrix}
x_2 \\
y_2
\end{pmatrix}
$$

と書けます。また、$X$は線分$P_3 P_4$上の点でもあるので、パラメータ$s (0<s<1)$を用いて

$$
s
\begin{pmatrix}
x_3 \\
y_3
\end{pmatrix}
+ 
(1-s)
\begin{pmatrix}
x_4 \\
y_4
\end{pmatrix}
$$

とも書けます。したがって、

$$
t
\begin{pmatrix}
x_1 \\
y_1
\end{pmatrix}
+
(1-t)
\begin{pmatrix}
x_2 \\
y_2
\end{pmatrix}
=
s
\begin{pmatrix}
x_3 \\
y_3
\end{pmatrix}
+ 
(1-s)
\begin{pmatrix}
x_4 \\
y_4
\end{pmatrix}
$$

です。これを$t, s$について整理すると、

$$
\begin{pmatrix}
x_1-x_2 \\
y_1-y_2
\end{pmatrix}
t
-
\begin{pmatrix}
x_3-x_4 \\
y_3-y_4
\end{pmatrix}
s
= 
\begin{pmatrix}
x_4-x_2 \\
y_4-y_2
\end{pmatrix}
$$

となります。これを、

$$
A
\begin{pmatrix}
t \\
s
\end{pmatrix}
=
b
$$

という連立一次方程式の形に書き直すと、

$$
\begin{pmatrix}
x_1-x_2 & x_4 - x_3 \\
y_1-y_2 & y_4 - y_3
\end{pmatrix}
\begin{pmatrix}
t \\
s
\end{pmatrix}
= 
\begin{pmatrix}
x_4-x_2 \\
y_4-y_2
\end{pmatrix}
$$

です。$t, s$について解くと

$$
\begin{pmatrix}
t \\
s
\end{pmatrix}
=
\frac{1}{|A|}
\begin{pmatrix}
y_4-y_3 & x_3 - x_4 \\
y_2-y_1 & x_4 - x_3
\end{pmatrix}
\begin{pmatrix}
x_4-x_2 \\
y_4-y_2
\end{pmatrix}
$$

となります。ただし、

$$
|A| = (y_4-y_3)(x_3-x_4) - (x_3-x_4)(y_2-y_1)
$$

です。以上から、

$$
t = \frac{(y_4-y_3)(x_4-x_2) + (x_3-x_4) (y_4-y_2)}{|A|}
$$

です。点$X$の座標は

$$
\begin{pmatrix}
t x_1 + (1-t) x_2 \\
t y_1 + (1-t) y_2 \\
\end{pmatrix}
$$

と求まる。