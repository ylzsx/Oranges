#ifndef _ORABGES_CONSOLE_H__
#define _ORABGES_CONSOLE_H__

typedef struct s_console {
    unsigned int current_start_addr;    // 当前显示页的起始地址
    unsigned int original_addr;         // 当前控制台对应的起始显存位置, 从0开始
    unsigned int v_mem_limit;           // 当前控制台的显存大小
    unsigned int cursor;                // 当前光标位置(只记录字符个数，当需要打印时，设计者乘2)
} CONSOLE;

#define DEFAULT_CHAR_COLOR  0x07        // 0000 0111 黑底白字

#define SCR_UP  1                       // 内容向上滚屏
#define SCR_DN  -1                      // 内容向下滚屏

#define SCREEN_SIZE     (80 * 25)       // 一个文本模式屏幕所能显示字符数
#define SCREEN_WIDTH    80              // 一个文本模式屏幕一行

#endif