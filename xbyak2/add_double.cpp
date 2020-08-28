#include <cstdio>
#include <xbyak/xbyak.h>

struct AddDouble : Xbyak::CodeGenerator {
  AddDouble() {
    addsd(xmm0, xmm1);
    ret();
  }
};

int main() {
  AddDouble a;
  auto f = a.getCode<double (*)(double, double)>();
  printf("%f\n", f(1.2, 3.4));
}
