#ifndef _ORANGES_CONST_H__
#define _ORANGES_CONST_H__

/* EXTERN is defined as extern except in global.c */
#define EXTERN extern

/* 函数类型 */
#define PUBLIC          // 全局变量
#define PRIVATE static  // 局部变量

/* GDT 和 IDT中描述符的个数 */
#define GDT_SIZE 128
#define IDT_SIZE 256

/* 8259A 中断控制器端口 */
#define INT_M_CTL     0x20 /* I/O port for interrupt controller       <Master> */
#define INT_M_CTLMASK 0x21 /* setting bits in this port disables ints <Master> */
#define INT_S_CTL     0xA0 /* I/O port for second interrupt controller<Slave>  */
#define INT_S_CTLMASK 0xA1 /* setting bits in this port disables ints <Slave>  */

/* 权限 */
#define PRIVILEGE_KRNL 0
#define PRIVILEGE_TASK 1
#define PRIVILEGE_USER 3

/* RPL */
#define RPL_KRNL SA_RPL0
#define RPL_TASK SA_RPL1
#define RPL_USER SA_RPL3

/* Boolean */
#define TRUE    1
#define FALSE   0

/* 硬件中断 */
#define NR_IRQ          16      // 外部中断个数

#define CLOCK_IRQ       0       // 时钟中断
#define KEYBOARD_IRQ    1       // 键盘中断
#define CASCADE_IRQ     2       // cascade enable for 2nd AT controller 
#define ETHER_IRQ       3       // default ethernet interrupt vector
#define SECONDARY_IRQ   3       // RS232 interrupt vector for port 2
#define RS232_IRQ       4       // RS232 interrupt vector for port 1
#define XT_WINI_IRQ     5       // xt winchester
#define FLOPPY_IRQ      6       // 软盘中断
#define PRINTER_IRQ     7       // 打印机中断
#define AT_WINI_IRQ     14      // at winchester

/* 系统调用 */
#define NR_SYS_CALL     1

#endif
