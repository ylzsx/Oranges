#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"


PUBLIC int kernel_main() {

    disp_str("-----\"kernel_main\" begins-----\n");

    // 初始化进程控制块
    TASK *p_task = task_table;
    PROCESS *p_proc = proc_table;
    char *p_task_stack = task_stack + STACK_SIZE_TOTAL;
    u16 selector_ldt = SELECTOR_LDT_FIRST;
    int i;

    for (i = 0; i < NR_TASKS; i++) {
        strcpy(p_proc->p_name, p_task->name);
        p_proc->pid = i;
        p_proc->ldt_sel = selector_ldt;
        
        memcpy(&p_proc->ldts[0], &gdt[SELECTOR_KERNEL_CS >> 3], sizeof(DESCRIPTOR));  // 将内核代码段和数据段复制到第一个进程中
        p_proc->ldts[0].attr1 = DA_C | (PRIVILEGE_TASK << 5);     // 修改DPL=1
        memcpy(&p_proc->ldts[1], &gdt[SELECTOR_KERNEL_DS >> 3], sizeof(DESCRIPTOR));
        p_proc->ldts[1].attr1 = DA_DRW | (PRIVILEGE_TASK << 5);
        p_proc->regs.cs = ((8 * 0) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;   // 0000 | 0100 | 0001 = 0101
        p_proc->regs.ds = ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;   // 1000 | 0100 | 0001 = 1101
        p_proc->regs.es = ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.fs = ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.ss = ((8 * 1) & SA_RPL_MASK & SA_TI_MASK) | SA_TIL | RPL_TASK;
        p_proc->regs.gs = (SELECTOR_KERNEL_GS & SA_RPL_MASK) | RPL_TASK;

        p_proc->regs.eip = (u32)p_task->initial_eip;
        p_proc->regs.esp = (u32)p_task_stack;
        p_proc->regs.eflags = 0x1202;       // IF = 1, IOPL = 1, bit 2 is always 1.

        p_task_stack -= p_task->stacksize;
        selector_ldt += 8;
        p_task++;
        p_proc++;
    }

    k_reenter = 0;  // 中断重入时会用到该变量
    ticks = 0;

    p_proc_ready = proc_table;

    // 设定时钟中断处理程序，并打开时钟中断使能
    put_irq_handler(CLOCK_IRQ, clock_handler);
    enable_irq(CLOCK_IRQ);

    restart();

    while (1) {}
}

/**
 * 进程A
 */
void TestA() {
    while (1) {
        disp_str("A");
        disp_int(get_ticks());
        disp_str(".");
        delay(1);
    }
}

/**
 * 进程B
 */
void TestB() {
    int i = 0x1000;
    while (1) {
        disp_str("B");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}

/**
 * 进程C
 */
void TestC() {
    int i = 0x2000;
    while (1) {
        disp_str("C");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}