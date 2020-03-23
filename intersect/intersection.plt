set term pngcairo
set output "intersection.png"

unset key
p "data1.dat" w linespoints pt 6\
, "data2.dat" w linespoints pt 6\
, "intersection.dat" pt 7 lc rgb "red"
