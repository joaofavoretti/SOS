; ############## Assembler Directives ##############

org 0x7C00              ; Directive to tell the assembly where the code is put in memory
                        ; First byte is in 0x7C00

bits 16                 ; Directive. Assemble into 16 bit code

%define ENDL 0x0D, 0x0A


; ############## FAT12 Header ##############

;
; BIOS Parameter Block (BPB)
;
jmp short start
nop
bpb_oem:                    db 'mkfs.fat'               ; Could also be: "MSWIN4.1"
bpb_bytes_per_sector:       dw 0200h
bpb_sectors_per_cluster:    db 01h
bpb_reserved_sectors:       dw 0001h
bpb_fat_count:              db 02h
bpb_dir_entries_count:      dw 0E0h
bpb_total_sectors:          dw 2880                     ; 2 bytes | 2880 * 512 = 1.44MB
bpb_media_descriptor_type:  db 0F0h                     ; 1 byte | F0 = 3.5" floppy disk
bpb_sectors_per_fat:        dw 0009h
bpb_sectors_per_track:      dw 0012h
bpb_heads_per_cylinder:     dw 02h
bpb_hidden_sectors:         dd 00000000h
bpb_large_sector_count:     dd 00000000h

;
; Extended Boot Record (EBR)
;
ebr_drive_number:           db 00h                      ; 0x00 = Floppy Disk, 0x80 = Hard Disk
ebr_reserved:               db 00h
ebr_signature:              db 29h                      ; 0x29 = Default value 
ebr_volume_id:              dd 3Fh, 0EFh, 30h, 0DAh     ; Just a serial number to track the disks in a computer
ebr_volume_label:           db 'SIMPLE OS  '            ; 11 bytes for the label of the disk
ebr_system_id:              db 'FAT12   '               ; 8 bytes for the system id


; ############## Bootloader Entry Point ##############

;
; Bootloader entry point
;
start:
    jmp main


;
; Main Function
;
main:
    ; Setup data segments
    mov ax, 0           ; Cant write to ds/es directly
    mov ds, ax
    mov es, ax

    mov ss, ax          ; Setup stack
    mov sp, 0x7C00      ; Set the stack just at the start of the program so that
                        ; It wont overwrite the program

    ; Read something from floppy disk
    ; BIOS should set DL TO drive number
    mov [ebr_drive_number], dl

    mov ax, 1           ; LBA=1, second sector from disk
    mov cl, 1           ; 1 sector to read
    mov bx, 0x7E00       ; Data should be after the bootloader 
    call disk_read

    mov si, msg_hello
    call puts

    hlt

.halt:
    cli         ; Disable interrupts. This way CPU cant get out of "halt" state
    hlt

;
; Error handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot


; ############## Auxiliar Routines ##############

;
; PUTS: Prints a string to the screen.
; Params:
;   - ds:si = pointer to string
;
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

;
; WAIT_KEY_AND_REBOOT: Waits for a key to be pressed and reboots the computer
;
wait_key_and_reboot:
    mov si, msg_press_key
    call puts
    
    mov ah, 0
    int 16h             ; Wait for keypress
    
    jmp 0FFFFh:0        ; Jumpt to beginning of BIOS, should reboot

; ############## Disk Routines ##############

;
; LBA_TO_CHS: Converts an LBA address to a CHS address
; Params:
;   - ax: LBA address
; Return:
;   - cx[0:5]: Sector Index (6 bits)
;   - cx[6:15]: Cylinder Index (10 bits)
;   - dh: Head Index
; 
lba_to_chs:

    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bpb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack
    
    inc dx                              ; dx = (LBA % SectorsPerTrack) + 1
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bpb_heads_per_cylinder]   ; ax = cylinder = (LBA / SectorsPerTrack) / HeadsPerCylinder
                                        ; dx = head = (LBA / SectorsPerTrack) % HeadsPerCylinder
    
    mov dh, dl                          ; dh = head
    
    mov ch, al                          ; According to the Read Disk interruption doc https://www.stanislavs.org/helppc/int_13-2.html
    shl ah, 6                           ; (Information about the cylinder) 
    or  cl, ah                          ; ah              al
                                        ; 0000    00dd    cccc    cccc
                                        ;
                                        ; (Information about the sector)
                                        ; ch              cl
                                        ; cccc    cccc    ddss    ssss

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


;
; DISK_READ: Reads sectors from a disk
; Params:
;   - ax: LBA address
;   - cl: Number of sectors to read (up to 128)
;   - dl: driver number
;   - es:bx: Buffer to read the sectors into
;
disk_read:
    
    push ax
    push bx
    push cx
    push dx
    push di
    
    push cx                             ; Save CL in memory (Number of Sectors to Read)
    call lba_to_chs                     ; Convert LBA to CHS
    pop ax                              ; AL = Numbers of Sectors to Read

    mov ah, 02h                         ; Set interruption number

    mov di, 3                           ; According to docs. Loop 3 times to
                                        ; try to read from floppy disk

.retry:
    pusha                           ; Save all registers
    stc                             ; Set carry flag to 1
    int 13h                         ; Call BIOS interruption 0x13
    jnc .done                       ; If carry flag is 0, the read was successful

    ; Read failed
    popa                            ; Restore all registers
    call disk_reset                 ; Reset disk

    dec di
    test di, di
    jnz .retry

.fail:
    ; All attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


;
; DIST_RESET: Resets the floppy_disk
; Params:
;   - dl: driver number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa

; ############## Data ##############

msg_hello:          db 'Hello, World! :)', ENDL, 0
msg_read_failed:    db 'Read from disk failed! :(', ENDL, 0
msg_press_key:      db 'Press any key to reboot...', ENDL, 0

; ############## Bootloader block Signature ##############
;
; Code to add the necessary padding and boot signature 0xAA55 at the end of the bootloader
;
times 510-($-$$) db 0
dw 0AA55h