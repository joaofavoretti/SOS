set disassembly-flavor intel

layout asm
layout regs

target remote | qemu-system-i386 -S -gdb stdio -fda build/disk.img

set architecture i8086

break *0x7C00

continue