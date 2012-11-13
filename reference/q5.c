#include <stdio.h>
#include <stdbool.h>

int main(int argc, char *argv[]) {
  int num = argc - 1;
  int nums[num];

  for (int i = 1; i < argc; i++) {
    sscanf(argv[i], "%d", &nums[i - 1]);
  }

  for (int bits = 0; bits < (1<<num); bits++) {
    int sum = 0;
    for (int i = 0; i < num; i++) {
      if (bits & (1<<i)) {
        sum += nums[i];
      }
    }

    if (sum == 21) {
      bool first = true;
      for (int i = 0; i < num; i++) {
        if (bits & (1<<i)) {
          if (first) {
            first = false;
          } else {
            printf("+ ");
          }
          printf("%d ", nums[i]);
        }
      }
      printf("= 21\n");
      return 0;
    }
  }

  printf("No sum adds to 21\n");

  return 0;
}
