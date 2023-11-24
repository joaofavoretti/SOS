set disassembly-flavor intel
target remote | qemu-system-i386 -S -gdb stdio -fda build/main_floppy.img

break *0x7C00
define si
    printf "############ Registers\n"
    info registers ax bx dx cx sp di eip

    printf "############ Next Instructions\n"
    x/5i $eip
    stepi
end

continue