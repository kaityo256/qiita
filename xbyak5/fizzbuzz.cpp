#include <cstdio>
#include <cstring>
#include <xbyak/xbyak.h>

const char *fizz = "Fizz\n";
const char *buzz = "Buzz\n";
const char *fizzbuzz = "Fizz Buzz\n";

struct Code : Xbyak::CodeGenerator {
  Code(int i) {
    mov(rax, 1);
    mov(rdi, 1);
    if (i % 15 == 0) {
      mov(rbx, (size_t)&fizzbuzz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(fizzbuzz));
      syscall();
    } else if (i % 3 == 0) {
      mov(rbx, (size_t)&fizz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(fizz));
      syscall();
      ret();
    } else if (i % 5 == 0) {
      mov(rbx, (size_t)&buzz);
      mov(rsi, ptr[rbx]);
      mov(rdx, strlen(buzz));
      syscall();
      ret();
    } else {
      std::string s = std::to_string(i);
      int n = s.length();
      Xbyak::Label num;
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
  }
};

int main() {
  for (int i = 1; i < 30; i++) {
    Code c(i);
    auto f = c.getCode<void (*)()>();
    f();
  }
}
