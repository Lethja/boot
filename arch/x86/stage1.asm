bits 16
org 7C00h

start:
	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7C00
	jmp .stage1

.halt:
	call .newline
	mov si, hltmsg
	call .print
.halt_hang:
	hlt
	jmp .halt_hang

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
	mov si, cpumsg
	call .newline
	call .print

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
	je .boot8086

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
	jz .boot80286

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
	jmp .boot80idp

.boot8086:
	mov si, cpu086msg
	call .print
	jmp .halt

.boot80286:
	mov si, cpu286msg
	call .print
	jmp .halt

.boot80386:
	mov si, cpu386msg
	call .print
	jmp .halt

.boot80486:
	mov si, cpu486msg
	call .print
	jmp .halt
	
.boot80idp:
	mov si, cpuidpmsg
	call .print
	jmp .halt

.bootx8664:
	mov si, cpu64bmsg
	call .print
	jmp .halt

botdrv db 0
cpumsg db 'CPU ARCH',0
cpu086msg db '      8086',0
cpu286msg db '     80286',0
cpu386msg db '     80386',0
cpu486msg db '     80486',0
cpuidpmsg db '    80486+',0
cpu64bmsg db '    x86_64',0
hltmsg db 'HALTED',0

times 510-($-$$) db 0
dw 0AA55h
