
LUA  := lua
NASM := nasm
QEMU_I386 := qemu-system-i386
QEMU_X86_64 := qemu-system-x86_64

.PHONY: clean all

all: disk/x86_160.ima disk/x86_720.ima

disk/x86_160.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 163840 $< > $@

disk/x86_720.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 737280 $< > $@

bin/x86/boot.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm bin
	$(NASM) -f bin $< -o $@

clean:
	rm -R bin disk

disk:
	mkdir -p disk

bin:
	mkdir -p bin/{x86,}

qemu-i386: disk/x86_720.ima
	$(QEMU_I386) $< -d int,cpu_reset

qemu-x86_64: disk/x86_720.ima
	$(QEMU_X86_64) $< -d int,cpu_reset