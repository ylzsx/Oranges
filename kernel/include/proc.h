/* 和进程有关的定义 */
#ifndef _ORANGES_PROC_H__
#define _ORANGES_PROC_H__

typedef struct s_stackframe {
    u32 gs;         // 保存进程状态,由中断服务程序压栈
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
    u32 retaddr;    // call save语句产生的、被压栈的返回地址
    u32 eip;        // 跨权跳转时，由硬件压栈
    u32 cs;
    u32 eflags;
    u32 esp;
    u32 ss;
} STACK_FRAME;

typedef struct s_proc {
    STACK_FRAME regs;
    u16 ldt_sel;                // ldt在gdt中对应的选择子
    DESCRIPTOR ldts[LDT_SIZE];  // ldt描述符
    int ticks;                  // 初始值等于priority,每被调度一次减一，减为0后重新赋值为priority
    int priority;               // 优先级
    u32 pid;                    // 进程号，用于内存管理
    char p_name[16];            // 进程名
} PROCESS;

/* 初始化进程控制块时，会用到该结构体 */
typedef struct s_task {
    task_f initial_eip;         // 进程起始位置
    int stacksize;              // 进程需要的堆栈大小
    char name[32];              // 进程名字
} TASK;

// 进程个数
#define NR_TASKS            1
#define NR_PROCS            3

#define STACK_SIZE_TTY      0x8000
#define STACK_SIZE_TESTA    0x8000
#define STACK_SIZE_TESTB    0x8000
#define STACK_SIZE_TESTC    0x8000

#define STACK_SIZE_TOTAL    (STACK_SIZE_TTY + STACK_SIZE_TESTA + STACK_SIZE_TESTB + STACK_SIZE_TESTC)

#endif