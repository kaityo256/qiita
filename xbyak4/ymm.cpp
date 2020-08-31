#include <cstdio>
#include <x86intrin.h>

void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
}


double a[] = {1.0, 2.0, 3.0, 4.0};
int main() {
  __m256d va = _mm256_load_pd(a);
  print_m256d(va);
}
