#include <cstdio>

int main() {
  size_t p = (size_t)puts;
  printf("%p\n", p);
  puts("Hello");
}
