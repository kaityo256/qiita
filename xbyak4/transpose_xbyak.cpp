#include <cstdio>
#include <x86intrin.h>
#include <xbyak/xbyak.h>

double a[] = {0.0, 0.1, 0.2, 0.3};
double b[] = {1.0, 1.1, 1.2, 1.3};
double c[] = {2.0, 2.1, 2.2, 2.3};
double d[] = {3.0, 3.1, 3.2, 3.3};

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)a);
    mov(rbx, (size_t)b);
    mov(rcx, (size_t)c);
    mov(rdx, (size_t)d);
    vmovapd(ymm0, ptr[rax]);
    vmovapd(ymm1, ptr[rbx]);
    vmovapd(ymm2, ptr[rcx]);
    vmovapd(ymm3, ptr[rdx]);
    vunpcklpd(ymm4, ymm0, ymm1);
    vunpckhpd(ymm5, ymm0, ymm1);
    vunpcklpd(ymm6, ymm2, ymm3);
    vunpckhpd(ymm7, ymm2, ymm3);
    vperm2f128(ymm0, ymm4, ymm6, 2 * 16 + 0 * 1);
    vperm2f128(ymm1, ymm5, ymm7, 2 * 16 + 0 * 1);
    vperm2f128(ymm2, ymm4, ymm6, 3 * 16 + 1 * 1);
    vperm2f128(ymm3, ymm5, ymm7, 3 * 16 + 1 * 1);
    vmovapd(ptr[rax], ymm0);
    vmovapd(ptr[rbx], ymm1);
    vmovapd(ptr[rcx], ymm2);
    vmovapd(ptr[rdx], ymm3);
    ret();
  }
};

void show(void) {
  printf("%f %f %f %f\n", a[0], a[1], a[2], a[3]);
  printf("%f %f %f %f\n", b[0], b[1], b[2], b[3]);
  printf("%f %f %f %f\n", c[0], c[1], c[2], c[3]);
  printf("%f %f %f %f\n", d[0], d[1], d[2], d[3]);
  puts("");
}

int main() {
  puts("Before");
  show();
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
  //transpose();
  puts("After");
  show();
}
