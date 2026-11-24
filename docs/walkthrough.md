# Walkthrough: from bug to repair

This narrative connects the vulnerable example, GDB, sanitizer evidence, mitigation behavior, and secure rewrite. Every command runs a binary built from this repository.

## 1. Build the four local variants

\`\`\`bash
make clean
make all
make help
\`\`\`

The Makefile produces:
- \`build/vuln\`: intentionally unsafe, non-PIE target with stack protection disabled for observation;
- \`build/safe\`: bounds-checked input with compiler hardening;
- \`build/asan\`: the vulnerable source instrumented with AddressSanitizer;
- \`build/canary\`: the vulnerable source compiled with stack canaries.

The Makefile selects 32-bit for the vulnerable target only if a 32-bit link test succeeds. Otherwise it uses 64-bit. Address width and register names therefore must be read from \`file ./build/vuln\`.

## 2. Understand the frame

The vulnerable function declares a 64-byte local array and then copies an unchecked string into it. In a conventional frame-pointer build, local storage is at lower addresses than the saved frame pointer and saved return address.

\`\`\`mermaid
flowchart TB
    high["Higher memory addresses"]
    ret["Saved return address<br/>x86-64: rbp + 8<br/>32-bit x86: ebp + 4"]
    frame["Saved frame pointer<br/>rbp / ebp"]
    buffer["Local buffer: buf[64]"]
    low["Lower memory addresses"]
    high --> ret --> frame --> buffer --> low
\`\`\`

The compiler may insert padding and the exact location of the array depends on ABI and code generation. Treat this as a conceptual layout; derive the actual offset in [GDB](gdb.md).

### ASCII memory map

\`\`\`text
        higher addresses
        +------------------------------+
        | saved return address         |  rbp+8 (x86-64)
        |                              |  ebp+4 (32-bit x86)
        +------------------------------+
        | saved frame pointer          |  rbp / ebp
        +------------------------------+
        | possible alignment padding   |
        +------------------------------+
        | buf[64]                      |  address obtained with &buf
        +------------------------------+
        | other local / caller storage |
        +------------------------------+
        lower addresses

        Stack grows toward lower addresses.
        Actual offsets and padding must be measured in GDB.
\`\`\`

## 3. Observe the invalid write

Start with [the GDB checkpoints](gdb.md). Inspect \`&buf\`, the frame pointer, and the saved-return slot before and after the copy. Use the address arithmetic shown there to calculate the offset for the binary on your system. No address or offset in this walkthrough should be copied as a universal constant.

## 4. Confirm the bug with AddressSanitizer

Run:

\`\`\`bash
python3 -c 'print("A" * 200)' | ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 ./build/asan
\`\`\`

The process is expected to fail and AddressSanitizer should report \`stack-buffer-overflow\`. The CI workflow performs this same check and fails the job if that diagnostic is absent.

## 5. Compare defenses

Run:

\`\`\`bash
make demo-canary
make demo-aslr
\`\`\`

Then use the observation commands and expected results in [Mitigations](mitigations.md). The canary detects selected stack overwrites, ASLR changes addresses, NX marks memory non-executable, PIE makes the main executable relocatable, RELRO protects relocation data, and FORTIFY adds checks to eligible libc calls. None makes the original unsafe copy correct.

## 6. Repair the source

Run:

\`\`\`bash
make run-safe
\`\`\`

The safe implementation formats into a fixed-size buffer, terminates it explicitly, checks the reported length, and rejects input that does not fit. See [Secure C](secure-c.md) for the API mapping and size-checking patterns.

## 7. Practice and report

Complete the eight [graded exercises](exercises.md). The stretch ret2win challenge redirects execution only to the local \`win()\` function in the repository's non-PIE training binary. It uses no shellcode and no remote target.

## Related documentation

- [GDB and offset derivation](gdb.md)
- [Mitigation comparison](mitigations.md)
- [Secure C API mapping](secure-c.md)
- [Graded exercises](exercises.md)
- [Project overview and ethics](../README.md)
