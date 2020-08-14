puts "#include<cstdio>"

N = 10

N.times do |i|
  puts "#define A#{i} A#{i + 1}"
end

puts <<EOS
#define A#{N} 1
int main(){
  printf("%d\\n",A0);
}
EOS
