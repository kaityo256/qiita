#include <cstdio>
#include <xbyak/xbyak.h>

void call_puts(void) {
  puts("Hello");
}

struct Code : Xbyak::CodeGenerator {
  Code() {
    mov(rax, (size_t)call_puts);
    call(rax);
    ret();
  }
};

int main() {
  puts(""); // これを挿入
  Code c;
  auto f = c.getCode<void (*)()>();
  f();
}
