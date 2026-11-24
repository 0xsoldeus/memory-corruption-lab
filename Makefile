CC ?= gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -g
BUILD := build

.PHONY: all clean run-safe
all: $(BUILD)/vulnerable $(BUILD)/safe

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/vulnerable: src/vulnerable.c | $(BUILD)
	$(CC) $(CFLAGS) -O0 -fno-stack-protector -o $@ $<

$(BUILD)/safe: src/safe.c | $(BUILD)
	$(CC) $(CFLAGS) -O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -o $@ $<

run-safe: $(BUILD)/safe
	./$(BUILD)/safe

clean:
	rm -rf $(BUILD)
