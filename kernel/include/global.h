/* 通常情况下，EXTERN被定义为 extern，但当宏 GLOBAL_VARIABLES_HERE 存在时，定义为空 */
#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN
#endif

/* 真实定义会在编译时由global.c生成 */

EXTERN int disp_pos;

EXTERN u8 gdt_ptr[6];       //  0~15:Limit  16~47:Base
EXTERN DESCRIPTOR gdt[GDT_SIZE];

EXTERN u8 idt_ptr[6];       //  0~15:Limit  16~47:Base
EXTERN GATE idt[IDT_SIZE];

EXTERN TSS tss;
EXTERN PROCESS *p_proc_ready;

EXTERN u32 k_reenter;           // 解决中断重入的变量

EXTERN int ticks;               // 时钟中断个数

EXTERN int nr_current_console;  // 当前控制台

extern PROCESS proc_table[];            // 进程控制块表，存放所有进程
extern char task_stack[];               // 进程占用堆栈
extern TASK task_table[];               // 初始化时任务信息
extern TASK user_proc_table[];          // 初始化用户进程信息
extern irq_handler irq_table[];         // 外部中断处理程序
extern system_call sys_call_table[];    // 系统调用处理程序
extern TTY tty_table[];                 // tty
extern CONSOLE console_table[];         // 控制台