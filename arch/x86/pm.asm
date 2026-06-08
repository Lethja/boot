VIDEO_MEMORY     equ 0xB8000
WHITE_ON_BLACK   equ 0x0F

CODE_OFFSET equ 0x8
DATA_OFFSET equ 0x10
cursor dw 0x0

gdt:
.start:
	dd 0x0
	dd 0x0

	; Code Segment descriptor
	dw 0xFFFF    ; Limit
	dw 0x0000    ; Base
	db 0x00      ; Base
	db 10011010b ; Access byte
	db 11001111b ; Flags
	db 0x00      ; Base

	; Data Segment descriptor
	dw 0xFFFF    ; Limit
	dw 0x0000    ; Base
	db 0x00      ; Base
	db 10010010b ; Access byte
	db 11001111b ; Flags
	db 0x00      ; Base

.end:

.desc:
	dw gdt.end - gdt.start -1 ; Size
	dd gdt.start              ; Address

pm:
.load:
	call start.newline
	mov ah, 03h
	mov bh, 0
	int 10h             ; Get cursor position before protected mode eats
	movzx ax, dh        ; AX = row * 80 + col
	mov bl, 80
	mul bl              ; AX = row * 80
	movzx bx, dl
	add ax, bx
	mov [cursor], ax

	cli                 ; Load global tables
	lgdt[gdt.desc]
	mov eax, cr0
	or al, 1
	mov cr0, eax
	jmp CODE_OFFSET:.go

bits 32

.go:
	mov ax, DATA_OFFSET
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax
	mov ebp, 0x9C00
	mov esp, ebp

	in al, 0x92
	or al, 2
	out 0x92, al

.print:
	movzx edi, word [cursor]
	shl edi, 1
	add edi, 0xB8000

	mov ax, 0x0750
	mov [edi], ax

	mov ax, 0x074d
	mov [edi+2], ax

.halt:
	jmp .halt
