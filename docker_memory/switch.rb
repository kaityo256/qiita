# frozen_string_literal: true

if ARGV.size != 2
  puts "usage: ruby switch.rb max num"
  exit
end

$max_level = ARGV[0].to_i
num = ARGV[1].to_i

def print_switch(num, level)
  indent = "  "*level + "  "
  puts "#{indent}switch(i#{level}){"
  num.times do |i|
    puts "#{indent}  case #{i}:"
    if level < $max_level
      print_switch(num, level+1)
    else
      puts "#{indent}    return #{i};"
    end
  end
  puts "#{indent}}"
end

arg = Array.new($max_level+1) { |i| "int i"+i.to_s }.join(",")
puts "int func(#{arg}){"
print_switch(num, 0)
puts "}"
