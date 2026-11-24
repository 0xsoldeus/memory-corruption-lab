# Known issues

Short, factual notes on defects found in this lab. Each entry records what was observed, the cause, the change that was made, and the commit that carried the change.

## The ASan input buffer overlapped the destination frame (fixed)

**Commit:** `1c13e4e73d75fa607757c9048417eb81919b91dc` — *fix: isolate ASan input from vulnerable stack frame*

**Observed.** The AddressSanitizer build of `src/vulnerable.c` did not report the intended stack-buffer-overflow. With 200 bytes of input on stdin it reported:

```text
==13==ERROR: AddressSanitizer: strcpy-param-overlap: memory ranges [0x7fff048e5cb0,0x7fff048e5d79) and [0x7fff048e5d70, 0x7fff048e5e39) overlap
    #0 0x7f412020a3e6 in __interceptor_strcpy
    #1 0x401583 in vulnerable src/vulnerable.c:31
    #2 0x401891 in main src/vulnerable.c:56

Address 0x7fff048e5cb0 is located in stack of thread T0 at offset 32 in frame
    #0 0x4014fb in vulnerable src/vulnerable.c:29

  This frame has 1 object(s):
    [32, 96) 'buf' (line 30) <== Memory access at offset 32 partially overflows this variable

Address 0x7fff048e5d70 is located in stack of thread T0 at offset 32 in frame
    #0 0x40160b in main src/vulnerable.c:35

  This frame has 1 object(s):
    [32, 544) 'input' (line 36) <== Memory access at offset 32 is inside this variable

SUMMARY: AddressSanitizer: strcpy-param-overlap in __interceptor_strcpy
```

The two addresses belong to different frames, and the report names both objects: `buf` in the frame of `vulnerable()` and `input` in the frame of `main()`.

**Cause.** `main()` declared the staging buffer as a 512-byte stack local, `char input[512];`. `vulnerable()` declares `char buf[64]` and copies into it with `strcpy(buf, input)`. The two objects are in different stack frames, but `vulnerable()` is called from `main()`, so its frame is below the caller's, and in this build `buf` starts 192 bytes below `input`. Copying 201 bytes therefore makes the destination range `buf[0..200]` reach upward into `input`, so the source range and the destination range of the same `strcpy` call overlap. The sanitizer's `strcpy` interceptor checks for that overlap before it checks the destination bounds, and aborts on it, so the report names the overlap rather than the out-of-bounds write. The overlap was a property of the staging buffer's placement, not of the bug being demonstrated.

**Change.** `main()` now declares the staging buffer as `static char input[512];`, which places it in static storage instead of on the stack:

```c
int main(int argc, char **argv) {
    static char input[512];
```

The source and the destination can no longer overlap. The same input now produces the intended diagnostic:

```text
==8==ERROR: AddressSanitizer: stack-buffer-overflow ... in __interceptor_strcpy
```

with `buf[64]` identified as the overflowed object, and the CI check that asserts on `stack-buffer-overflow` passes.

**Reproducing.** Check out the parent of the fixing commit and build the sanitizer target from the same source:

```bash
git show 1c13e4e^:src/vulnerable.c > src/vulnerable.c
make asan
python3 -c 'print("A" * 200)' | ASAN_OPTIONS=detect_leaks=0:halt_on_error=1 ./build/asan
```
