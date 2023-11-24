org 0x7C00                      ; Address which the BIOS loads the device sector into
bits 16 


main:
    hlt

.halt:
    jmp .halt

; Adding padding to make the binary 512 bytes long
times 510 - ($ - $$) db 0

; Adding the last two bytes to make the section bootable to the BIOS
dw 0xAA55
