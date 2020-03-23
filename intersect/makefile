all: intersection.png

intersection.png: intersection.dat
	gnuplot intersection.plt

intersection.dat: data1.dat
	ruby find_intersect.rb

data1.dat:
	ruby makedata.rb

.PHONY: clean

clean:
	rm -f data1.dat data2.dat intersection.dat intersection.png
