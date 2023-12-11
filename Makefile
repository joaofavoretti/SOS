
# BUILDING

ASM=nasm
BUILD_DIR=build
SRC_DIR=src

$(BUILD_DIR)/floppy.img: $(BUILD_DIR)/main.bin
	dd if=/dev/zero of=$(BUILD_DIR)/floppy.img bs=512 count=2880
	dd if=$(BUILD_DIR)/main.bin of=$(BUILD_DIR)/floppy.img bs=512 seek=0 conv=notrunc

$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	$(ASM) -f bin -o $(BUILD_DIR)/main.bin $(SRC_DIR)/main.asm


# RUNNING

.PHONY: run debug

EMULATOR=qemu-system-i386

run: $(BUILD_DIR)/main.bin
	$(EMULATOR) -fda $(BUILD_DIR)/floppy.img

debug:
	gdb -q -x gdbscript.gdb
