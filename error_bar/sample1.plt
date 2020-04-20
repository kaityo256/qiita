set term pngcairo
set out "sample1.png"
unset key
set xlabel "x"
set ylabel "y"
p [0.5:10.5] "test1.dat" u 1:2:3 w errorbars, x
