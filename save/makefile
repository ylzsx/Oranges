SRC = interrupt.asm
BIN = $(subst .asm,.com,$(SRC))
RM := ~/bash_tool/rm.sh
# .PHONY: everything

all: $(BIN)
	sudo losetup /dev/loop18 pm.img
	sudo mount /dev/loop18 /mnt/floppy/
	sudo cp $(BIN) /mnt/floppy/
	sudo umount /mnt/floppy

$(BIN): $(SRC)
	nasm $< -o $@

.PHONY:
cleanall:
	$(RM) $(BIN)
	sudo losetup -d /dev/loop18