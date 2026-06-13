page_directory_pointer_table equ 4096
page_directory               equ 8192

lm:
	; Jump back into long mode setup after switching to protected mode
	mov eax, .after_pm
	mov [then], eax
	cli
	jmp pm

.after_pm:
	; Allocate aligned 16KB region
	mov edi, end_boot
	add edi, 4095
	and edi, 0xFFFFF000
	mov [base], edi


	; Clear 16KB for page tables
	xor eax, eax
	mov ecx, 4096*4/4
	mov edi, [base]
	rep stosd


	; Build paging
	mov edi, [base]
	mov eax, edi
	add eax, page_directory_pointer_table
	mov ebx, edi
	add ebx, page_directory

	; Page map level 4 to page directory pointer table
	mov [edi], eax
	or  dword [edi], 3

	; Page directory pointer table to page directory
	mov [eax], ebx
	or  dword [eax], 3

	; Page_directory to 2MB identity mapping
	mov dword [ebx], 0x83

	; Load CR3
	mov eax, [base]
	mov cr3, eax

	; Enable long mode
	mov eax, cr4
	or  eax, (1 << 5)          ; PAE
	mov cr4, eax

	mov ecx, 0xC0000080
	rdmsr
	or  eax, (1 << 8)          ; LME
	wrmsr

	mov eax, cr0
	or  eax, (1 << 31)         ; PG
	mov cr0, eax

	; Patch CS descriptor to 64-bit (L=1, D=0), then far jump
	mov byte [gdt.c_flags], 10101111b
	jmp CODE_OFFSET:.halt

bits 64
default rel

.halt:
%ifdef AUTOTEST
    mov eax, 0
    jmp rm.halt
%else
	mov byte [halt_message], 'L'
	mov rsi, halt_message
	call .print
	call pm.wait
	call .reboot

.reboot:
	cli

.reboot_idt:
	; Triple fault the long mode processor forcing a reset
	dw 0
	dq 0
	lidt [.reboot_idt]
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
	ret

.print_put_char:
	push rbx
	push rdi

	mov bl, al

	movzx rdi, word [cursor]
	shl rdi, 1
	add rdi, 0xB8000

	mov al, bl
	mov ah, 0x07
	mov [rdi], ax

	inc word [cursor]

	pop rdi
	pop rbx
	ret

base dq 0
