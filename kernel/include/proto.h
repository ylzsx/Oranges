/* 函数声明 */
/* lib/klib.asm */
PUBLIC void out_byte(u16 port, u8 value);           // 写8059A
PUBLIC u8 in_byte(u16 port);                        // 读8259A

PUBLIC void disp_str(char *pszInfo);                // 显示字符串
PUBLIC void disp_color_str(char *info, int color);  // 显示带色字符串

PUBLIC void disable_irq(int irq);                   // 屏蔽指定外部中断
PUBLIC void enable_irq(int irq);                    // 使能指定外部中断 

/* lib/klib,c */
PUBLIC void disp_int(int input);                    // 打印一个32位整形数
PUBLIC void delay(int time);                        // 延迟一段时间

/* i8259.c */
PUBLIC void init_8259A();                           // 初始化中断控制器
PUBLIC void put_irq_handler(int irq, irq_handler handler);  // 为指定中断设置中断处理程序

/* protect.c */
PUBLIC void init_prot();                            // 设置IDT

/* main.c */
void TestA();                                       // 进程A
void TestB();                                       // 进程B
void TestC();                                       // 进程C

/* kernel.asm */
void restart();
PUBLIC void sys_call();                             // 系统调用处理函数

/* clock.c */
PUBLIC void clock_handler(int irq);                 // 时钟中断，进程调度

/* syscall.asm */
PUBLIC int get_ticks();                             // 系统调用,返回发生时钟中断次数

/* proc.c */
PUBLIC int sys_get_ticks();