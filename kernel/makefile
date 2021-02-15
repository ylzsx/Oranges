# Entry point of Orange's.
# It must have the same value with 'KernelEntryPointPhyAddr' in load.inc!
ENTRYPOINT = 0x30400

# Offset of entry point in kernel file.
# It depends on ENTRYPOINT
ENTRYOFFSET = 0x400

# Programs, flags, etc.
ASM = nasm
DASM = ndisasm
CC = gcc
LD = ld
ASMBFLAGS = -I boot/include/
ASMKFLAGS = -I include/ -f elf
CFLAGS = -m32 -I include/ -c -Wall -fno-builtin -fno-stack-protector
LDFLAGS = -m elf_i386 -s -Ttext $(ENTRYPOINT)
DASMFLAGS = -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)

# Source
BOOT = boot/boot.asm
LDR	= boot/loader.asm
BOOT_BIN = $(subst .asm,.bin,$(BOOT))
LDR_BIN = $(subst .asm,.bin,$(LDR))
KERNEL_BIN = kernel.bin
IMG = os.img
FLOPPY = /mnt/floppy/
RM = ~/bash_tool/rm.sh

# This Program output
ORANGESBOOT = $(BOOT_BIN) $(LDR_BIN)
ORANGESKERNEL = $(KERNEL_BIN)
OBJS = kernel/kernel.o kernel/start.o kernel/main.o kernel/i8259.o kernel/global.o kernel/protect.o \
	   kernel/clock.o kernel/keyboard.o kernel/syscall.o kernel/proc.o \
	   lib/klib.o lib/kliba.o lib/string.o
DASMOUTPUT = kernel.bin.asm

.PHONY:
	all everything debug clean cleandebug cleanall

all: everything
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp $(LDR_BIN) $(FLOPPY) -v
	sudo cp $(ORANGESKERNEL) $(FLOPPY) -v
	sudo umount $(FLOPPY)

everything: $(ORANGESBOOT) $(ORANGESKERNEL)

debug: $(ORANGESKERNEL)
	$(DASM) $(DASMFLAGS) $(ORANGESKERNEL) > $(DASMOUTPUT)

cleandebug:
	$(RM) $(DASMOUTPUT)

clean:
	$(RM) $(OBJS) $(ORANGESBOOT) $(ORANGESKERNEL)

cleanall: clean cleandebug

$(BOOT_BIN): $(BOOT) boot/include/load.inc boot/include/fat12hdr.inc
	$(ASM) $(ASMBFLAGS) $< -o $@

$(LDR_BIN): $(LDR) boot/include/load.inc boot/include/fat12hdr.inc boot/include/pm.inc boot/include/lib.inc
	$(ASM) $(ASMBFLAGS) $< -o $@

$(KERNEL_BIN): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $(KERNEL_BIN)

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

%.o: %.asm
	$(ASM) $(ASMKFLAGS) $< -o $@
