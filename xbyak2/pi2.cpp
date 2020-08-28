#include <cstdio>
#include <x86intrin.h>

double my_pi = 3.141592;

double pi(void) {
  __asm__("movupd my_pi(%rip), %xmm0");
}

int main() {
  printf("%f\n", pi());
}
