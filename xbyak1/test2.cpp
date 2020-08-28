#include <cstdio>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    mov(eax, i);
    ret();
  }
};

int main() {
  Code c(12345);
  int (*f)() = (int (*)())c.getCode();
  printf("%d\n", f());
}
