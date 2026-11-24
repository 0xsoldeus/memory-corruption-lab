# Debugging with GDB

This walkthrough stays within a local process and focuses on observation rather than exploit construction.

## Build with symbols
```bash
make
```

## Start GDB
```bash
gdb ./build/vulnerable
```

Within GDB:
```
break main
run
list
next
print input
print name
info frame
quit
```

## Observe
- Follow control flow through the input and copy statements.
- Inspect the declared sizes of the arrays.
- Compare ordinary input with the destination's declared capacity.
- Do not attempt to construct a payload to redirect execution or spawn a shell.

GDB's output and behavior vary by compiler, architecture, and build configuration.
