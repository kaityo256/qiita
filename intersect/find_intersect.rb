Point = Struct.new(:x, :y)

def f(p1, p2, p3)
  (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
end

def intersect?(p1, p2, p3, p4)
  t1 = f(p1, p2, p3)
  t2 = f(p1, p2, p4)
  t3 = f(p3, p4, p1)
  t4 = f(p3, p4, p2)
  t1 * t2 < 0.0 and t3 * t4
end

def intersection(p1, p2, p3, p4)
  det = (p1.x - p2.x) * (p4.y - p3.y) - (p4.x - p3.x) * (p1.y - p2.y)
  t = ((p4.y - p3.y) * (p4.x - p2.x) + (p3.x - p4.x) * (p4.y - p2.y)) / det
  x = t * p1.x + (1.0 - t) * p2.x
  y = t * p1.y + (1.0 - t) * p2.y
  return x, y
end
