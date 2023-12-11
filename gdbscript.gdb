set disassembly-flavor intel
set architecture i8086

target remote | qemu-system-i386 -S -gdb stdio -fda build/floppy.img

break *0x7C00

define si
    shell clear

    printf "############ Registers\n"
    info registers ax bx dx cx sp di eip

    printf "############ Next Instructions\n"
    x/5i $eip
    stepi
end

continue