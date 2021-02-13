#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"
#include "string.h"
#include "proc.h"
#include "global.h"

PUBLIC void cstart() {
    disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n-----\"cstart\" begins-----\n");

    // 切换 GDT，0~15:Limit  16~47:Base
    memcpy(&gdt, (void *)(*((u32*)(&gdt_ptr[2]))), *((u16*)(&gdt_ptr[0])) + 1);
    u16* p_gdt_limit = (u16*)(&gdt_ptr[0]);
    u32* p_gdt_base = (u32*)(&gdt_ptr[2]);
    *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1;
    *p_gdt_base = (u32)&gdt;

    // 初始化idt
    u16* p_idt_limit = (u16*)(&idt_ptr[0]);
    u32* p_idt_base = (u32*)(&idt_ptr[2]);
    *p_idt_limit = IDT_SIZE * sizeof(GATE) - 1;
    *p_idt_base = (u32)&idt;

    // 初始化中断控制器，并设置IDT表
    init_prot();

    disp_str("-----\"cstart\" ends-----\n");
}