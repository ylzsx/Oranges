%include "sconst.inc"

; 导入函数
extern cstart
extern kernel_main
extern exception_handler
extern spurious_irq
extern disp_str
extern delay

; 导入全局变量
extern gdt_ptr
extern idt_ptr
extern disp_pos
extern p_proc_ready
extern tss
extern k_reenter

BITS 32
[SECTION .data]
clock_int_msg db "^", 0


BITS 32
[section .bss]
StackSpace resb 2 * 1024
StackTop:


[section .text]     ; 代码段

global _start
global restart

; 导出异常处理函数入口
global divide_error
global single_step_exception
global nmi
global breakpoint_exception
global overflow
global bounds_check
global inval_opcode
global copr_not_available
global double_fault
global copr_seg_overrun
global inval_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global copr_error
global hwint00
global hwint01
global hwint02
global hwint03
global hwint04
global hwint05
global hwint06
global hwint07
global hwint08
global hwint09
global hwint10
global hwint11
global hwint12
global hwint13
global hwint14
global hwint15

_start:
    ; 切换堆栈
    mov esp, StackTop

    mov dword [disp_pos], 0

    ; 切换GDT
    sgdt [gdt_ptr]
    call cstart
    lgdt [gdt_ptr]

    ; 设置idt
    lidt [idt_ptr]

    jmp SELECTOR_KERNEL_CS:csinit

csinit:
    ; 设置tr寄存器，加载tss
    xor eax, eax
    mov ax, SELECTOR_TSS
    ltr ax

    jmp kernel_main

    ;hlt


restart:
    mov esp, [p_proc_ready]             ; esp <- 进程控制块起始地址
    lldt [esp + P_LDT_SEL]              ; 加载进程LDT
    lea eax, [esp + P_STACKTOP]         ; eax <- 偏移地址
    mov dword [tss + TSS3_S_SP0], eax   ; 保存 ring1 -> ring0 堆栈切换需要的地址

    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp, 4
    iretd


; 外部中断，宏定义
%macro hwint_master 1
    push %1
    call spurious_irq
    add esp, 4
    hlt
%endmacro

%macro hwint_slave 1
    push %1
    call spurious_irq
    add esp, 4
    hlt
%endmacro

; 主8059A
ALIGN 16
hwint00:                ; Interrupt routine for irq 0 (the clock).
    sub esp, 4      ; 跳过进程控制块中的retaddr
    pushad
    push ds
    push es
    push fs
    push gs         ; 保存进程现场
    mov dx, ss
    mov ds, dx
    mov es, dx

    inc byte [gs:0]

    mov al, EOI
    out INT_M_CTL, al   ; 通知8259A中断处理结束

    inc dword [k_reenter]
    cmp dword [k_reenter], 0
    jne .re_enter       ; 解决重入

    mov esp, StackTop   ; 切换到内核栈

    sti                 ; 开中断，允许中断嵌套

    push clock_int_msg
    call disp_str
    add esp, 4

    push 1
    call delay
    add esp, 4

    cli                             ; 关中断

    mov esp, [p_proc_ready]         ; 切换到进程栈

    lea eax, [esp + P_STACKTOP]
    mov dword [tss + TSS3_S_SP0], eax  ; 保存 ring1 -> ring0 时进入的进程栈顶位置

.re_enter:
    dec dword [k_reenter]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp, 4
    iretd




ALIGN 16
hwint01:                ; Interrupt routine for irq 1 (keyboard)
    hwint_master    1

ALIGN 16
hwint02:                ; Interrupt routine for irq 2 (cascade!)
    hwint_master    2

ALIGN 16
hwint03:                ; Interrupt routine for irq 3 (second serial)
    hwint_master    3

ALIGN 16
hwint04:                ; Interrupt routine for irq 4 (first serial)
    hwint_master    4

ALIGN 16
hwint05:                ; Interrupt routine for irq 5 (XT winchester)
    hwint_master    5

ALIGN 16
hwint06:                ; Interrupt routine for irq 6 (floppy)
    hwint_master    6

ALIGN 16
hwint07:                ; Interrupt routine for irq 7 (printer)
    hwint_master    7

; 从8259A
ALIGN 16
hwint08:                ; Interrupt routine for irq 8 (realtime clock).
    hwint_slave     8

ALIGN 16
hwint09:                ; Interrupt routine for irq 9 (irq 2 redirected)
    hwint_slave     9

ALIGN 16
hwint10:                ; Interrupt routine for irq 10
    hwint_slave     10

ALIGN 16
hwint11:                ; Interrupt routine for irq 11
    hwint_slave     11

ALIGN 16
hwint12:                ; Interrupt routine for irq 12
    hwint_slave     12

ALIGN 16
hwint13:                ; Interrupt routine for irq 13 (FPU exception)
    hwint_slave     13

ALIGN 16
hwint14:                ; Interrupt routine for irq 14 (AT winchester)
    hwint_slave     14

ALIGN   16
hwint15:                ; Interrupt routine for irq 15
    hwint_slave     15


; 中断和异常
divide_error:
    push 0xFFFFFFFF     ; no err code
    push 0              ; vector_no = 0
    jmp exception
single_step_exception:
    push 0xFFFFFFFF     ; no err code
    push 1              ; vector_no = 1
    jmp exception
nmi:
    push 0xFFFFFFFF     ; no err code
    push 2              ; vector_no = 2
    jmp exception
breakpoint_exception:
    push 0xFFFFFFFF     ; no err code
    push 3              ; vector_no = 3
    jmp exception
overflow:
    push 0xFFFFFFFF     ; no err code
    push 4              ; vector_no = 4
    jmp exception
bounds_check:
    push 0xFFFFFFFF     ; no err code
    push 5              ; vector_no = 5
    jmp exception
inval_opcode:
    push 0xFFFFFFFF     ; no err code
    push 6              ; vector_no = 6
    jmp exception
copr_not_available:
    push 0xFFFFFFFF     ; no err code
    push 7              ; vector_no = 7
    jmp exception
double_fault:
    push 8              ; vector_no = 8
    jmp exception
copr_seg_overrun:
    push 0xFFFFFFFF     ; no err code
    push 9              ; vector_no = 9
    jmp exception
inval_tss:
    push 10             ; vector_no = A
    jmp exception
segment_not_present:
    push 11             ; vector_no = B
    jmp exception
stack_exception:
    push 12             ; vector_no = C
    jmp exception
general_protection:
    push 13             ; vector_no = D
    jmp exception
page_fault:
    push 14             ; vector_no = E
    jmp exception
copr_error:
    push 0xFFFFFFFF     ; no err code
    push 16             ; vector_no = 10h
    jmp exception

; 堆栈栈顶: vector_no(中断向量号)、err_code/0xFFFFFFFF、eip、cs、eflags
exception:
    call exception_handler
    add esp,4*2         ; 栈顶指向eip
    hlt