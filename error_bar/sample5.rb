def func(x, delta)
  y = Math.exp(-x * 0.2) + 0.1 * Math.sin(x * 3 + delta)
  y
end

def draw(delta)
  x = 0.1
  while x < 10
    y = func(x, delta)
    puts "#{x} #{y}"
    x += 0.1
  end
end

3.times do
  delta = rand * 2 * Math::PI
  draw(delta)
end
