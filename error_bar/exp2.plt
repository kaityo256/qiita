set term pngcairo
set out "exp2.png"
set samples 10000
set xlabel "t"
set ylabel "y"
p [0:] exp(-0.2*x) + 0.3*sin(10*x) t "Exp. 1"\
,exp(-0.2*x) + 0.3*sin(10*x + 1.5) t "Exp. 2"\
,exp(-0.2*x) lc 0 lt 1 t ""
