def func(x)
  ysum = 0.0
  y2sum = 0.0
  n = 10
  n.times do
    y = x + (rand - 0.5) * 2.0
    ysum += y
    y2sum += y * y
  end
  ysum /= n.to_f
  y2sum /= n.to_f
  sigma = (y2sum - ysum ** 2) / (n - 1).to_f
  return ysum, Math.sqrt(sigma)
end

srand(1)

10.times do |i|
  x = i + 1
  y, e = func(x)
  puts "#{x} #{y} #{e}"
end
