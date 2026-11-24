# Mitigations: what they do and don't do

## Stack canaries
A compiler may place a guard value near sensitive stack data and check it before returning from a function. This can detect some stack overwrites, but it does not prevent all memory corruption or protect every data object.

## ASLR
Address Space Layout Randomization changes the placement of memory regions. It complicates assumptions about addresses but does not fix unsafe code.

## NX / DEP
Non-executable memory policies prevent execution from selected data regions. They do not stop data corruption or eliminate code-reuse attack classes.

## Compiler hardening
Useful options vary by compiler and platform. This lab's safe target uses stack protection and fortified library checks where supported. These are defense-in-depth measures, not substitutes for memory-safe design.

## Recommended practice
- Validate input lengths and types.
- Prefer bounded APIs and explicit capacity checks.
- Avoid unsafe copying and parsing routines.
- Use memory-safe languages for new components when feasible.
- Enable compiler hardening and sanitizers during development.
- Test and review the code; no single mitigation is sufficient.
