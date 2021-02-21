#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "proto.h"
#include "proc.h"
#include "keyboard.h"
#include "global.h"

#define TTY_FIRST   (tty_table)
#define TTY_END     (tty_table + NR_CONSOLES)

/**
 * 初始化tty，绑定console
 * @param p_tty 要初始化的TTY
 */
PRIVATE void init_tty(TTY* p_tty) {
    p_tty->inbuf_count = 0;
    p_tty->p_inbuf_head = p_tty->p_inbuf_tail = p_tty->in_buf;
    init_screen(p_tty);
}

/**
 * 如果待处理的tty是当前显示的tty，读取keyboard buf
 * @param p_tty
 */
PRIVATE void tty_do_read(TTY* p_tty) {
    if (is_current_console(p_tty->p_console))
        keyboard_read(p_tty);
}

/**
 * 将tty buf写到屏幕
 * @param p_tty
 */
PRIVATE void tty_do_write(TTY* p_tty) {
    if (p_tty->inbuf_count) {
        char ch = *(p_tty->p_inbuf_tail);
        p_tty->p_inbuf_tail++;
        if (p_tty->p_inbuf_tail == p_tty->in_buf + TTY_IN_BYTES)
            p_tty->p_inbuf_tail = p_tty->in_buf;
        p_tty->inbuf_count--;

        out_char(p_tty->p_console, ch);
    }
}

/**
 * 将 key 放入 p_tty 对应的缓冲区
 * @param p_tty tty
 * @param key   要放入的值
 */
PRIVATE void put_key(TTY *p_tty, u32 key) {
    if (p_tty->inbuf_count < TTY_IN_BYTES) {    // 写入 tty buf
        *(p_tty->p_inbuf_head) = key;
        p_tty->p_inbuf_head++;
        if (p_tty->p_inbuf_head == p_tty->in_buf + TTY_IN_BYTES)
            p_tty->p_inbuf_head = p_tty->in_buf;
        p_tty->inbuf_count++;
    }
}

/**
 * 处理tty终端的进程: 初始化keyboard/tty -> 读keyboard buf到对应tty buf -> 写显存
 */
PUBLIC void task_tty() {
    TTY *p_tty;

    init_keyboard();
    for (p_tty = TTY_FIRST; p_tty < TTY_END; p_tty++)
        init_tty(p_tty);
    select_console(0);

    while (1) {
        for (p_tty = TTY_FIRST; p_tty < TTY_END; p_tty++) {
            tty_do_read(p_tty);
            tty_do_write(p_tty);
        }
    }
}

/**
 * 将从keyboard buf读取到的字符放入tty buf，或者直接处理不可打印字符
 * @param p_tty 要写入的tty
 * @param key   待处理的字符
 */
PUBLIC void in_process(TTY *p_tty, u32 key) {

    if (!(key & FLAG_EXT)) {    // 可打印字符
        put_key(p_tty, key);
    } else {    // 不可打印字符
        int raw_code = key & MASK_RAW;
        switch (raw_code) {
            case ENTER:
                put_key(p_tty, '\n');
                break;
            case BACKSPACE:
                put_key(p_tty, '\b');
                break;
            case UP:
                if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R))     // shift + up 屏幕向前滚动15行
                    scroll_screen(p_tty->p_console, SCR_DN);
                break;
            case DOWN:
                if ((key & FLAG_SHIFT_L) || (key & FLAG_SHIFT_R))     // shift + down
                    scroll_screen(p_tty->p_console, SCR_UP);
                break;
            case F1:
            case F2:
            case F3:
            case F4:
            case F5:
            case F6:
            case F7:
            case F8:
            case F9:
            case F10:
            case F11:
            case F12:
                if ((key & FLAG_ALT_L) || (key & FLAG_ALT_R))         // alt + F1/F2/F3 切换tty 
                    select_console(raw_code - F1);
                break;
            default:
                break;
        }
    }
}