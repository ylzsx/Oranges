/* 和进程有关的定义 */
#ifndef _ORANGES_PROC_H__
#define _ORANGES_PROC_H__

typedef struct s_stackframe {
    u32 gs;         // 保存进程状态时压栈
    u32 fs;
    u32 es;
    u32 ds;
    u32 edi;
    u32 esi;
    u32 ebp;
    u32 kernel_esp;
    u32 ebx;
    u32 edx;
    u32 ecx;
    u32 eax;
    u32 retaddr;    // ...
    u32 eip;        // 跨权跳转时压栈
    u32 cs;
    u32 eflags;
    u32 esp;
    u32 ss;
} STACK_FRAME;

typedef struct s_proc {
    STACK_FRAME regs;
    u16 ldt_sel;                // ldt在gdt中对应的选择子
    DESCRIPTOR ldts[LDT_SIZE];  // ldt描述符
    u32 pid;                    // 进程号，用于内存管理
    char p_name[16];            // 进程名
} PROCESS;

// 进程个数
#define NR_TASKS    1

#define STACK_SIZE_TESTA    0x8000
#define STACK_SIZE_TOTAL    STACK_SIZE_TESTA

#endif