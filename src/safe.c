#include <stdio.h>
#include <string.h>

int main(void) {
    char input[256];
    char name[16];

    puts("Memory Corruption Lab — safe version");
    printf("Enter a name (max 15 characters): ");

    if (!fgets(input, sizeof input, stdin)) {
        fputs("Input error.\n", stderr);
        return 1;
    }

    input[strcspn(input, "\n")] = '\0';

    if (strlen(input) >= sizeof name) {
        fprintf(stderr, "Input too long; limit is %zu characters.\n", sizeof name - 1);
        return 2;
    }

    memcpy(name, input, strlen(input) + 1);
    printf("Hello, %s!\n", name);
    return 0;
}
