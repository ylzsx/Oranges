#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "proc.h"
#include "global.h"

/**
 * 进程调度函数
 * @param irq   进程号
 */
PUBLIC void clock_handler(int irq) {
    disp_str("#");
    p_proc_ready++;
    if (p_proc_ready >= proc_table + NR_TASKS)
        p_proc_ready = proc_table;
}