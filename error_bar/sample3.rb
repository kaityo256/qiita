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

s = 0.0
s2 = 0.0
i = 0
10.times do |j|
  n = 2 ** (j + 2)
  while (i < n)
    i += 1
    r = rand
    s += r
    s2 += r * r
  end
  a = s / n.to_f
  a2 = s2 / n.to_f
  sigma = Math.sqrt((a2 - a ** 2) / (n - 1))
  puts "#{n} #{a} #{sigma}"
end
