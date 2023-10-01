org 0x7C00              ; Directive to tell the assembly where the code is put in memory
                        ; First byte is in 0x7C00
bits 16                 ; Directive. Assemble into 16 bit code

%define ENDL 0x0D, 0x0A

;
; FAT12 Header
;
; BIOS Parameter Block (BPB)
jmp short start
nop
bpb_oem:                    db 'mkfs.fat'     ; Could also be: "MSWIN4.1"
bpb_bytes_per_sector:       dw 0200h
bpb_sectors_per_cluster:    db 01h
bpb_reserved_sectors:       dw 0001h
bpb_fat_count:              db 02h
bpb_dir_entries_count:      dw 0E0h
bpb_total_sectors:          dw 2880           ; 2 bytes | 2880 * 512 = 1.44MB
bpb_media_descriptor_type:  db 0F0h            ; 1 byte | F0 = 3.5" floppy disk
bpb_sectors_per_fat:        dw 0009h
bpb_sectors_per_track:      dw 0012h
bpb_heads_per_cylinder:     dw 02h
bpb_hidden_sectors:         dd 00000000h
bpb_large_sector_count:     dd 00000000h

; Extended Boot Record (EBR)
ebr_drive_number:           db 00h                  ; 0x00 = Floppy Disk, 0x80 = Hard Disk
ebr_reserved:               db 00h
ebr_signature:              db 29h                  ; 0x29 = Default value 
ebr_volume_id:              dd 3Fh, 0EFh, 30h, 0DAh   ; Just a serial number to track the disks in a computer
ebr_volume_label:           db 'SIMPLE OS  '        ; 11 bytes for the label of the disk
ebr_system_id:              db 'FAT12   '            ; 8 bytes for the system id

;
; Code goes here
;

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