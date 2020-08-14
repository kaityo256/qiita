# frozen_string_literal: true

def check(n)
  open("test.cpp", "w") do |f|
    f.puts "#include<cstdio>"
    n.times do |i|
      f.puts "#define A#{i} A#{i + 1}"
    end

    f.puts <<EOS
#define A#{n} 1
int main() {
  printf("%d\\n", A0);
}
EOS
  end
  system("g++ test.cpp 2> /dev/null")
end

def binary_search
  s = 100000
  e = 1000000

  while s != e && s + 1 != e
    m = (s + e) / 2
    if check(m)
      puts "#{m} OK"
      s = m
    else
      puts "#{m} NG"
      e = m
    end
  end
end

binary_search
