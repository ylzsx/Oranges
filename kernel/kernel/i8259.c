#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 外部中断处理
 * @param irq   中断向量号
 */
PUBLIC void spurious_irq(int irq) {
    disp_str("spurious_irq: ");
    disp_int(irq);
    disp_str("\n");
}

/**
 *  初始化中断控制器
 */
PUBLIC void init_8259A() {
    /* Master 8259, ICW1. */
    out_byte(INT_M_CTL, 0x11);

    /* Slave  8259, ICW1. */
    out_byte(INT_S_CTL, 0x11);

    /* Master 8259, ICW2. 设置 '主8259' 的中断入口地址为 0x20. */
    out_byte(INT_M_CTLMASK, INT_VECTOR_IRQ0);

    /* Slave  8259, ICW2. 设置 '从8259' 的中断入口地址为 0x28 */
    out_byte(INT_S_CTLMASK, INT_VECTOR_IRQ8);

    /* Master 8259, ICW3. IR2 对应 '从8259'. */
    out_byte(INT_M_CTLMASK, 0x4);

    /* Slave  8259, ICW3. 对应 '主8259' 的 IR2. */
    out_byte(INT_S_CTLMASK, 0x2);

    /* Master 8259, ICW4. */
    out_byte(INT_M_CTLMASK, 0x1);

    /* Slave  8259, ICW4. */
    out_byte(INT_S_CTLMASK, 0x1);

    /* Master 8259, OCW1. 屏蔽所有中断 */
    out_byte(INT_M_CTLMASK, 0xFF);

    /* Slave  8259, OCW1. 屏蔽所有中断 */
    out_byte(INT_S_CTLMASK, 0xFF);

    int i;
    for (i = 0; i < NR_IRQ; i++)
        irq_table[i] = spurious_irq;
}

/**
 * 为制定外部中断设置中断处理程序
 * @param irq       中断向量号
 * @param handler   中断处理程序入口
 */
PUBLIC void put_irq_handler(int irq, irq_handler handler) {
    disable_irq(irq);   // 屏蔽此中断，需要使用时再打开
    irq_table[irq] = handler;
}