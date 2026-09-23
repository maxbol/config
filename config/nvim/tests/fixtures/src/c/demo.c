#include <stdio.h>
#include <stdlib.h>

static int square(int x) { return x * x; }

int sum_squares(int n) {
    int acc = 0;
    for (int i = 0; i < n; i++) {
        acc += square(i);
    }
    return acc;
}

int main(int argc, char **argv) {
    int n = argc > 1 ? atoi(argv[1]) : 10;
    printf("%d\n", sum_squares(n));
    return 0;
}
