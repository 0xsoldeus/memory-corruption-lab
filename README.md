# Memory Corruption Lab

A reproducible, local-only buffer-overflow teaching lab covering memory safety, debugger observation, mitigation behavior, and secure C rewrites.

> **Safety boundary:** This lab is intended for isolated, local learning. It demonstrates a bounds error and its consequences without weaponized payloads, shellcode, exploit automation, or remote targeting.

## Learning objectives
- Explain how an out-of-bounds write can corrupt adjacent memory.
- Compile a deliberately unsafe program and inspect it in GDB.
- Observe how compiler and OS mitigations affect debugging outcomes.
- Replace unsafe input handling with bounds-aware code.
- Compare build flags and discuss limitations of each mitigation.

## Requirements
- Linux (Ubuntu/Debian recommended)
- GCC or Clang
- GDB
- Make

## Quick start
```bash
make
./build/vulnerable
```
The vulnerable example accepts a short input and prints it. Use only in a disposable local environment.

## Lab sequence
1. Read [the vulnerable example](src/vulnerable.c) and identify the unchecked copy.
2. Build and run the program with ordinary inputs of different lengths.
3. Use GDB to inspect execution and local variables: [debugging guide](docs/gdb.md).
4. Build the hardened variant and compare: [mitigations](docs/mitigations.md).
5. Study [the safe rewrite](src/safe.c).

## Build targets
- `make`: build both programs
- `make run-safe`: run the safe example
- `make clean`: remove build output

## Disclaimer
Use these materials only on systems you own or have explicit permission to test. The unsafe program is intentionally flawed and should not be deployed.

## License
MIT — see [LICENSE](LICENSE).
