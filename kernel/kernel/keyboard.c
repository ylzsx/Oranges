#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 键盘中断处理程序
 * @param irq
 */
PUBLIC void keyboard_handler(int irq) {
    disp_str("*");
}

/**
 * 初始化键盘中断处理程序
 */
PUBLIC void init_keyboard() {
    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
    enable_irq(KEYBOARD_IRQ);
}