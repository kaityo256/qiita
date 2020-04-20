def func(n)
  s = 0.0
  s2 = 0.0
  n.times do
    r = rand
    s += r
    s2 += r * r
  end
  s /= n.to_f
  s2 /= n.to_f
  sigma = Math.sqrt((s2 - s ** 2) / (n - 1))
  return s, sigma
end

srand(1)

10.times do |i|
  n = 2 ** (i + 2)
  a, e = func(n)
  puts "#{n} #{a} #{e}"
end
