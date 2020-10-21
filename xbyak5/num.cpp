#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    Xbyak::Label num;
    std::string s = std::to_string(i);
    int n = s.length();
    mov(rax, 1);
    mov(rdi, 1);
    mov(rsi, num);
    mov(rdx, n + 1);
    syscall();
    ret();
    L(num);
    for (int i = 0; i < n; i++) {
      db(s[i]);
    }
    db(0x0a);
  }
};

int main() {
  for (int i = 0; i < 10; i++) {
    Code c(1 << i);
    auto f = c.getCode<void (*)()>();
    f();
  }
}
