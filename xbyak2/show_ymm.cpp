#include <cstdio>
#include <x86intrin.h>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code() {
    vmovups(ptr[rdi], xmm0);
    vextractf128(xmm0, ymm0, 0x1);
    vmovups(ptr[rdi + 16], xmm0);
    ret();
  }
};

int main() {
  double x[4] = {};
  __m256d v = _mm256_set_pd(4.0, 3.0, 2.0, 1.0);
  Code c;
  auto f = c.getCode<void (*)(__m256d, double *)>();
  f(v, x);
  printf("%f %f %f %f\n", x[3], x[2], x[1], x[0]);
}
