
    org 0100h

%include "pm.inc"

    jmp LABEL_BEGIN


; GDT
[SECTION .gdt]
LABEL_GDT:            Descriptor            0,                0,                        0
LABEL_DESC_NORMAL:    Descriptor            0,           0ffffh,                   DA_DRW ; 用于返回实模式
LABEL_DESC_CODE32:    Descriptor            0,   SegCode32Len-1,              DA_CR|DA_32
LABEL_DESC_CODE16:    Descriptor            0,           0ffffh,                     DA_C
LABEL_DESC_DATA:      Descriptor            0,        DataLen-1,                   DA_DRW
LABEL_DESC_STACK:     Descriptor            0,       TopOfStack,            DA_DRWA+DA_32
LABEL_DESC_VIDEO:     Descriptor      0B8000h,           0ffffh,                   DA_DRW

GdtLen  equ     $ - LABEL_GDT
GdtPtr  dw      GdtLen - 1      ; GDT界限
        dd      0               ; GDT基地址

SelectorNomal   equ     LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32  equ     LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16  equ     LABEL_DESC_CODE16 - LABEL_GDT
SelectorData    equ     LABEL_DESC_DATA - LABEL_GDT
SelectorStack   equ     LABEL_DESC_STACK - LABEL_GDT
SelectorVideo   equ     LABEL_DESC_VIDEO - LABEL_GDT


; 数据段
[SECTION .data1]
ALIGN 32
[BITS 32]
LABEL_DATA:
    ; 实模式下
    _szPMMessge         db  "In Protect Mode now.", 0Ah, 0Ah, 0
    _szReturn           db  0Ah, 0  ; 换行符
    _wSPValueInRealMode dw  0
    _dwDispPos          dd  (80 * 6 + 0) * 2    ; 打印屏幕位置
    _SavedIDTR          dd  0
                        dd  0
    _SavedIMREG1        db  0
    _SavedIMREG2        db  0

    ; 保护模式下
    szPMMessge          equ _szPMMessge - $$
    szReturn            equ _szReturn - $$
    dwDispPos           equ _dwDispPos - $$
    SavedIDTR           equ _SavedIDTR - $$
    SavedIMREG1         equ _SavedIMREG1 - $$
    SavedIMREG2         equ _SavedIMREG2 - $$

DataLen equ $ - LABEL_DATA



; IDT, 中断向量描述符
[SECTION .idt]
ALIGN 32
[BITS 32]
LABEL_IDT:
%rep 32
    Gate SelectorCode32,    SpuriousHandler,        0,      DA_386IGate
%endrep
.020h:
    Gate SelectorCode32,       ClockHandler,        0,      DA_386IGate
%rep 95
    Gate SelectorCode32,    SpuriousHandler,        0,      DA_386IGate
%endrep
.080h:
    Gate SelectorCode32,     UserIntHandler,        0,      DA_386IGate

IdtLen  equ $ - LABEL_IDT
IdtPtr  dw  IdtLen - 1
        dd  0



; 堆栈段
[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
    times 512 db 0

TopOfStack equ $ - LABEL_STACK - 1



; 实模式下 16位代码段
[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h

    mov [LABEL_GO_BACK_TO_REAL + 3], ax
    mov [_wSPValueInRealMode], sp

    ; 初始化16位代码段描述符
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, LABEL_SEG_CODE16
    mov word [LABEL_DESC_CODE16 + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_CODE16 + 4], al
    mov byte [LABEL_DESC_CODE16 + 7], ah

    ; 初始化32位代码段描述符
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, LABEL_SEG_CODE32
    mov word [LABEL_DESC_CODE32 + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_CODE32 + 4], al
    mov byte [LABEL_DESC_CODE32 + 7], ah

    ; 初始化数据段描述符
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_DATA
    mov word [LABEL_DESC_DATA + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_DATA + 4], al
    mov byte [LABEL_DESC_DATA + 7], ah

    ; 初始化堆栈段描述符
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_STACK
    mov word [LABEL_DESC_STACK + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_STACK + 4], al
    mov byte [LABEL_DESC_STACK + 7], ah

    ; 加载GDTR准备
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [GdtPtr + 2], eax
    
    ; 加载IDTR准备
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_IDT
    mov dword [IdtPtr + 2], eax

    ; 保存原来IDTR 和 中断屏蔽寄存器(IMREG)
    sidt [_SavedIDTR]
    in al, 21h
    mov [_SavedIMREG1], al
    in al, 0A1h
    mov [_SavedIMREG2], al

    lgdt [GdtPtr]
    lidt [IdtPtr]

    ; 关中断
    cli

    ; 打开地址线A20
    in al, 92h
    or al, 00000010b
    out 92h, al

    ; 进入保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword SelectorCode32:0

LABEL_REAL_ENTRY:   ; 从保护模式回到实模式
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, [_wSPValueInRealMode]

    lidt [_SavedIDTR]
    mov al, [_SavedIMREG1]
    out 21h, al
    mov al, [_SavedIMREG2]
    out 0A1h, al

    ; 关闭地址线A20
    in al, 92h
    and al, 11111101b
    out 92h, al

    ; 开中断
    sti



[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
    mov ax, SelectorData
    mov ds, ax
    mov es, ax
    mov ax, SelectorVideo
    mov gs, ax
    mov ax, SelectorStack
    mov ss, ax
    mov esp, TopOfStack

    ; 显示字符串
    push szPMMessge     ; esp = esp - 4, (esp) = szPMMessge, 堆栈传参
    call DispStr
    add esp, 4

    call Init8259A

    int 21h
    int 080h
    call io_delay
    sti
    jmp $
    ; call run_delay

    cli

    jmp SelectorCode16:0    ; 跳转到16位保护模式，准备回到实模式

; 初始化8259A
Init8259A:
    mov al, 011h
    out 020h, al        ; 主8259, ICW1.
    call io_delay

    out 0A0h, al        ; 从8259, ICW1.
    call io_delay

    mov al, 020h        ; IRQ0 对应中断向量 0x20
    out 021h, al        ; 主8259, ICW2.
    call io_delay

    mov al, 028h        ; IRQ8 对应中断向量 0x28
    out 0A1h, al        ; 从8259, ICW2.
    call io_delay

    mov al, 004h        ; IR2 对应从8259
    out 021h, al        ; 主8259, ICW3.
    call io_delay

    mov al, 002h        ; 对应主8259的 IR2
    out 0A1h, al        ; 从8259, ICW3.
    call io_delay

    mov al, 001h
    out 021h, al        ; 主8259, ICW4.
    call io_delay

    out 0A1h, al        ; 从8259, ICW4.
    call io_delay

    mov al, 11111110b   ; 仅开启定时器中断
    out 21h, al
    call io_delay

    mov al, 11111111b   ; 关闭8259A从片所有中断
    out 0A1h, al
    call io_delay

    ret

; Init8259A End

; SetRealmode8259A:
;     mov ax, SelectorData
;     mov fs, ax

;     mov al, 017h
;     out 020h, al        ; 主8259, ICW1.
;     call io_delay

;     mov al, 008h        ; IRQ0 对应中断向量 0x8
;     out 021h, al        ; 主8259, ICW2.
;     call io_delay

;     mov al, 001h
;     out 021h, al        ; 主8259, ICW4.
;     call io_delay

;     mov al, [fs:SavedIMREG1] ; 恢复中断屏蔽寄存器(IMREG)的原值
;     out 21h, al
;     call io_delay

;     ret
; SetRealmode8259A End

; int handler
_ClockHandler:
    ClockHandler equ _ClockHandler - $$
    inc byte [gs:((80 * 0 + 70) * 2)]
    mov al, 20h
    out 20h, al ; 发送EOI给8259A
    iretd

_UserIntHandler:
    UserIntHandler equ _UserIntHandler - $$
    mov ah, 0Ch
    mov al, 'A'
    mov [gs:((80 * 0 + 70) * 2)], ax
    iretd

_SpuriousHandler:
    SpuriousHandler equ _SpuriousHandler - $$
    mov ah, 0Ch
    mov al, '!'
    mov [gs:((80 * 0 + 75) * 2)], ax
    iretd
; int handler End

; IO操作后延迟函数
io_delay:
    nop
    nop
    nop
    nop
    ret
; io_delay End

run_delay:
%rep 500
    nop
%endrep
    ret
; run_delay End

%include "lib.inc"
SegCode32Len equ $ - LABEL_SEG_CODE32




[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
    mov ax, SelectorNomal
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, cr0
    and eax, 7FFFFFFEh  ; PG=0, PE=0
    mov cr0, eax

LABEL_GO_BACK_TO_REAL:
    jmp 0:LABEL_REAL_ENTRY

Code16Len equ $ - LABEL_SEG_CODE16