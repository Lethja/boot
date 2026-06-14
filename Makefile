
LUA         := lua
NASM        := nasm
BLFLAGS     :=
QEMU_I386   := qemu-system-i386
QEMU_X86_64 := qemu-system-x86_64
TEST_ADDR   := 0xf4

.PHONY: clean demo unit-test zip

demo: disk/x86_160.ima disk/x86_720.ima

zip: zip/disks.zip

disk/x86_160.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 163840 $< > $@

disk/x86_720.ima: bin/x86/boot.bin disk
	$(LUA) scripts/blobcat.lua 737280 $< > $@

bin/x86/boot.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm bin
	$(NASM) $(BLFLAGS) -f bin $< -o $@

clean:
	rm -Rf bin disk test zip

disk:
	mkdir -p disk

bin:
	mkdir -p bin/{x86,}

qemu-i386: disk/x86_720.ima
	$(QEMU_I386) $< -d int,cpu_reset

qemu-x86_64: disk/x86_720.ima
	$(QEMU_X86_64) $< -d int,cpu_reset

zip/disks.zip: demo
	mkdir -p zip
	zip --DOS-names -j9 $@ disk/*

# Unit test rules
unit-test: test-qemu-rm test-qemu-pm test-qemu-lm

test:
	mkdir -p $@

test/test8086.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=1 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/testi286.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=2 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/testi386.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=3 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/testi486.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=4 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/testcpui.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=5 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/testlong.bin: arch/x86/rm.asm arch/x86/lm.asm arch/x86/pm.asm arch/x86/config.asm test
	$(NASM) -DBOOT_MAX=6 -DAUTOTEST=$(TEST_ADDR) -f bin $< -o $@

test/test%.ima: test/test%.bin test
	$(LUA) scripts/blobcat.lua 163840 $< > $@

test-qemu-rm: test/test8086.ima test/testi286.ima
	for img in $^; do \
		timeout 5 $(QEMU_I386) $$img -nographic -display none -device isa-debug-exit,iobase=$(TEST_ADDR),iosize=0x04 < /dev/null > /dev/null 2>&1; status=$$?; [ $$status -eq 1 ] || exit "$$status"; \
	done

test-qemu-pm: test/testi386.ima test/testi486.ima test/testcpui.ima
	for img in $^; do \
		timeout 5 $(QEMU_I386) $$img -nographic -display none -device isa-debug-exit,iobase=$(TEST_ADDR),iosize=0x04 < /dev/null > /dev/null 2>&1; status=$$?; [ $$status -eq 1 ] || exit "$$status"; \
	done

test-qemu-lm: test/testlong.ima
	for img in $^; do \
		timeout 5 $(QEMU_I386) $$img -nographic -display none -device isa-debug-exit,iobase=$(TEST_ADDR),iosize=0x04 < /dev/null > /dev/null 2>&1; status=$$?; [ $$status -eq 1 ] || exit "$$status"; \
	done
