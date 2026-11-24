SHELL := /bin/bash
CC ?= gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -std=c11
BUILD := build

# Use 32-bit output only when the compiler and 32-bit runtime libraries link.
# Otherwise the vulnerable target falls back to 64-bit.
M32_AVAILABLE := $(shell tmp=$$(mktemp); printf 'int main(void) { return 0; }\n' | $(CC) -m32 -x c -o "$$tmp" - >/dev/null 2>&1 && echo yes || echo no; rm -f "$$tmp")
ifeq ($(M32_AVAILABLE),yes)
VULN_ARCH := -m32
else
VULN_ARCH :=
endif

.PHONY: all vuln safe asan canary run-safe run-vuln demo-canary demo-aslr clean help docker-build docker-shell

all: vuln safe asan canary

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/vuln: src/vulnerable.c | $(BUILD)
	$(CC) $(CFLAGS) -O0 -g -fno-omit-frame-pointer -fno-stack-protector -fno-pie -z execstack -no-pie $(VULN_ARCH) -o $@ $<

$(BUILD)/safe: src/safe.c | $(BUILD)
	$(CC) $(CFLAGS) -O2 -g -D_FORTIFY_SOURCE=2 -fstack-protector-strong -fPIE -pie -Wl,-z,noexecstack -Wl,-z,relro,-z,now -o $@ $<

$(BUILD)/asan: src/vulnerable.c | $(BUILD)
	$(CC) $(CFLAGS) -O0 -g -fno-omit-frame-pointer -fno-stack-protector -fsanitize=address -fno-pie -no-pie -Wl,-z,noexecstack -o $@ $<

$(BUILD)/canary: src/vulnerable.c | $(BUILD)
	$(CC) $(CFLAGS) -O0 -g -fno-omit-frame-pointer -fstack-protector-all -fno-pie -no-pie -Wl,-z,noexecstack -o $@ $<

vuln: $(BUILD)/vuln

safe: $(BUILD)/safe

asan: $(BUILD)/asan

canary: $(BUILD)/canary

run-safe: safe
	./$(BUILD)/safe

run-vuln: vuln
	./$(BUILD)/vuln

demo-canary: canary
	@python3 -c 'import subprocess; p = subprocess.run(["./build/canary", "A" * 200], text=True, capture_output=True); output = p.stdout + p.stderr; print(output, end=""); assert "stack smashing detected" in output, "stack-canary failure marker was not observed"'

demo-aslr: safe
	@echo "kernel.randomize_va_space=$$(cat /proc/sys/kernel/randomize_va_space)"
	@python3 -c 'import subprocess; [print(subprocess.check_output(["./build/safe", "--layout"], text=True).strip()) for _ in range(3)]'

clean:
	rm -rf $(BUILD)

docker-build:
	docker build -t mcl .

docker-shell:
	docker build -t mcl . && docker run --rm -it -v "$$PWD":/lab -w /lab mcl

help:
	@echo "Memory Corruption Lab build targets:"
	@echo "  make all          Build vulnerable, safe, ASan, and canary binaries"
	@echo "  make vuln         Build the intentionally vulnerable local target"
	@echo "  make safe         Build the hardened safe example"
	@echo "  make asan         Build the AddressSanitizer instrumented target"
	@echo "  make canary       Build the stack-canary demonstration target"
	@echo "  make run-safe     Run the safe program (reads stdin)"
	@echo "  make run-vuln     Run the vulnerable program (local use only)"
	@echo "  make demo-canary  Trigger and verify a local stack-canary detection"
	@echo "  make demo-aslr    Print PIE data and stack addresses across runs"
	@echo "  make clean        Remove build artifacts"
	@echo "  make docker-build Build the canonical 32-bit Docker image (tag: mcl)"
	@echo "  make docker-shell Build the image and open a shell in it with the repo mounted at /lab"
	@echo "  make help         Show this help"
	@if [ "$(M32_AVAILABLE)" = yes ]; then echo "Vulnerable target architecture: 32-bit (-m32)"; else echo "Vulnerable target architecture: 64-bit (32-bit multilib unavailable)"; fi
