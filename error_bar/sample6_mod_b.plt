set term pngcairo
set out "sample6_mod_b.png"
unset key
set xlabel "t"
set ylabel "y * exp(0.2t)"
p [0.5:10.5] "test6_b.dat" u 1:($2*exp($1*0.2)):($3*exp($1*0.2)) w e pt 6, 1
