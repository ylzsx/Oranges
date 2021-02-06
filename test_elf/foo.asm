extern choose

[section .data]
    num1st dd 3
    num2nd dd 4

[section .text]

global _start
global myprint

_start:
    push dword [num2nd]
    push dword [num1st]
    call choose
    add esp, 8

    mov ebx, 0
    mov eax, 1  ; sys_exit
    int 0x80

myprint:
    mov ecx, [esp + 4]  ; msg
    mov edx, [esp + 8]  ; len
    mov ebx, 1
    mov eax, 4  ; sys_write
    int 0x80
    ret
