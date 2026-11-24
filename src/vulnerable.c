#include <stdio.h>
#include <string.h>

/*
 * INTENTIONALLY UNSAFE, LOCAL EDUCATIONAL EXAMPLE.
 * The unchecked copy may exceed the destination buffer.
 * Never use this pattern in production.
 */
int main(void) {
    char input[256];
    char name[16] = "student";

    puts("Memory Corruption Lab (local demonstration)");
    printf("Enter a short name: ");

    if (!fgets(input, sizeof input, stdin)) {
        fputs("Input error.\n", stderr);
        return 1;
    }

    /* Deliberate bug: destination size is not enforced. */
    strcpy(name, input);

    printf("Hello, %s", name);
    return 0;
}
