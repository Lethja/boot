lm:
	; Jump back into long mode setup after switching to protected mode
	mov eax, .after_pm
	mov [then], eax
	jmp pm

.after_pm:
	; Continue into long mode
	mov byte [hltmsg], 'L'
	jmp pm.halt
