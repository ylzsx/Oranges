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

/* 8253/8254 PIT */
#define TIMER0          0x40        // I/O port for timer channel 0
#define TIMER_MODE      0x43        // I/O port for timer mode control
#define RATE_GENERATOR  0x34        // 00(0号端口) 11(写两个字节)  010(模式2) 0(二进制)
#define TIMER_FREQ      1193182L    // PC 上的输入频率
#define HZ              100         // 时钟中断频率

/* Color */
#define BLACK           0x0     /* 0000 */
#define WHITE           0x7     /* 0111 */
#define RED             0x4     /* 0100 */
#define GREEN           0x2     /* 0010 */
#define BLUE            0x1     /* 0001 */
#define FLASH           0x80    /* 1000 0000 */
#define BRIGHT          0x08    /* 0000 1000 */
#define MAKE_COLOR(x, y) (x | y) /* MAKE_COLOR(Background,Foreground) */

/* 8042 键盘控制器 */
#define KB_DATA         0x60    // I/O port for keyboard data
#define KB_CMD          0x64    // I/O port for keyboard command
#define LED_CODE        0xED    // 设置键盘 LED 的命令
#define KB_ACK          0xFA    // 键盘返回的ACK

/* TTY */
#define NR_CONSOLES     3

/* VGA */
#define CRTC_ADDR_REG   0x3D4   /* CRT Controller Registers - Addr Register */
#define CRTC_DATA_REG   0x3D5   /* CRT Controller Registers - Data Register */
#define START_ADDR_H    0xC     /* reg index of video mem start addr (MSB) */
#define START_ADDR_L    0xD     /* reg index of video mem start addr (LSB) */
#define CURSOR_H        0xE     /* reg index of cursor position (MSB) */
#define CURSOR_L        0xF     /* reg index of cursor position (LSB) */
#define V_MEM_BASE      0xB8000 /* base of color video memory */
#define V_MEM_SIZE      0x8000  /* 32K: B8000H -> BFFFFH */

#endif
