#include <cstdio>
#include <x86intrin.h>
#include <xbyak/xbyak.h>

void print_m256d(__m256d v) {
  printf("%f %f %f %f\n", v[3], v[2], v[1], v[0]);
}

double a[] = {1.0, 2.0, 3.0, 4.0};

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)a);
    vmovapd(ymm0, ptr[rax]);
    mov(rbx, (size_t)print_m256d);
    call(rbx);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
