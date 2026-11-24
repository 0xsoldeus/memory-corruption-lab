# Mitigations: compare what each layer does

A mitigation constrains one class of consequence; it does not make an unsafe copy correct. The repository builds a vulnerable non-PIE target, a hardened PIE target, a canary target, and an AddressSanitizer target so you can compare concrete observations.

## Quick demonstrations

\`\`\`bash
make demo-canary
make demo-aslr
\`\`\`

- \`demo-canary\` runs the local canary binary with an oversized argument and checks for the stack-smashing diagnostic.
- \`demo-aslr\` prints the PIE program's global-data and stack addresses across separate processes. With ASLR enabled, addresses should generally vary.

## Mitigation comparison

| Mitigation | What it stops or constrains | Enable / disable | Observation command | Expected observation |
|---|---|---|---|---|
| Stack canary | Detects many stack overwrites before a protected function returns; it does not stop the write itself | Enable: \`-fstack-protector-strong\` or \`-fstack-protector-all\`; disable: \`-fno-stack-protector\` | \`nm -D ./build/canary \| grep __stack_chk_fail\` and \`make demo-canary\` | The canary binary imports the failure handler; the local oversized input triggers a stack-smashing diagnostic |
| ASLR | Randomizes process memory-region placement; it does not fix memory corruption | Enable: \`sudo sysctl -w kernel.randomize_va_space=2\`; disable: \`sudo sysctl -w kernel.randomize_va_space=0\` | \`cat /proc/sys/kernel/randomize_va_space\` and \`make demo-aslr\` | Value \`2\` means full system ASLR; repeated PIE global/stack addresses generally differ |
| NX (non-executable stack) | Prevents instruction execution from stack pages marked non-executable | Enable: \`-Wl,-z,noexecstack\`; disable for this local comparison: \`-Wl,-z,execstack\` | \`readelf -lW ./build/vuln \| grep GNU_STACK\` and \`readelf -lW ./build/safe \| grep GNU_STACK\` | The lab's vulnerable binary shows an executable stack flag; the safe binary's stack is non-executable |
| PIE | Makes the main executable eligible for relocation; ASLR can then randomize its load address | Enable: \`-fPIE -pie\`; disable: \`-fno-pie -no-pie\` | \`readelf -hW ./build/safe \| grep Type\` and \`readelf -hW ./build/vuln \| grep Type\` | The PIE executable is normally \`DYN\`; the non-PIE executable is normally \`EXEC\` |
| RELRO | Makes relocation-related data read-only after relocation; full RELRO also resolves symbols eagerly | Enable full RELRO: \`-Wl,-z,relro,-z,now\`; disable: \`-Wl,-z,norelro\` | \`readelf -lW ./build/safe \| grep GNU_RELRO\` and \`readelf -dW ./build/safe \| grep -E 'BIND_NOW|FLAGS'\` | Full RELRO has a \`GNU_RELRO\` segment and eager-binding metadata |
| FORTIFY | Adds compile-time and selected runtime checks to supported libc calls when object sizes are known | Enable: \`-O2 -D_FORTIFY_SOURCE=2\`; disable: \`-U_FORTIFY_SOURCE\` | \`readelf -Ws ./build/safe \| grep -E '__.*_chk'\` | Fortified libc entry points may appear (for example, a \`__*_chk\` symbol); exact imports depend on compiler and optimization |

## Inspect the current builds

\`\`\`bash
make all
file ./build/vuln ./build/safe ./build/asan ./build/canary
readelf -lW ./build/vuln | grep GNU_STACK
readelf -lW ./build/safe | grep GNU_STACK
readelf -hW ./build/vuln | grep Type
readelf -hW ./build/safe | grep Type
readelf -lW ./build/safe | grep GNU_RELRO
readelf -dW ./build/safe | grep -E 'BIND_NOW|FLAGS'
readelf -Ws ./build/safe | grep -E '__.*_chk'
\`\`\`

A \`grep\` command can return no matches for a particular compiler/linker build. Interpret the actual ELF metadata rather than treating one symbol name as universal proof.

## Toggle system ASLR carefully

The following settings affect the whole host, not just this repository. Use them only on a disposable learning VM and restore the original setting afterward:

\`\`\`bash
cat /proc/sys/kernel/randomize_va_space
sudo sysctl -w kernel.randomize_va_space=0
make demo-aslr
sudo sysctl -w kernel.randomize_va_space=2
make demo-aslr
\`\`\`

The values commonly mean: \`0\` disables ASLR, \`1\` randomizes stack/mmap regions, and \`2\` also randomizes the heap. Some containers do not permit changing this kernel setting; in that case, observe the current value without attempting to override the host.

## Build variants for additional comparisons

These optional commands compile the same safe source with alternative RELRO and FORTIFY settings. They write only under \`/tmp\`:

\`\`\`bash
gcc -O2 -fPIE -pie -Wl,-z,relro,-z,now -o /tmp/mcl-full-relro src/safe.c
gcc -O2 -fPIE -pie -Wl,-z,norelro -o /tmp/mcl-no-relro src/safe.c
readelf -lW /tmp/mcl-full-relro | grep GNU_RELRO
readelf -lW /tmp/mcl-no-relro | grep GNU_RELRO
gcc -O2 -D_FORTIFY_SOURCE=2 -o /tmp/mcl-fortify src/safe.c
gcc -O2 -U_FORTIFY_SOURCE -o /tmp/mcl-no-fortify src/safe.c
readelf -Ws /tmp/mcl-fortify | grep -E '__.*_chk'
\`\`\`

Do not infer that a binary is safe because it has several mitigations. The durable fix is to remove the out-of-bounds write, as shown in [Secure C](secure-c.md).
