# Memory Corruption Lab

> **Ethics & legal use:** This repository is for authorized, isolated, local education only. Run the deliberately vulnerable binaries only in a disposable environment that you control. Do not use these materials against third-party software, systems, services, or data. You are responsible for complying with applicable laws and rules.
>
> **Safety boundary:** This lab is intended for isolated, local learning. It demonstrates a bounds error and its consequences without weaponized payloads, shellcode, exploit automation, or remote targeting.

[![CI](https://github.com/0xsoldeus/memory-corruption-lab/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/0xsoldeus/memory-corruption-lab/actions/workflows/ci.yml)

A reproducible, local-only buffer-overflow teaching lab covering memory safety, debugger observation, mitigation behavior, and secure C rewrites.

## Learning objectives

- Explain how an out-of-bounds write can corrupt adjacent stack data.
- Compile a deliberately vulnerable C program and inspect it with GDB.
- Derive stack offsets and symbol addresses from the binary being studied rather than copying fixed values.
- Observe AddressSanitizer and stack-canary diagnostics.
- Compare ASLR, NX, PIE, RELRO, and FORTIFY.
- Replace unsafe string handling with bounds-aware code.

## Prerequisites

- Ubuntu 22.04 or a similar Linux environment
- GCC, GNU Make, GDB, and binutils (file, readelf, nm)
- Python 3 for demo helpers
- Optional: Python virtual environment support and pip for the pwntools cyclic-pattern helper

On Ubuntu, install the system tools with:

~~~bash
sudo apt-get update
sudo apt-get install -y build-essential gdb binutils python3 python3-venv python3-pip
~~~

## Quick start

~~~bash
git clone https://github.com/0xsoldeus/memory-corruption-lab.git
cd memory-corruption-lab
make help
make all
printf 'learner\n' | make run-safe
~~~

To run the deliberately vulnerable target interactively, use <code>make run-vuln</code>. Keep it local and use only disposable test input.

The Makefile tests whether GCC can link a minimal 32-bit program. It selects <code>-m32</code> for the vulnerable target only when that test succeeds. Otherwise, it builds a 64-bit target and prints that choice in <code>make help</code>. The Ubuntu 22.04 CI runner used for this repository did not have the 32-bit multilib toolchain, so CI verifies the 64-bit fallback.

## Build targets

| Command | Purpose |
|---|---|
| <code>make all</code> | Build the vulnerable, safe, ASan, and canary binaries |
| <code>make vuln</code> | Build the intentionally vulnerable local target |
| <code>make safe</code> | Build the hardened safe example |
| <code>make asan</code> | Build the AddressSanitizer-instrumented target |
| <code>make run-safe</code> | Run the safe program; input is read from stdin |
| <code>make run-vuln</code> | Run the vulnerable program; input is read from stdin |
| <code>make demo-canary</code> | Verify a local stack-canary diagnostic |
| <code>make demo-aslr</code> | Print PIE global-data and stack addresses across runs |
| <code>make clean</code> | Remove build output |
| <code>make help</code> | Print target help and vulnerable-binary architecture choice |

### AddressSanitizer exercise

After <code>make all</code>, run the following command. It is expected to terminate unsuccessfully after reporting the deliberate stack overflow:

~~~bash
python3 -c 'print("A" * 200)' | ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 ./build/asan
~~~

CI repeats this test and explicitly fails if the output does not contain <code>stack-buffer-overflow</code>.

### Optional cyclic-pattern helper

Install the pinned pwntools dependency in a virtual environment:

~~~bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 scripts/check_offset.py --length 200 --n 8
~~~

Use <code>--n 8</code> for a 64-bit target and <code>--n 4</code> for a 32-bit target. See [the GDB guide](docs/gdb.md) for deriving offsets from the current stack frame.

## Repository map

~~~text
.
├── .github/
│   └── workflows/
│       └── ci.yml
├── docs/
│   ├── exercises.md
│   ├── gdb.md
│   ├── mitigations.md
│   ├── secure-c.md
│   └── walkthrough.md
├── scripts/
│   └── check_offset.py
├── src/
│   ├── safe.c
│   └── vulnerable.c
├── .gitignore
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile
├── README.md
├── requirements.txt
└── SECURITY.md
~~~

## Learning path and documentation

1. [End-to-end walkthrough](docs/walkthrough.md) — follow the bug from source to repair.
2. [GDB guide](docs/gdb.md) — inspect registers, stack frames, and derived offsets.
3. [Mitigations](docs/mitigations.md) — compare canary, ASLR, NX, PIE, RELRO, and FORTIFY.
4. [Secure C](docs/secure-c.md) — unsafe-to-safe API mapping and explicit length checks.
5. [Graded exercises](docs/exercises.md) — eight beginner, intermediate, and stretch exercises.

## Topics

C memory safety · stack frames · out-of-bounds writes · GDB · cyclic patterns · local ret2win · AddressSanitizer · stack canaries · ASLR · NX · PIE · RELRO · FORTIFY · secure C APIs · compiler hardening

## Good first issues

- Add automated benign and boundary-length tests for the safe input path.
- Add a small Clang build job while retaining GCC on Ubuntu 22.04 as the required baseline.
- Improve the stack diagram with side-by-side x86 and x86-64 frame annotations.
- Add a UBSan build target and document which checks it adds beyond AddressSanitizer.
- Expand the secure C examples with a checked length-prefixed parsing routine.

See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Scope and limitations

The ret2win stretch exercise is a local demonstration that redirects control flow to the repository's own <code>win()</code> function. It uses no shellcode and does not target another program. The vulnerable target intentionally disables stack protection and marks its stack executable so learners can observe individual mitigation differences; do not reuse those build settings in production software.

Compiler output, addresses, register values, and stack offsets vary with architecture, compiler, and environment. Derive them from the binary being studied. The CI workflow verifies builds and the expected AddressSanitizer diagnostic on Ubuntu 22.04; it does not claim that every optional local demonstration behaves identically on every distribution.

## License

MIT — see [LICENSE](LICENSE).
