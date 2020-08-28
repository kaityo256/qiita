#include <cstdio>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    mov(eax, i);
    ret();
  }
};

int main(int argc, char **argv) {
  int i = atoi(argv[1]);
  Code c(i);
  int (*f)() = (int (*)())c.getCode();
  printf("%d\n", f());
}
