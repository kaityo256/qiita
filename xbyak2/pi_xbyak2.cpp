#include <cstdint>
#include <cstdio>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  uint64_t double_byte(double x) {
    unsigned char *b = (unsigned char *)(&x);
    uint64_t v = 0;
    for (int i = 0; i < 8; i++) {
      v <<= 8;
      v += b[7 - i];
    }
    return v;
  }
  Code() {
    push(rbp);
    mov(rbp, rsp);
    sub(rsp, 0x8);
    //mov(rax, 0x400921fafc8b007a);
    mov(rax, double_byte(3.141592));
    mov(ptr[rsp], rax);
    movsd(xmm0, ptr[rsp]);
    mov(rsp, rbp);
    pop(rbp);
    ret();
  }
};

int main() {
  Code c;
  auto f = c.getCode<double (*)()>();
  printf("%f\n", f());
}
