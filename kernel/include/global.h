/* 通常情况下，EXTERN被定义为 extern，但当宏 GLOBAL_VARIABLES_HERE 存在时，定义为空 */
#ifdef GLOBAL_VARIABLES_HERE
#undef EXTERN
#define EXTERN
#endif

EXTERN int disp_pos;

EXTERN u8 gdt_ptr[6];       //  0~15:Limit  16~47:Base
EXTERN DESCRIPTOR gdt[GDT_SIZE];

EXTERN u8 idt_ptr[6];       //  0~15:Limit  16~47:Base
EXTERN GATE idt[IDT_SIZE];