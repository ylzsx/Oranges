BOOT := boot.asm
LDR	:= loader.asm
KERNEL := kernel.asm
BOOT_BIN := $(subst .asm,.bin,$(BOOT))
LDR_BIN := $(subst .asm,.bin,$(LDR))
KERNEL_BIN := $(subst .asm,.bin,$(KERNEL))
RM := ~/bash_tool/rm.sh

IMG := os.img
FLOPPY := /mnt/floppy/

all: everything

everything:$(BOOT_BIN) $(LDR_BIN) $(KERNEL_BIN)
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp $(LDR_BIN) $(FLOPPY) -v
	sudo cp $(KERNEL_BIN) $(FLOPPY) -v
	sudo umount $(FLOPPY)

%.bin: %.asm
	nasm $< -l $(subst .asm,.s,$<) -o $@

$(KERNEL_BIN):$(KERNEL)
	nasm -f elf $< -l $(subst .asm,.s,$<) -o $(subst .asm,.o,$<)
	ld -m elf_i386 -s -o $@ $(subst .asm,.o,$<)

.PYTHON:
clean:
	$(RM) *.bin *.o *.s

	

