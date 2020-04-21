set term pngcairo
set out "sample6_b.png"
unset key
set xlabel "t"
set ylabel "y"
p [0.5:10.5] "test6_b.dat" u 1:2:3 w errorbars pt 6
