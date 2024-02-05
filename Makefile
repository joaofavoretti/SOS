
.PHONY: run debug image boot kernel always clean disas tools_fat

###### BUILDING
ASM=nasm
CC=gcc
BUILD_DIR=build
TOOLS_DIR=tools
SRC_DIR=src

all: always image tools_fat

#
# Image
#
image: $(BUILD_DIR)/disk.img

$(BUILD_DIR)/disk.img: boot kernel
	dd if=/dev/zero of=$(BUILD_DIR)/disk.img bs=512 count=2880
	mkfs.fat -F 12 -n "SOS" $(BUILD_DIR)/disk.img
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/disk.img conv=notrunc
	mcopy -i $(BUILD_DIR)/disk.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/disk.img test.txt "::test.txt"


#
# Boot
#
boot: $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/boot.bin: always
	$(ASM) -f bin -o $(BUILD_DIR)/boot.bin $(SRC_DIR)/boot/boot.asm


#
# Kernel
#
kernel: $(BUILD_DIR)/kernel.bin always

$(BUILD_DIR)/kernel.bin: always
	$(ASM) -f bin -o $(BUILD_DIR)/kernel.bin $(SRC_DIR)/kernel/kernel.asm

#
# Tool
#
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

#
# Always
#
always:
	mkdir -p $(BUILD_DIR)

#
# Clean
#
clean:
	rm -rf $(BUILD_DIR)/*

###### RUNNING
EMULATOR=qemu-system-i386

run: image
	$(EMULATOR) -fda $(BUILD_DIR)/disk.img

debug: image
	gdb -q -x gdbscript.gdb

disas: image
	objdump -D -b binary -m i8086 --start-address=0x7C3D --adjust-vma=0x7C00 -M intel $(BUILD_DIR)/disk.img
