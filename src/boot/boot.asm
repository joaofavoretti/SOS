org 0x7C00                      ; Address which the BIOS loads the device sector into
bits 16 

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;
jmp short start
nop

;
; BIOS Parameter Block (BPB)
;
bpbOem:                 db "MSWIN4.1"
bpbBytesPerSector:      dw 512
bpbSectorsPerCluster:   db 1
bpbReservedSectors:     dw 1
bpbFatCount:            db 2
bpbRootEntryCount:      dw 0xE0
bpbTotalSectors:        dw 2880
bpbMediaDescriptorType: db 0xF0
bpbSectorsPerFat:       dw 9
bpbSectorsPerTrack:     dw 18
bpbHeadCount:           dw 2
bpbHiddenSectorCount:   dd 0
bpbTotalSectorCount:    dd 0

;
; Extended Boot Record (EBR)
;
ebrDriveNumber:         db 0
ebrReserved:            db 0
ebrVolumeId:            db 0x12, 0x34, 0x56, 0x78
ebrVolumeLabel:         db "SOS        "
ebrSystemId:            db "FAT12   "

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
; 
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
; LbaToChs: Converts a LBA address to a CHS address
; Sector Number = (LBA % SectorsPerTrack) + 1
; Cylinder Number = (LBA / SectorsPerTrack) / HeadCount
; Head Number = (LBA / SectorsPerTrack) % HeadCount
; 
; Params:
;   ax: LBA address
; Returns:
;   cx [0:5]: Sector Number
;   cx [6:15]: Cylinder Number
;   dh: Head Number
;
lbaToChs:
    push ax
    push dx

    mov dx, 0                       ; dx = 0
    div word [bpbSectorsPerTrack]   ; ax = LBA / SectorsPerTrack
                                    ; dx = LBA % SectorsPerTrack

    inc dx                          ; dx = (LBA % SectorsPerTrack) + 1
    mov cx, dx                      ; cx = Sector Number

    mov dx, 0                       ; dx = 0
    div word [bpbHeadCount]         ; ax = (LBA / SectorsPerTrack) / HeadCount
                                    ; dx = (LBA / SectorsPerTrack) % HeadCount

    mov dh, dl                      ; dh = Head Number

    mov ch, al                      ; ch = Cylinder Number (Low)
    shl ah, 6                       ; ah = Cylinder Number (High)
    or ch, ah                       ; ch = Cylinder Number (Low) + Cylinder Number (High)

    pop ax
    mov dl, al
    pop ax
    ret

;
; ReadDisk: Reads sectors from the disk
; 
; Params:
;   ax: LBA address
;   cl: Number of sectors to read
;   dl: Drive number
;   es:bx: Pointer to the buffer to read the sectors into
;
readDisk:
    pusha               ; Save registers

    push cx
    call lbaToChs
    pop ax                      ; ax = Number of Sectors to Read

    mov di, 3                   ; Retry Counter. 3x

.retry:
    pusha
    stc                         ; Set Carry Flag for the int 0x13. Zero = Success, One = Error
    mov ah, 0x02                ; 0x2 = Read Sectors from Drive
    int 0x13                    ; int 0x13 = BIOS Disk Interrupt
    popa
    
    jnc .done                   ; If the carry flag is not set, the read was successful

    call resetDisk

    dec di                      ; Read failed, decrement the retry counter
    jnz .retry                  ; If the retry counter is not zero, retry

.error:
    mov si, readDiskErrorMsg    ; All retries failed, print the error message
    call puts
    jmp main.halt

.done:
    popa
    ret


; 
; ResetDisk: Resets the disk
; 
; Params:
;  dl: Drive number
;
resetDisk:
    pusha

    stc
    mov ah, 0x00                    ; 0x0 = Reset Disk
    int 0x13                        ; int 0x13 = BIOS Disk Interrupt
    jnc .done

.error:
    mov si, resetDiskErrorMsg       ; All retries failed, print the error message
    call puts
    jmp main.halt

.done:
    popa
    ret


;
; Main: The main function
;
main:
    mov ax, 0                   ; Setting up the correct segments

    mov ds, ax                  ; Setting up Data segments
    mov es, ax

    mov ss, ax                  ; Setting up Stack segment
    mov sp, 0x7C00

    call clear                  ; Clearing the screen
           
    mov ax, 1                   ; Reading 1 sector starting from the 1st sector 
    mov cl, 1                   ;   from the disk drive 0 into the memory 0x7E00
    mov dl, [ebrDriveNumber]
    mov bx, 0x7E00
    call readDisk

    
    mov si, helloWorldMsg       ; Printing the "Hello World" Message
    call puts

.halt:
    cli
    hlt

helloWorldMsg: db "Hello, World!", ENDL, 0
readDiskErrorMsg:   db "Error reading disk!", ENDL, 0
resetDiskErrorMsg:   db "Error resetting disk!", ENDL, 0

times 510 - ($ - $$) db 0       ; Adding padding to make the binary 512 bytes long

dw 0xAA55                       ; Adding the last two bytes to make the section bootable to the BIOS
