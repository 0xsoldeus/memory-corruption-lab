# Memory Corruption Lab v0.1.0

Initial educational release of a reproducible, local-only C memory-corruption lab.

## Included

- Deliberately vulnerable 64-byte stack-buffer example and a safe, bounds-checked implementation.
- GCC Makefile targets for vulnerable, safe, AddressSanitizer, and stack-canary builds.
- Ubuntu 22.04 GitHub Actions verification for all build targets, benign safe execution, and the expected AddressSanitizer `stack-buffer-overflow` diagnostic.
- GDB walkthrough for inspecting stack frames and deriving offsets from the actual binary.
- Mitigation guide covering stack canaries, ASLR, NX, PIE, RELRO, and FORTIFY.
- Secure C API mapping, eight graded exercises, and an end-to-end Mermaid/ASCII walkthrough.
- Contribution, security, and community conduct guidance.

## Verification

The release workflow publishes this version only from the commit associated with a successful Ubuntu 22.04 CI run on `main`.

The hosted runner used for this release does not include 32-bit multilib, so the Makefile selects its documented 64-bit fallback. A runner with a working GCC 32-bit link toolchain will select the 32-bit vulnerable target automatically.

## Safety and scope

This is a **teaching lab, not a weaponized exploit**. All examples are intended for authorized, isolated, local education. The local ret2win exercise redirects execution only to the repository's own `win()` function. It contains no shellcode, no setuid behavior, and no remote targets.

The intentionally vulnerable binary is not production code. Do not deploy it or use it with untrusted input.
