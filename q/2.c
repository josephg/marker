#include <stdlib.h>
#include <stdio.h>

struct node {
  int data;
  struct node *next;
};

typedef struct node node_t;

float average(node_t *first);

// Awful and hacky, but whatever.
void insert(node_t *list, int val) {
  // go to the end of the list.
  node_t *last;
  for (last = list; last->next != NULL; last = last->next);
  last->next = (node_t *)calloc(sizeof(node_t), 1);
  last->next->data = val;
}

void check(int val) {
  if (!val) {
    printf("TEST FAILED\n");
    exit(1);
  } else {
    printf("✓\n");
  }
}

int main() {
  printf("The average of 1 2 3 should be 2... ");
  node_t l = {1};
  insert(&l, 2);
  insert(&l, 3);
  check(average(&l) == 2);

  return 0;
}

