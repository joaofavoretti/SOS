org 0x7E00                      ; Address which the BIOS loads the device sector into
bits 16 

%define ENDL 0x0D, 0x0A

;
; Start: First instruction to be executed.
;   Jump to the main function
;
start:
    jmp main


;
; Clear: Clears the screen
;
clear:
    push ax

    mov ah, 0x00    ; Set Video Mode
    mov al, 0x03    ; 80x25 16-color text mode
    int 0x10
    
    pop ax
    ret


;
; Puts: Prints a string to the screen
; Params:
;   ds:si - Pointer to the string to print
;
puts:
    push si
    push ax

    .loop:
        lodsb
        or al, al
        jz .done

        mov ah, 0x0E
        mov bh, 0x00
        mov bl, 0x07
        int 0x10

        jmp .loop

    .done:
        pop ax
        pop si
        ret

;
; Main: The main function
;
main:
    ; Setting up the correct segments
    mov ax, 0

    ; Data segments
    mov ds, ax
    mov es, ax

    ; Stack segment
    mov ss, ax
    mov sp, 0x7C00

    ; Clearing the screen
    call clear

    ; Printing the message
    mov si, msg
    call puts

    ; Printing the second message
    mov si, msg2
    call puts

    hlt

    .halt:
        jmp .halt

msg: db "Hello, World!", ENDL, 0
msg2: db "This is a test", ENDL, 0

; Adding padding to make the binary 512 bytes long
times 510 - ($ - $$) db 0

; Adding the last two bytes to make the section bootable to the BIOS
dw 0xAA55
