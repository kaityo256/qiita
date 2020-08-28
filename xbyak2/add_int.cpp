#include <cstdio>
#include <xbyak/xbyak.h>

struct AddInt : Xbyak::CodeGenerator {
  AddInt() {
    mov(eax, edi);
    add(eax, esi);
    ret();
  }
};

int main() {
  AddInt a;
  auto f = a.getCode<int (*)(int, int)>();
  printf("%d\n", f(1, 2));
}
