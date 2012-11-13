#include <stdio.h>
#include <math.h>

int main() {
  float ax, ay, bx, by;

  scanf("%f %f %f %f", &ax, &ay, &bx, &by);

  float dx = bx - ax;
  float dy = by - ay;

  // Now to rotate it...
  float s = sinf(M_PI/6);
  float c = cosf(M_PI/6);

  float vx = dx * s + dy * c;
  float vy = dx * c - dy * s;

  printf("%.2f %.2f\n", ax + vx, ay + vy);

  return 0;
}
