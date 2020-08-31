#include <cstdio>
#include <xbyak/xbyak.h>

int add_one(int i) {
  return i + 1;
}

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)add_one);
    call(rax);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<int (*)(int)>();
  printf("%d\n", f(12345));
}
