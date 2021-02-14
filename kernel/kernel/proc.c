#include "type.h"
#include "const.h"
#include "protect.h"
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