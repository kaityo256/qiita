size = 10
puts format("L%{size}.dat", size: size.to_s.rjust(3, "0"))
