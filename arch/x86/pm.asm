VIDEO_MEMORY     equ 0xB8000
WHITE_ON_BLACK   equ 0x0F

CODE_OFFSET equ 0x8
DATA_OFFSET equ 0x10

gdt:
.start:
	dd 0x0
	dd 0x0

	; Code Segment descriptor
	dw 0xFFFF             ; Limit
	dw 0x0000             ; Base
	db 0x00               ; Base
	db 10011010b          ; Access byte
	.c_flags db 11001111b ; Flags
	db 0x00               ; Base

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
	call rm.newline
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
	mov byte [halt_message], 'P'
	jmp [then]

.halt:
%ifdef AUTOTEST
    mov al, 0
    jmp rm.halt
%else
	mov esi, halt_message
	call .print
	call .wait

.reboot:
	cli

.reboot_idt:
	; Triple fault the protected mode processor forcing a reset
	lidt [gdt.start]
	int 3
%endif

.print:
.print_next:
	lodsb
	test al, al
	jz .print_done

	call .print_put_char
	jmp .print_next

.print_done:
	call .update_cursor
	ret

.print_put_char:
	push ebx
	push edi
	mov bl, al
	movzx edi, word [cursor]
	shl edi, 1                ; *2 bytes per cell
	add edi, VIDEO_MEMORY
	mov al, bl
	mov ah, 0x07
	mov [edi], ax
	inc word [cursor]
	pop edi
	pop ebx
	ret

.update_cursor:
	mov bx, [cursor]
	mov dx, 0x3D4
	mov al, 0x0F
	out dx, al
	mov dx, 0x3D5
	mov al, bl
	out dx, al
	mov dx, 0x3D4
	mov al, 0x0E
	out dx, al
	mov dx, 0x3D5
	mov al, bh
	out dx, al
	ret

.wait:
	; Wait for keyboard input
	in al, 0x64
	test al, 1
	jz .wait

	; Read scan code
	in al, 0x60
	ret
