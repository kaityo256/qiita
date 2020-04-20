set term pngcairo
set out "sample2_errorbar.png"
set xlabel "N"
set log x
unset key
p [2:4096] "test2.dat" u 1:2:3 w errorbars pt 6, 0.5
