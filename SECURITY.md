# Security policy

## Scope

This repository contains intentionally vulnerable C code for local education. The vulnerable program is not a product, service, or reusable component and must not be deployed or used with untrusted input.

The intended security scope is limited to:
- the source code and build scripts in this repository;
- the local binaries produced by its Makefile;
- the documentation and exercises describing those local binaries.

## Reporting a problem

For a security issue in this repository, use GitHub's private vulnerability reporting feature if it is enabled for the repository. If private reporting is unavailable, contact the repository owner through their GitHub profile. Please do not publish details of a potentially exploitable issue in a public issue before maintainers have had a chance to review it.

Include the affected file, the relevant commit or revision, the compiler and operating-system versions, the exact local reproduction command, and the observed output. Do not include unrelated third-party targets or data.

## Handling and disclosure

Maintainers will review reports that affect this repository and may request a minimal reproduction limited to the checked-in lab. Do not test a report against systems or software that you do not own or have explicit authorization to assess.

The intentionally unsafe examples are documented teaching material. Their presence is not a reportable defect by itself; unintended behavior in the safe example, build workflow, or documentation may be reported.
