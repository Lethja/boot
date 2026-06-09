
LUA  := lua
NASM := nasm

.PHONY: clean all

all: disk/x86_160.ima disk/x86_720.ima

disk/x86_160.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 163840 $< > $@

disk/x86_720.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 737280 $< > $@

bin/x86/boot.bin: arch/x86/stage1.asm arch/x86/pm.asm bin
	$(NASM) -f bin $< -o $@

clean:
	rm -R bin disk

disk:
	mkdir -p disk

bin:
	mkdir -p bin/{x86,}
