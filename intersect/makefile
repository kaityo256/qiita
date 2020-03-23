all: intersection.png

intersection.png: intersection.dat
	gnuplot intersection.plt

intersection.dat: data1.dat data2.dat
	ruby find_intersect.rb


