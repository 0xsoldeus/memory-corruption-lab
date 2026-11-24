#!/usr/bin/env python3
"""Generate a local cyclic pattern or recover its offset from a GDB value."""

import argparse
import sys

from pwn import context, cyclic, cyclic_find


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate/find offsets with pwntools cyclic patterns."
    )
    parser.add_argument(
        "--length", type=int, default=200,
        help="pattern length to generate (default: 200)"
    )
    parser.add_argument(
        "--value",
        help="overwritten instruction-pointer value from GDB (decimal or 0x-prefixed hex)"
    )
    parser.add_argument(
        "--n", type=int, choices=(4, 8), default=4,
        help="cyclic subsequence width: use 4 for 32-bit and 8 for 64-bit (default: 4)"
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    context.endian = "little"
    context.arch = "amd64" if args.n == 8 else "i386"
    context.log_level = "error"

    if args.length < 1:
        print("error: --length must be positive", file=sys.stderr)
        return 2

    if args.value is None:
        sys.stdout.write(cyclic(args.length, n=args.n).decode("ascii"))
        sys.stdout.write("\n")
        return 0

    try:
        observed = int(args.value, 0)
    except ValueError:
        print("error: --value must be a decimal or 0x-prefixed integer", file=sys.stderr)
        return 2

    offset = cyclic_find(observed, n=args.n)
    if offset < 0:
        print("No matching subsequence found; check --n and the register value.")
        return 1

    print(f"offset={offset}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
