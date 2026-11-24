# GDB: inspect the stack and derive offsets

This guide inspects the local training binary. It does not use a remote target or supplied executable code.

## 1. Build and identify the architecture

\`\`\`bash
make vuln
file ./build/vuln
\`\`\`

The Makefile tests whether the installed compiler can link a tiny 32-bit program. If it can, \`build/vuln\` is 32-bit; otherwise it is 64-bit. The exact layout depends on compiler version, architecture, and build environment.

## 2. Stop at the vulnerable function

Start GDB with an oversized but non-special-character argument:

\`\`\`bash
gdb --args ./build/vuln "$(python3 -c 'print("A" * 200)')"
\`\`\`

At the GDB prompt:

\`\`\`gdb
break vulnerable
run
list vulnerable
info registers
info frame
print &buf
\`\`\`

**Checkpoint A — before the copy**

- GDB should stop in \`vulnerable\`, at or immediately before the \`strcpy\` call.
- On x86-64, \`rip\` identifies the current instruction, \`rsp\` is the stack pointer, \`rbp\` is the frame pointer, and \`rdi\` carries the first function argument under the System V ABI.
- On 32-bit x86, inspect \`eip\`, \`esp\`, and \`ebp\`; the first argument is passed on the stack.
- \`print &buf\` should show the address of the 64-byte local array. The address is expected to vary between runs.

The register values and exact stack addresses are examples of runtime state, not constants to copy into notes.

## 3. Observe the copy

Use \`list vulnerable\` to locate the copy line in your checkout. Step source line by line until the \`strcpy\` call has executed:

\`\`\`gdb
next
x/96bx &buf
info frame
info registers
\`\`\`

**Checkpoint B — after the copy**

The bytes from the long input should be visible beginning at \`&buf\` (ASCII \`A\` is byte \`0x41\`). The saved return-address slot may also contain input bytes. On x86-64, inspect it with:

\`\`\`gdb
x/gx $rbp+8
x/16gx $rsp
\`\`\`

On 32-bit x86, use:

\`\`\`gdb
x/wx $ebp+4
x/16wx $esp
\`\`\`

The instruction pointer remains inside \`vulnerable\` until the function attempts to return. A damaged saved return address is data in the stack frame; it is not yet the current \`rip\`/ \`eip\`.

## 4. Derive the saved-return-address offset

The Makefile builds the vulnerable target with debug symbols, no optimization, and a frame pointer. For the common x86-64 frame-pointer layout, the saved return address is stored one 8-byte word above \`rbp\`. Calculate the distance from the start of \`buf\` using the live addresses:

\`\`\`gdb
print/d (char *)($rbp + 8) - (char *)&buf
\`\`\`

For 32-bit x86, the saved return address is one 4-byte word above \`ebp\`:

\`\`\`gdb
print/d (char *)($ebp + 4) - (char *)&buf
\`\`\`

This expression computes the offset for the binary you actually built. Do not substitute a memorized value: padding and ABI details can change the result.

You can also use \`info frame\` to confirm where GDB says the saved program counter is stored. If the frame pointer is unavailable, inspect \`disassemble /m vulnerable\` and the function prologue before deriving a location; do not assume the formula above applies unchanged.

## 5. Use a pwntools cyclic pattern

Install the pinned optional dependency:

\`\`\`bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements.txt
\`\`\`

Generate a pattern. Use 8-byte subsequences for a 64-bit register and 4-byte subsequences for a 32-bit register:

\`\`\`bash
python3 scripts/check_offset.py --length 200 --n 8 > /tmp/mcl-pattern.txt
gdb --args ./build/vuln "$(cat /tmp/mcl-pattern.txt)"
\`\`\`

After the inferior stops or faults, inspect the saved-return slot and registers. Pass the overwritten instruction-pointer value (or the matching value read from the saved-return slot) to the helper:

\`\`\`bash
python3 scripts/check_offset.py --value 0x616161616161616c --n 8
\`\`\`

The hexadecimal value above is only an example of the input format; use the value from your own GDB session. For a 32-bit build, use the observed 32-bit value and \`--n 4\`.

## 6. Locate the local ret2win symbol

\`\`\`gdb
info functions win
disassemble win
\`\`\`

You can also inspect the linked symbol table outside GDB:

\`\`\`bash
nm -n ./build/vuln | grep ' win$'
\`\`\`

The no-PIE vulnerable build gives the local \`win\` function a stable code address for that particular binary. Rebuilds or toolchain changes can change it; always obtain it from the binary you are examining. The bounded ret2win exercise is described in [Exercises](exercises.md).

## Expected observations at a glance

| Checkpoint | Expected observation |
|---|---|
| Before \`strcpy\` | \`buf\` is 64 bytes; saved return slot still points into the caller |
| After \`strcpy\` | Input bytes extend beyond \`buf\`; adjacent frame data may be overwritten |
| Offset calculation | GDB prints a byte distance derived from the actual buffer and saved-return-slot addresses |
| Symbol lookup | \`info functions win\` lists the local \`win\` symbol |
| Architecture check | \`file\` reports ELF 32-bit or ELF 64-bit; use matching registers and word sizes |

For the memory model behind these observations, continue to the [end-to-end walkthrough](walkthrough.md).
