f1 = open("data1.dat", "w")
f2 = open("data2.dat", "w")
10.times do |i|
  x1 = i + rand * 0.2 - 0.1
  y1 = x1 ** 2.0 + 10.0 + rand * 0.2 - 0.1
  f1.puts "#{x1} #{y1}"
  x2 = i + rand * 0.2 - 0.1
  y2 = 0.3 * x2 ** 3.0
  f2.puts "#{x2} #{y2}"
end

puts "generated data1.dat"
puts "generated data2.dat"
