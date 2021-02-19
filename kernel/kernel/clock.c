#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 时钟中断处理函数
 * @param irq   进程号
 */
PUBLIC void clock_handler(int irq) {
    
    ticks++;
    p_proc_ready->ticks--;

    if (k_reenter != 0)
        return;

    // if (p_proc_ready->ticks > 0) 
    //     return;

    schedule();
}

/**
 * 做一定延迟
 * @param milli_sec 延迟时间，单位毫秒
 */
PUBLIC void milli_delay(int milli_sec) {
    
    int t = get_ticks();
    while(((get_ticks() - t) * 1000 / HZ) < milli_sec) ;
}

/**
 * 初始化时钟周期、时钟中断程序
 */
PUBLIC void init_clock() {
    // 初始化 8253//8254 PIT
    out_byte(TIMER_MODE, RATE_GENERATOR);
    out_byte(TIMER0, (u8)(TIMER_FREQ/HZ));
    out_byte(TIMER0, (u8)((TIMER_FREQ/HZ) >> 8));   // 先写低字节，再写高字节

    // 设定时钟中断处理程序，并打开时钟中断使能
    put_irq_handler(CLOCK_IRQ, clock_handler);
    enable_irq(CLOCK_IRQ);
}