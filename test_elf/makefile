RM := ~/bash_tool/rm.sh

all: foobar

foobar: bar.o foo.o
	ld -m elf_i386 -s -o $@ $^

bar.o: bar.c
	gcc -m32 -c $< -o $@

foo.o: foo.asm
	nasm -f elf $< -o $@

.PHONY:
clean:
	$(RM) *.o foobar
