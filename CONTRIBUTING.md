# Contributing

Thank you for helping improve Memory Corruption Lab. Contributions should make the exercises clearer, more reproducible, and safer to learn from.

## Scope

This repository is a deliberately local educational project. Contributions must stay within binaries compiled from this repository and local-only demonstrations.

Do not add:
- shellcode or payloads that execute supplied machine code;
- setuid or privilege-escalation behavior;
- remote targets, network listeners, or instructions for testing third-party systems;
- stealth, persistence, credential access, or evasion functionality;
- binaries or exploit examples aimed at software outside this repository.

The bounded local ret2win exercise is the only control-flow-redirection challenge in scope. Keep it confined to the local <code>win()</code> function in <code>build/vuln</code>.

## Development setup

On Ubuntu 22.04, install GCC, Make, GDB, binutils, and Python 3. Then run:

~~~bash
make clean
make all
make help
printf 'learner\n' | make run-safe
~~~

For the optional cyclic-pattern helper:

~~~bash
python3 -m venv .venv
. .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 scripts/check_offset.py --length 200 --n 8
~~~

Before submitting, run the checks relevant to your change:

~~~bash
make all
make demo-canary
make demo-aslr
~~~

The deliberately vulnerable and ASan binaries are expected to fail when given oversized test input. Do not treat those expected diagnostics as a regression in the safe target.

## Pull requests

- Keep changes focused and explain the teaching objective.
- Update the README or relevant guide when commands, targets, or expected behavior change.
- Derive addresses and offsets from the current binary; never insert unexplained constants.
- Prefer commands that work with stock GCC on Ubuntu 22.04.
- Preserve the safety and legal-use block at the top of the README.
- Do not commit generated binaries, build output, or local virtual environments.
- Include the exact commands run and their results in the pull request description.

GitHub Actions is the required build-verification path. A change is not verified merely because it looks correct in a diff; the Ubuntu 22.04 workflow must pass.
