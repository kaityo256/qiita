set term pngcairo
set out "sample6_a.png"
unset key
p [0.5:10.5] "test6_a.dat" u 1:2:3 w errorbars pt 6
