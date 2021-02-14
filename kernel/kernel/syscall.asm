%include "sconst.inc"

_NR_get_ticks       equ 0       ; 必须和 global.c 中 sys_call_table 的定义对应
INT_VECTOR_SYS_CALL equ 0x90    ; 系统调用的中断向量号

; 导出函数
global get_ticks

BITS 32
[section .text]

get_ticks:
    mov eax, _NR_get_ticks
    int INT_VECTOR_SYS_CALL
    ret
