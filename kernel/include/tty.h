#ifndef _ORANGES_TTY_H__
#define _ORANGES_TTY_H__

#define TTY_IN_BYTES    256

struct s_console;

typedef struct s_tty {
    u32 in_buf[TTY_IN_BYTES];   // TTY输入缓冲区
    u32 *p_inbuf_head;          // 指向缓冲区中下一个空闲位置
    u32 *p_inbuf_tail;          // 指向要处理的字符
    int inbuf_count;            // 缓冲区中有效字符个数
    struct s_console *p_console;// 该TTY对应的控制台
} TTY;

#endif