
LUA  := lua
NASM := nasm

.PHONY: clean all

all: disk/x86_160.ima disk/x86_720.ima

disk/x86_160.ima: arch/x86/stage1.bin disk
	$(LUA) scripts/blobcat.lua 163840 $< > $@

disk/x86_720.ima: arch/x86/stage1.bin disk
	$(LUA) scripts/blobcat.lua 737280 $< > $@

arch/x86/stage1.bin: arch/x86/stage1.asm
	$(NASM) -f bin $< -o $@

clean:
	rm disk/* arch/*/*.bin

disk:
	mkdir -p disk
