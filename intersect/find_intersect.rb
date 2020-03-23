Point = Struct.new(:x, :y)

def f(p1, p2, p3)
  (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
end

def intersect?(p1, p2, p3, p4)
  t1 = f(p1, p2, p3)
  t2 = f(p1, p2, p4)
  t3 = f(p3, p4, p1)
  t4 = f(p3, p4, p2)
  t1 * t2 < 0.0 and t3 * t4 < 0.0
end

def intersection(p1, p2, p3, p4)
  det = (p1.x - p2.x) * (p4.y - p3.y) - (p4.x - p3.x) * (p1.y - p2.y)
  t = ((p4.y - p3.y) * (p4.x - p2.x) + (p3.x - p4.x) * (p4.y - p2.y)) / det
  x = t * p1.x + (1.0 - t) * p2.x
  y = t * p1.y + (1.0 - t) * p2.y
  return x, y
end

def read_file(filename)
  File.read(filename).split(/\n/).map do |n|
    x, y = n.split(/\s+/)
    Point.new(x.to_f, y.to_f)
  end
end

def find_intersection(file1, file2)
  puts "reading #{file1}"
  data1 = read_file(file1)
  puts "reading #{file2}"
  data2 = read_file(file2)
  (data1.size - 1).times do |i|
    p1 = data1[i]
    p2 = data1[i + 1]
    (data2.size - 1).times do |j|
      p3 = data2[j]
      p4 = data2[j + 1]
      if intersect?(p1, p2, p3, p4)
        return intersection(p1, p2, p3, p4)
      end
    end
  end
end

open("intersection.dat", "w") do |f|
  x, y = find_intersection("data1.dat", "data2.dat")
  f.puts "#{x} #{y}"
end
puts "generated intersection.dat"
