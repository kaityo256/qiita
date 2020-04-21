set term pngcairo
set out "sample6_mod_a.png"
unset key
set xlabel "t"
set ylabel "y * exp(a t)"
p [0.5:10.5] "test6_a.dat" u 1:($2*exp($1*0.2)):($3*exp($1*0.2)) w e pt 6, 1
