BOOT := boot.asm
LDR	:= loader.asm
BOOT_BIN := $(subst .asm,.bin,$(BOOT))
LDR_BIN := $(subst .asm,.bin,$(LDR))
RM := ~/bash_tool/rm.sh

IMG := os.img
FLOPPY := /mnt/floppy/

all: everything

everything:$(BOOT_BIN) $(LDR_BIN)
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	sudo mount -o loop $(IMG) $(FLOPPY)
	sudo cp $(LDR_BIN) $(FLOPPY) -v
	sudo umount $(FLOPPY)

%.bin: %.asm
	nasm $< -l $(subst .asm,.o,$<) -o $@

.PYTHON:
clean:
	$(RM) *.bin *.o

	

