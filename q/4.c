#include <stdio.h>
#include <stdlib.h>

struct node {
  int data;
  struct node *next;
};

typedef struct node node_t;

int converging(node_t *first);

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
  }
}

int main() {
  printf("Testing 6 4 3 converges\n");
  node_t l = {6};
  insert(&l, 4);
  insert(&l, 3);
  check(converging(&l) == 1);

  printf("Testing 1 2 4 does not converge\n");
  node_t l2 = {1};
  insert(&l2, 2);
  insert(&l2, 4);
  check(converging(&l2) == 0);

  return 0;
}

