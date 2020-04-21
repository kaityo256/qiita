set term pngcairo
set output "exp_noise.png"
set yrange [-0.2:1.2]

p "exp3.dat" u 1:2 pt 6 t "Data A"\
, "exp3.dat" u 1:3 pt 7 t "Data B"

set output "exp_noise2.png"

set samples 10000
p "exp3.dat" u 1:2 pt 6 t "Data A"\
, "exp3.dat" u 1:3 pt 7 t "Data B"\
, exp(-0.2*x) + 0.3*sin(x*10) lt 1 lc 0 t ""

