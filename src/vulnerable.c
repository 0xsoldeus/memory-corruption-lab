#include <stdio.h>
#include <string.h>

int layout_marker = 1;

static void print_layout(void) {
    volatile int stack_marker = 0;
    printf("global=%p stack=%p\n", (void *)&layout_marker, (void *)&stack_marker);
}

/*
 * Local-only ret2win exercise target.
 * This function is not a shell and executes no supplied code.
 */
#if defined(__GNUC__)
__attribute__((noinline, force_align_arg_pointer))
#endif
void win(void) {
    puts("\n[+] WIN: local ret2win demonstration reached win()!");
}

/*
 * INTENTIONALLY VULNERABLE. Do not use with untrusted input or in production.
 * The lab observes this out-of-bounds write only in a disposable local process.
 */
void vulnerable(char *input) {
    char buf[64];
    strcpy(buf, input); /* Deliberate bug: no destination-capacity check. */
    printf("You entered: %s\n", buf);
}

int main(int argc, char **argv) {
    char input[512];

    if (argc > 1 && strcmp(argv[1], "--layout") == 0) {
        print_layout();
        return 0;
    }

    if (argc > 1) {
        vulnerable(argv[1]);
        return 0;
    }

    fputs("Enter a short string: ", stdout);
    fflush(stdout);
    if (fgets(input, sizeof input, stdin) == NULL) {
        fputs("Input error.\n", stderr);
        return 1;
    }

    input[strcspn(input, "\n")] = '\0';
    vulnerable(input);
    return 0;
}
