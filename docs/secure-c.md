# Secure C: replace unsafe operations

The goal is to make buffer capacity and input length explicit. A bounded API is not automatically safe if its return value, terminator, or size arithmetic is ignored.

## Unsafe-to-safe API mapping

| Avoid | Safer pattern | Required check |
|---|---|---|
| \`gets(dst)\` | \`fgets(dst, sizeof dst, stdin)\` | Check for \`NULL\`, then handle the newline and any truncated input |
| \`strcpy(dst, src)\` | \`snprintf(dst, sizeof dst, "%s", src)\` or carefully checked \`strncpy\` | Check the return value; explicitly terminate; reject or deliberately handle truncation |
| \`sprintf(dst, ...)\` | \`snprintf(dst, sizeof dst, ...)\` | Treat a return value greater than or equal to the destination size as truncation |
| \`memcpy(dst, src, n)\` | Keep \`memcpy\` only with validated sizes | Prove \`n <= dst_capacity\` and \`n <= src_available\` before copying |

## Why \`snprintf\` is used in this lab

The safe target uses a fixed-size destination and checks the formatted length:

\`\`\`c
char buf[64];
int written = snprintf(buf, sizeof buf, "%s", input);
buf[sizeof buf - 1] = '\\0';

if (written < 0) {
    /* formatting error */
}
if ((size_t)written >= sizeof buf) {
    /* reject input that did not fit */
}
\`\`\`

The explicit terminator documents the invariant. The return-value check distinguishes a complete copy from a truncated one. The build also enables \`-D_FORTIFY_SOURCE=2\`, optimization, stack protection, PIE, NX stack, and full RELRO; these are defense-in-depth measures.

## A careful \`strncpy\` pattern

\`strncpy\` may leave the destination unterminated when the source fills the bound. If it is used, reserve a byte and terminate explicitly:

\`\`\`c
char dst[64];
strncpy(dst, src, sizeof dst - 1);
dst[sizeof dst - 1] = '\\0';
\`\`\`

This example still needs an input-length policy: silent truncation may be incorrect for identifiers, paths, authorization values, or protocol fields. Prefer a checked \`snprintf\` or explicit length validation when truncation is not acceptable.

## Validate \`memcpy\` lengths

\`\`\`c
if (copy_len > dst_capacity || copy_len > src_available) {
    /* reject invalid length */
} else {
    memcpy(dst, src, copy_len);
}
\`\`\`

If the length is computed by multiplying a count by an element size, check the multiplication before evaluating it:

\`\`\`c
if (count > SIZE_MAX / element_size) {
    /* reject integer overflow */
}
size_t bytes = count * element_size;
\`\`\`

Include \`<stdint.h>\` for \`SIZE_MAX\` (and ensure \`element_size\` is nonzero before division).

## Compile and compare

\`\`\`bash
make safe
make run-safe
make all
\`\`\`

The checked-in implementation is [src/safe.c](../src/safe.c); the intentionally flawed local example is [src/vulnerable.c](../src/vulnerable.c). The Makefile's \`safe\` target records the hardening flags used for the comparison.
