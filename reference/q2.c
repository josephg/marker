
struct Node
{
  int data;
  struct Node *next;
};

float average(struct Node *first) {
  int sum = 0;
  int count = 0;

  for (struct Node *n = first; n; n = n->next) {
    sum += n->data;
    count++;
  }

  return (float)sum / count;
}

