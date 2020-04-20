set term pngcairo
set out "sample3_sigma.png"
set xlabel "N"
set ylabel "Sigma"
set log xy
p [2:4096] "test3.dat" u 1:3 pt 6 t "Data"\
, x**-0.5*0.3 lt 1 lc 0 t "1/sqrt(N)"
