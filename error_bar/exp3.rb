10.times do |i|
  x = i + 1
  y = Math.exp(-0.2*x) + 0.3*Math.sin(10.0*x)
  puts "#{x} #{y}"
end
