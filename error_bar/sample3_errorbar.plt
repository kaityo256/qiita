set term pngcairo
set out "sample3_errorbar.png"
set xlabel "N"
set log x
unset key
p [2:4096] "test3.dat" u 1:2:3 w errorbars pt 6, 0.5
