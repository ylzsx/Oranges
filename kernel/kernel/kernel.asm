
SELECTOR_KERNEL_CS equ 8

extern cstart
extern gdt_ptr

[section .bss]
StackSpace resb 2 * 1024
StackTop:



[section .text]     ; 代码段

global _start

_start:
    ; 切换堆栈
    mov esp, StackTop

    ; 切换GDT
    sgdt [gdt_ptr]
    call cstart
    lgdt [gdt_ptr]

    jmp SELECTOR_KERNEL_CS:csinit

csinit:
    push 0
    popfd   ; Pop top of stack into EFLAGS
    hlt