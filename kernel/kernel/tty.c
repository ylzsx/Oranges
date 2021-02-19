#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "keyboard.h"
#include "global.h"

/**
 * 持续扫描键盘缓冲区，打印字符
 */
PUBLIC void task_tty() {
    while (1) {
        keyboard_read();
    }
}

PUBLIC void in_process(u32 key) {
    char output[2] = {'\0', '\0'};

    if (!(key & FLAG_EXT)) {    // 可打印字符
        output[0] = key & 0xFF;
        disp_str(output);
    }
}