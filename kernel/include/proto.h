/* 函数声明 */
/* lib/klib.asm */
PUBLIC void out_byte(u16 port, u8 value);           // 写8059A
PUBLIC u8 in_byte(u16 port);                        // 读8259A

PUBLIC void disp_str(char *pszInfo);                // 显示字符串
PUBLIC void disp_color_str(char *info, int color);  // 显示带色字符串

/* lib/klib,c */
PUBLIC void disp_int(int input);                    // 打印一个32位整形数
PUBLIC void delay(int time);                        // 延迟一段时间

/* i8259.c */
PUBLIC void init_8259A();                           // 初始化中断控制器

/* protect.c */
PUBLIC void init_prot();                            // 设置IDT

/* main.c */
void TestA();                                       // 进程A

/* kernel.asm */
void restart();