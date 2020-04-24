def stat(d)
  n = d.size.to_f
  ave = d.sum / n
  ave2 = d.sum { |i| i ** 2 } / n
  sigma = Math.sqrt((ave2 - ave ** 2) / (n - 1.0))
  return ave, sigma
end

def bakermap(n)
  x = rand
  d = []
  n.times do |i|
    x = x * 3
    x -= x.to_i
    d.push x
  end
  d
end

def noise(n)
  d = []
  n.times do |i|
    d.push rand
  end
  d
end

srand(1)

def sigma
  fn = File.open("noise_sigma.dat", "w")
  fb = File.open("bakermap_sigma.dat", "w")
  15.times do |i|
    n = 2 ** (4 + i)
    na, ns = stat(noise(n))
    ba, bs = stat(bakermap(n))
    fn.puts "#{n} #{na} #{ns}"
    fb.puts "#{n} #{ba} #{bs}"
  end
end

def rawdata
  File.open("noise.dat", "w") do |f|
    noise(100).each_with_index do |v, i|
      f.puts "#{i} #{v}"
    end
  end
  File.open("bakermap.dat", "w") do |f|
    bakermap(100).each_with_index do |v, i|
      f.puts "#{i} #{v}"
    end
  end
end

def samples
  fn = File.open("noise_s.dat", "w")
  fb = File.open("bakermap_s.dat", "w")
  n_count = 0
  b_count = 0
  n_trial = 100
  n_trial.times do |i|
    n = 10
    na, ns = stat(noise(n))
    ba, bs = stat(bakermap(n))
    fn.puts "#{i} #{na} #{ns}"
    fb.puts "#{i} #{ba} #{bs}"
    n_count += 1 if na - ns < 0.5 and na + ns > 0.5
    b_count += 1 if ba - bs < 0.5 and ba + bs > 0.5
  end
  puts "baker's map #{b_count.to_f / n_trial}"
  puts "noise       #{n_count.to_f / n_trial}"
end

samples
rawdata
