#include <cstdio>
#include <xbyak/xbyak.h>

struct Code : Xbyak::CodeGenerator {
  Code() {
    push(rbp);
    mov(rbp, rsp);
    sub(rsp, 0x8);
    mov(rax, 0x400921fafc8b007a);
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
