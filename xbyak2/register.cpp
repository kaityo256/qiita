#include <cstdio>
#include <x86intrin.h>

void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
}

int main() {
  __m256d v = _mm256_set_pd(4.0, 3.0, 2.0, 1.0);
  print_m256d(v);
}
