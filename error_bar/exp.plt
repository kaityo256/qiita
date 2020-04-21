set term pngcairo
set out "exp.png"
set samples 10000
p [0:] exp(-0.2*x) + 0.3*sin(10*x),exp(-0.2*x) lc 0 lt 1
