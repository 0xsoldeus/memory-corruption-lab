# Secure C checklist

- [ ] Track each buffer's capacity alongside its data.
- [ ] Reject input that cannot fit; do not silently truncate security-sensitive values.
- [ ] Use bounded input APIs and validate parsing results.
- [ ] Avoid `strcpy`, `sprintf`, and unchecked pointer arithmetic.
- [ ] Check return values and integer overflow in size calculations.
- [ ] Compile with warnings and hardening enabled.
- [ ] Run sanitizers in test builds (e.g., AddressSanitizer).
- [ ] Review error paths and resource cleanup.
- [ ] Prefer memory-safe alternatives for new code.
