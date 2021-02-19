#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "keyboard.h"
#include "keymap.h"
#include "global.h"

PRIVATE KB_INPUT kb_in;

PRIVATE int code_with_E0 = 0;
PRIVATE int shift_l;
PRIVATE int shift_r;
PRIVATE int alt_l;
PRIVATE int alt_r;
PRIVATE int ctrl_l;
PRIVATE int ctrl_r;
PRIVATE int caps_lock;
PRIVATE int num_lock;
PRIVATE int scroll_lock;
PRIVATE int column;

/**
 * 键盘中断处理程序
 * @param irq
 */
PUBLIC void keyboard_handler(int irq) {
    u8 scan_code = in_byte(KB_DATA);

    // 将读入的值写入键盘缓冲区
    if (kb_in.count < KB_IN_BYTES) {
        *(kb_in.p_head) = scan_code;
        kb_in.p_head++;
        if (kb_in.p_head == kb_in.buf + KB_IN_BYTES)
            kb_in.p_head = kb_in.buf;
        kb_in.count++;
    }
}

/**
 * 初始化键盘中断处理程序
 */
PUBLIC void init_keyboard() {
    kb_in.count = 0;
    kb_in.p_head = kb_in.p_tail = kb_in.buf;

    shift_l = shift_r = 0;
    alt_l = alt_r = 0;
    ctrl_l = ctrl_r = 0;

    put_irq_handler(KEYBOARD_IRQ, keyboard_handler);
    enable_irq(KEYBOARD_IRQ);
}

/**
 * 读取键盘缓冲区
 * @return 返回读取到的字节
 */
PRIVATE u8 get_byte_from_kbuf() {
    u8 scan_code;

    while (kb_in.count <= 0) ;  // 等待下一个字节的到来

    disable_int();  // 关中断读缓冲区
    scan_code = *(kb_in.p_tail);
    kb_in.p_tail++;
    if (kb_in.p_tail == kb_in.buf + KB_IN_BYTES)
        kb_in.p_tail = kb_in.buf;
    kb_in.count--;
    enable_int();

    return scan_code;
}

/**
 * 解析扫描码
 */
PUBLIC void keyboard_read() {
    u8 scan_code;
    int make;       // TRUE: make code; FALSE: break code
    u32 key = 0;    // 表示键,低8位(0~7)为真正的键值，第8位为1表示不可打印字符，第9位为1表示 shift_l....(详见keyboard.h)
    u32 *keyrow;    // 指向keymap[]的一行

    if (kb_in.count > 0) {
        code_with_E0 = 0;
        scan_code = get_byte_from_kbuf();

        // 解析扫描码
        if (scan_code == 0xE1) {
            int i;
            u8 pausebrk_scode[] = {0xE1, 0x1D, 0x45, 0xE1, 0x9D, 0xC5}; // Pause键 make code
            int is_pausebreak = 1;

            for (i = 1; i < 6; i++) {
                if (get_byte_from_kbuf() != pausebrk_scode[i]) {
                    is_pausebreak = 0;
                    break;
                }
            }
            if (is_pausebreak)
                key = PAUSEBREAK;
        } else if (scan_code == 0xE0) {
            scan_code = get_byte_from_kbuf();
            if (scan_code == 0x2A) {    // PrintScreen 按下
                if (get_byte_from_kbuf() == 0xE0)
                    if (get_byte_from_kbuf() == 0x37) {
                        key = PRINTSCREEN;
                        make = 1;
                    }
            }
            if (scan_code == 0xB7) {    // PrintScreen 被释放
                if (get_byte_from_kbuf() == 0xE0)
                    if (get_byte_from_kbuf() == 0xAA) {
                        key = PRINTSCREEN;
                        make = 0;
                    }
            }

            if (key == 0) {     // scan_code此时为0xE0后跟的值
                code_with_E0 = 1;
            }
        }

        if ((key != PAUSEBREAK) && (key != PRINTSCREEN)) {    // 除 PAUSEBREAK PRINTSCREEN 外的所有键
            make = (scan_code & FLAG_BREAK ? 0 : 1);
            keyrow = &keymap[(scan_code & 0x7F) * MAP_COLS];
            column = 0;

            if (shift_l || shift_r)
                column = 1;
            if (code_with_E0) {
                column = 2;
                code_with_E0 = 0;
            }

            key = keyrow[column];
            switch (key) {
                case SHIFT_L:
                    shift_l = make;
                    break;
                case SHIFT_R:
                    shift_r = make;
                    break;
                case CTRL_L:
                    ctrl_l = make;
                    break;
                case CTRL_R:
                    ctrl_r = make;
                    break;
                case ALT_L:
                    alt_l = make;
                    break;
                case ALT_R:
                    alt_r = make;
                    break;
                default:
                    break;
            }

            if (make) {     // 忽略 break code
                key |= (shift_l ? FLAG_SHIFT_L : 0);
                key |= (shift_r ? FLAG_SHIFT_R : 0);
                key |= (ctrl_l ? FLAG_CTRL_L : 0);
                key |= (ctrl_r ? FLAG_CTRL_R : 0);
                key |= (alt_l ? FLAG_ALT_L : 0);
                key |= (alt_r ? FLAG_ALT_L : 0);

                in_process(key);
            }
        }
    }
}