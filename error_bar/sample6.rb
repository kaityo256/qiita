NDATA = 10
NSAMPLE = 20

srand(1)

def func(x, delta, a_sin)
  y = Math.exp(-x * 0.2) + (rand - 0.5) * 0.1
  y += a_sin * Math.sin(x * 10.0 + delta)
  y
end

def stat(d)
  n = d.size.to_f
  ave = d.sum / n
  ave2 = d.map { |i| i ** 2 }.sum / n
  sigma = Math.sqrt((ave2 - ave ** 2) / (n - 1.0))
  return ave, sigma
end

def run(filename, a_sin)
  data = Array.new(NDATA) { [] }

  NSAMPLE.times do
    delta = rand * 2 * Math::PI
    NDATA.times do |i|
      y = func(i, delta, a_sin)
      data[i].push y
    end
  end

  open(filename, "w") do |f|
    NDATA.times do |i|
      a, s = stat(data[i])
      f.puts "#{i} #{a} #{s}"
    end
  end
  puts filename
end

run("test6_a.dat", 0.0)
run("test6_b.dat", 0.3)
