# ColecoVision Rachel Client Makefile

ASM = pasmo
AFLAGS = --bin

SRC_DIR = src
BUILD_DIR = build
SOURCES = $(wildcard $(SRC_DIR)/*.asm $(SRC_DIR)/net/*.asm)

TARGET = $(BUILD_DIR)/rachel.col

.PHONY: all clean

all: $(TARGET)
	@ls -la $(TARGET)
	@echo "Build complete: $(TARGET)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SOURCES) | $(BUILD_DIR)
	cd $(SRC_DIR) && $(ASM) $(AFLAGS) main.asm ../$(TARGET)

clean:
	rm -rf $(BUILD_DIR)
