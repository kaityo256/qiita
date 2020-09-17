#include <cstdio>
#include <cstring>
#include <fstream>
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

void dump_asm(Xbyak::CodeGenerator &c) {
  char tempfile[] = "/tmp/dumpXXXXXX";
  int fd = mkstemp(tempfile);
  write(fd, (char *)c.getCode(), c.getSize());
  close(fd);
  char cmd[256];
  sprintf(cmd, "objdump -D -b binary -m i386 %s", tempfile);
  FILE *fp = popen(cmd, "r");
  if (fp == NULL) {
    return;
  }
  char buf[1024];
  while (fgets(buf, sizeof(buf), fp) != NULL) {
    printf("%s", buf);
  }
  remove(tempfile);
  pclose(fp);
}

int main() {
  Code c(15);
  dump_asm(c);
}
