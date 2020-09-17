#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

const char *str = "Hello World!\n";

struct Code : Xbyak::CodeGenerator {
  Code() {
    int n = std::strlen(str);
    mov(rax, 1);
    mov(rdi, 1);
    mov(rsi, (size_t)str);
    mov(rdx, n);
    syscall();
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
