#include <stdio.h>

int plus(int a, int b) {
  for (int i = 0; i < b; i++) {
    a++;
  }
  return a;
}

int times(int a, int b) {
  int result = 0;
  for (int i = 0; i < b; i++) {
    result = plus(result, a);
  }
  return result;
}

int main(int argc, char *argv[]) {
  int a, b;
  sscanf(argv[1], "%d", &a);
  sscanf(argv[2], "%d", &b);

  printf("%d\n", times(a, b));

  return 0;
}

