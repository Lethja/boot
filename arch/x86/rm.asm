%include "arch/x86/config.asm"

bits 16
org 7C00h

rm:
	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7C00
	jmp .stage1

.halt:
	call .newline
	mov si, hltmsg
	call .print
	call .wait

.reboot:
	; Jump to address 0FFFFh:0 to warm reset (equivilent to pressing Ctrl-Alt-Delete)
	db 0x0ea
	dw 0x0000
	dw 0xffff

.newline:
	; Get current cursor position
	mov ah, 03h
	mov bh, 0
	int 10h

	; Move down one line
	inc dh
	mov dl, 0

	mov ah, 02h
	mov bh, 0
	int 10h

	ret

.print:
	lodsb
	test al, al
	jz .print_done

	mov ah, 0Eh
	mov bh, 0
	int 10h

	jmp .print

.print_done:
	ret

.wait:
	mov ah, 0
	int 16h
	ret

.stage1:
	mov [botdrv], dl

.stage2:
	mov bx, 0x7E00
	mov ah, 0x02
	mov al, 1
	mov ch, 0
	mov cl, 2
	mov dh, 0
	mov dl, [botdrv]
	int 0x13
	jc .halt

.cpudetect: ; Stage 3

%if BOOT_MAX == 1
    jmp BOOT_8086
%else
	; Test if CPU is 80286 compatible otherwise boot 8086
	pushf
	pop ax
	mov cx, ax
	and ax, 0FFFh      ; try to clear bits 12-15
	push ax
	popf
	pushf
	pop ax
	and ax, 0F000h
	cmp ax, 0F000h
	je BOOT_8086
%endif

%if BOOT_MAX > 2
	; Test if CPU is 80386 compatible otherwise boot 80286
	pushf
	pop ax
	mov cx, ax
	xor ax, 0F000h
	push ax
	popf
	pushf
	pop ax
	xor ax, cx
	and ax, 0F000h
	jz BOOT_80286
%else
    jmp BOOT_80286
%endif

	; Test if CPU is 80486 compatible otherwise boot 80386
	pushfd
	pop eax
	mov ecx, eax
	xor eax, 1 << 18      ; AC bit
	push eax
	popfd
	pushfd
	pop eax
	push ecx
	popfd
	xor eax, ecx
	test eax, 1 << 18
	jz .boot80386

	; Test if CPU is CPUID compatible otherwith boot 80486
	pushfd
	pop eax
	mov ecx, eax
	xor eax, 1 << 21      ; ID bit
	push eax
	popfd
	pushfd
	pop eax
	push ecx
	popfd
	xor eax, ecx
	test eax, 1 << 21
	jz .boot80486

	; Test if CPU is x86_64 compatible otherwise boot 80486 with CPUID
	mov eax, 80000000h
	cpuid
	cmp eax, 80000001h
	jb .boot80idp
	mov eax, 80000001h
	cpuid
	test edx, 1 << 29
	jz .boot80idp
	jmp .bootx8664

; Boot jumps
.boot8086:
	jmp .halt

.boot80286:
	jmp .halt

.boot80386:
	jmp pm

.boot80486:
	jmp pm

.boot80idp:
	jmp pm

.bootx8664:
	jmp lm

%include "arch/x86/pm.asm"

times 493-($-$$) db 0 ; Pad zeros for what remains of the first sector
; Values at the end of the sector
then dd pm.halt         ; Where protected mode should jump to after being initialized. Might be overwritten to jump into long mode setup
cursor dw 0x0           ; The position of the cursor
botdrv db 0             ; The disk the BIOS says it booted
hltmsg db 'RM HALTED',0 ; The halt message which is overwritten as modes change
dw 0AA55h ; BIOS boot magic number

; Sector 2 of disk

%include "arch/x86/lm.asm"
