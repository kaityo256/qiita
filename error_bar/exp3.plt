set term pngcairo
set out "exp3.png"
unset key
set xlabel "t"
set ylabel "y"
p [0:10] "exp3.dat" pt 6
