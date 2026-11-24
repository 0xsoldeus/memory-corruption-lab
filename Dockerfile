# Canonical 32-bit build environment for the Memory Corruption Lab.
#
# The vulnerable target needs the 32-bit multilib toolchain to be built with
# -m32. Build the image with `make docker-build`, then open a shell in it with
# `make docker-shell`.
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc-multilib \
        gdb \
        python3 \
        make \
        file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /lab
COPY . /lab

CMD ["bash"]
