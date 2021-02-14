#ifndef _ORANGES_TYPE_H__
#define _ORANGES_TYPE_H__

typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;

typedef void (*int_handler) (void);
typedef void (*task_f) (void);
typedef void (*irq_handler) (int irq);
typedef void* system_call;  // 保证能存放各种形式的系统调用处理函数

#endif