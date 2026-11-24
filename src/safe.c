#include <stdio.h>
#include <string.h>

int layout_marker = 1;

static void print_layout(void) {
    volatile int stack_marker = 0;
    printf("global=%p stack=%p\n", (void *)&layout_marker, (void *)&stack_marker);
}

static int safe_copy_and_print(const char *input) {
    char buf[64];
    int written = snprintf(buf, sizeof buf, "%s", input);

    /* Defensive terminator even if implementation or future edits change. */
    buf[sizeof buf - 1] = '\0';

    if (written < 0) {
        fputs("Formatting error.\n", stderr);
        return 1;
    }
    if ((size_t)written >= sizeof buf) {
        fprintf(stderr, "Input too long: maximum accepted length is %zu bytes.\n",
                sizeof buf - 1);
        return 2;
    }

    printf("You entered: %s\n", buf);
    return 0;
}

int main(int argc, char **argv) {
    char input[512];

    if (argc > 1 && strcmp(argv[1], "--layout") == 0) {
        print_layout();
        return 0;
    }

    if (argc > 1) {
        return safe_copy_and_print(argv[1]);
    }

    fputs("Enter a short string: ", stdout);
    fflush(stdout);
    if (fgets(input, sizeof input, stdin) == NULL) {
        fputs("Input error.\n", stderr);
        return 1;
    }

    input[strcspn(input, "\n")] = '\0';
    return safe_copy_and_print(input);
}
