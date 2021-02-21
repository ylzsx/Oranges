#include "type.h"
#include "const.h"
#include "protect.h"
#include "tty.h"
#include "console.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 系统调用，得到时钟中断发生的次数
 * @return
 */
PUBLIC int sys_get_ticks() {
    return ticks;
}

/**
 * 进程调度函数
 */
PUBLIC void schedule() {
    PROCESS *p;
    int greatest_ticks = 0;

    while (!greatest_ticks) {
        for (p = proc_table; p < proc_table + NR_TASKS + NR_PROCS; p++) {
            if (p->ticks > greatest_ticks) {
                greatest_ticks = p->ticks;
                p_proc_ready = p;
            }
        }

        if (!greatest_ticks) {
            for (p = proc_table; p < proc_table + NR_TASKS + NR_PROCS; p++)
                p->ticks = p->priority;
        }
    }
}