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


#endif
