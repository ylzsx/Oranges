[section .text]     ; 代码段

global _start

_start:
    mov ah, 0Ch
    mov al, 'K'
    mov [gs:((80 * 1 + 39) * 2)], ax
    jmp $