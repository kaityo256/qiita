#include <cstdio>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(eax, 1);
    ret();
  }
};

int main() {
  Code c;
  int (*f)() = (int (*)())c.getCode();
  printf("%d\n", f());
}
