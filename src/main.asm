org 0x7C00  ; Directive to tell the assembly where the code is put in memory
            ; First byte is in 0x7C00
bits 16     ; Directive. Assemble into 16 bit code

%define ENDL 0x0D, 0x0A

start:
    jmp main


; Prints a string to the screen.
; Params:
;   - ds:si = pointer to string
puts:
    push si
    push ax

.loop:
    lodsb        ; Load next byte from ds:si into al, and increment si
    or al, al    ; Check if al is 0 (end of string). Will set the flags reg if the result is 0
    jz .done
    
    mov ah, 0x0E ; BIOS tty teletype function
    mov bh, 0x00 ; Page number
    int 0x10     ; Call BIOS interrupt 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret


main:
    ; setup data segments
    mov ax, 0    ; cant write to ds/es directly
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7C00  ; Set the stack just at the start of the program so that
                    ; It wont overwrite the program

    mov si, msg_hello
    call puts

    hlt


.halt:
    jmp .halt


msg_hello:
    db 'Hello, World!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h