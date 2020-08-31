#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

int main() {
  int i;
  __asm__(
      "mov $12345,%%edi\n\t"
      "call _Z7add_onei\n\t"
      "mov %%eax, %0\n\t"
      : "=m"(i)
      :
      :);
  printf("%d\n", i);
}
