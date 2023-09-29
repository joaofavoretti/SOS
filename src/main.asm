org 0x7C00  ; Directive to tell the assembly where the code is put in memory
            ; First byte is in 0x7C00
bits 16     ; Directive. Assemble into 16 bit code


main:
    hlt

.halt:
    jmp .halt


times 510-($-$$) db 0
dw 0AA55h