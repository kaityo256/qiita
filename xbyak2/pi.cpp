#include <cstdio>
#include <x86intrin.h>

double pi(void) {
  __m128d xmm = {3.141592, 0.0};
  __asm__(
      "movups %0, %%xmm0\n\t"
      :
      : "m"(xmm));
}

int main() {
  printf("%f\n", pi());
}
