#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

int main() {
  int i;
  size_t p = (size_t)add_one;
  __asm__(
      "mov $12345,%%edi\n\t"
      "movq %1,%%rax\n\t"
      "callq *%%rax\n\t"
      "mov %%eax, %0\n\t"
      : "=m"(i)
      : "m"(p)
      :);
  printf("%d\n", i);
}
