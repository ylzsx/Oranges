#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 设置光标位置
 * @param position
 */
PRIVATE void set_cursor(unsigned int position) {
    disable_int();
    out_byte(CRTC_ADDR_REG, CURSOR_H);
    out_byte(CRTC_DATA_REG, (position >> 8) & 0xFF);
    out_byte(CRTC_ADDR_REG, CURSOR_L);
    out_byte(CRTC_DATA_REG, position & 0xFF);
    enable_int();
}

/**
 * 设置屏幕起始页地址
 * @param addr 显存地址偏移(相对于0xB8000)
 */
PRIVATE void set_video_start_addr(u32 addr) {
    disable_int();
    out_byte(CRTC_ADDR_REG, START_ADDR_H);
    out_byte(CRTC_DATA_REG, (addr >> 8) & 0xFF);
    out_byte(CRTC_ADDR_REG, START_ADDR_L);
    out_byte(CRTC_DATA_REG, addr & 0xFF);
    enable_int();
}

/**
 * 判断是否当前控制台
 * @param p_con 要判断的控制台
 * @return 如果是当前控制台返回1， 否则返回0
 */
PUBLIC int is_current_console(CONSOLE* p_con) {
    return p_con == &console_table[nr_current_console];
}

/**
 * 将字符输出到指定控制台
 * @param p_con 指定控制台
 * @param ch    输出字符
 */
PUBLIC void out_char(CONSOLE* p_con, char ch) {
    u8 *p_vmem = (u8*)(V_MEM_BASE + p_con->cursor * 2);

    *p_vmem++ = ch;
    *p_vmem++ = DEFAULT_CHAR_COLOR;
    p_con->cursor++;

    set_cursor(p_con->cursor);
}

/**
 * 初始化console
 * @param p_tty
 */
PUBLIC void init_screen(TTY *p_tty) {
    int nr_tty = p_tty - tty_table;
    p_tty->p_console = console_table + nr_tty;

    int v_mem_size = V_MEM_SIZE >> 1;   // 显存总大小 in word
    int con_v_mem_size = v_mem_size / NR_CONSOLES;
    p_tty->p_console->original_addr = nr_tty * con_v_mem_size;
    p_tty->p_console->v_mem_limit = con_v_mem_size;
    p_tty->p_console->current_start_addr = p_tty->p_console->original_addr;

    p_tty->p_console->cursor = p_tty->p_console->original_addr;
    if (nr_tty == 0) {  // 第一个控制台沿用原来的光标位置
        p_tty->p_console->cursor = disp_pos / 2;
        disp_pos = 0;
    } else {    // 其他控制台打印当前tty值
        out_char(p_tty->p_console, 'T');
        out_char(p_tty->p_console, 'T');
        out_char(p_tty->p_console, 'Y');
        out_char(p_tty->p_console, nr_tty + '0');
        out_char(p_tty->p_console, '#');
    }

    set_cursor(p_tty->p_console->cursor);
}

/**
 * 切换控制台
 * @param nr_console 控制台编号
 */
PUBLIC void select_console(int nr_console) {
    if (nr_console < 0 || nr_console >= NR_CONSOLES)
        return;

    nr_current_console = nr_console;
    set_video_start_addr(console_table[nr_console].current_start_addr);
    set_cursor(console_table[nr_console].cursor);
}

/**
 * 滚屏
 * @param p_con     要滚动的屏幕指针
 * @param direction 方向：SCR_UP(向上，显示上面显存的文字) / SCR_DN(向下)
 */
PUBLIC void scroll_screen(CONSOLE *p_con, int direction) {

    if (direction == SCR_UP) {  // up
        if (p_con->current_start_addr > p_con->original_addr)
            p_con->current_start_addr -= SCREEN_WIDTH;
    } else if (direction == SCR_DN) {   // down
        if (p_con->current_start_addr + SCREEN_SIZE < p_con->original_addr + p_con->v_mem_limit)
            p_con->current_start_addr += SCREEN_WIDTH;
    }

    set_video_start_addr(p_con->current_start_addr);
    set_cursor(p_con->cursor);
}