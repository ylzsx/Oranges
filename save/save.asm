%define _BOOT_DEBUG_    ; DOS下的预编译
%include "pm.inc"

%ifdef _BOOT_DEBUG_
    org 0100h
%else
    org 7c00h
%endif
    jmp LABEL_BEGIN


[SECTION .gdt]
; GDT 段描述符
LABEL_GDT:            Descriptor        0,                0,                    0
LABEL_DESC_NORMAL:    Descriptor        0,           0ffffh,               DA_DRW ; Normal描述符，用于返回实模式
LABEL_DESC_CODE32:    Descriptor        0,   SegCode32Len-1,           DA_C+DA_32 ; 32位非一致代码段
LABEL_DESC_CODE16:    Descriptor        0,           0ffffh,                 DA_C ; 16位非一致代码段
LABEL_DESC_CODE_DEST: Descriptor        0, SegCodeDestLen-1,           DA_C+DA_32
LABEL_DESC_CODE_RING3:Descriptor        0,SegCodeRing3Len-1,   DA_C+DA_32+DA_DPL3 ; 3环非一致代码段
LABEL_DESC_DATA:      Descriptor        0,        DataLen-1,               DA_DRW ; 数据段
LABEL_DESC_STACK:     Descriptor        0,       TopOfStack,        DA_DRWA+DA_32 ; 32位堆栈段
LABEL_DESC_STACK3:    Descriptor        0,      TopOfStack3,DA_DRWA+DA_32+DA_DPL3 ; 3环堆栈段
LABEL_DESC_LDT:       Descriptor        0,         LDTLen-1,               DA_LDT ; LDT
LABEL_DESC_TSS:       Descriptor        0,         TSSLen-1,            DA_386TSS ; TSS
LABEL_DESC_TEST:      Descriptor 0500000h,           0ffffh,               DA_DRW
LABEL_DESC_VIDEO:     Descriptor  0B8000h,           0ffffh,       DA_DRW+DA_DPL3 ; 显存首地址

LABEL_CALL_GATE_TEST: Gate SelectorCodeDest,    0,      0,    DA_386CGate+DA_DPL3 ; 调用门

GdtLen equ $ - LABEL_GDT    ; GDT长度
GdtPtr dw  GdtLen - 1       ; GDT界限
       dd  0                ; GDT基地址

; GDT 选择子
SelectorNormal       equ LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode32       equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorCode16       equ LABEL_DESC_CODE16 - LABEL_GDT
SelectorCodeDest     equ LABEL_DESC_CODE_DEST - LABEL_GDT
SelectorCodeRing3    equ LABEL_DESC_CODE_RING3 - LABEL_GDT + SA_RPL3
SelectorData         equ LABEL_DESC_DATA   - LABEL_GDT
SelectorStack        equ LABEL_DESC_STACK  - LABEL_GDT
SelectorStack3       equ LABEL_DESC_STACK3 - LABEL_GDT + SA_RPL3
SelectorLDT          equ LABEL_DESC_LDT - LABEL_GDT
SelectorTSS          equ LABEL_DESC_TSS - LABEL_GDT
SelectorTest         equ LABEL_DESC_TEST   - LABEL_GDT
SelectorVideo        equ LABEL_DESC_VIDEO  - LABEL_GDT
SelectorCallGateTest equ LABEL_CALL_GATE_TEST - LABEL_GDT + SA_RPL3

; LDT
[SECTION .ldt]
ALIGN 32
LABEL_LDT:
LABEL_LDT_DESC_CODEA: Descriptor 0, CodeALen-1, DA_C+DA_32

LDTLen equ $ - LABEL_LDT

SelectorLDTCodeA  equ  LABEL_LDT_DESC_CODEA - LABEL_LDT + SA_TIL  ; TI = 1


[SECTION .data1] ; 数据段
ALIGN 32    ; 32字节对齐
[BITS 32]
LABEL_DATA:
    SPValueInRealMode dw    0
    PMMessage         db    "In Protect Mode now.", 0
    OffsetPMMessage   equ   PMMessage - $$
    StrTest           db    "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 0
    OffsetStrTest     equ   StrTest - $$
    DataLen           equ   $ - LABEL_DATA



[SECTION .gs]   ; 全局堆栈段
ALIGN 32
[BITS 32]
LABEL_STACK:
    times 512  db    0
    TopOfStack equ   $ - LABEL_STACK - 1
    


[SECTION .s3]   ; 3环堆栈段
ALIGN 32
[BITS 32]
LABEL_STACK3:
    times 512   db    0
    TopOfStack3 equ   $ - LABEL_STACK3 -1


[SECTION .tss]
ALIGN 32
[BITS 32]
LABEL_TSS:
        DD  0                   ; Back
        DD  TopOfStack          ; 0 级堆栈
        DD  SelectorStack       ; 
        DD  0                   ; 1 级堆栈
        DD  0                   ; 
        DD  0                   ; 2 级堆栈
        DD  0                   ; 
        DD  0                   ; CR3
        DD  0                   ; EIP
        DD  0                   ; EFLAGS
        DD  0                   ; EAX
        DD  0                   ; ECX
        DD  0                   ; EDX
        DD  0                   ; EBX
        DD  0                   ; ESP
        DD  0                   ; EBP
        DD  0                   ; ESI
        DD  0                   ; EDI
        DD  0                   ; ES
        DD  0                   ; CS
        DD  0                   ; SS
        DD  0                   ; DS
        DD  0                   ; FS
        DD  0                   ; GS
        DD  0                   ; LDT
        DW  0                   ; 调试陷阱标志
        DW  $ - LABEL_TSS + 2   ; I/O位图基址
        DB  0ffh                ; I/O位图结束标志
TSSLen  equ $ - LABEL_TSS



[SECTION .s16]  ; 实模式
[BITS 16]   ; 表示16位代码段
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h   ; 初始化代码段，数据段，附加段，堆栈段

    mov [LABEL_GO_BACK_TO_REAL + 3], ax   ; 为保护模式回到实模式修改段地址
    mov [SPValueInRealMode], sp ; 将栈顶指针位置保存在SPValueInRealMode地址处

    ; 初始化16位代码段描述符
    mov ax, cs
    movzx eax, ax
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

    ; 初始化LDT在GDT中的描述符
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_LDT
    mov word [LABEL_DESC_LDT + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_LDT + 4], al
    mov byte [LABEL_DESC_LDT + 7], ah
    
    ; 初始化LDT中的描述符 
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_CODE_A
    mov word [LABEL_LDT_DESC_CODEA + 2], ax
    shr eax, 16
    mov byte [LABEL_LDT_DESC_CODEA + 4], al
    mov byte [LABEL_LDT_DESC_CODEA + 7], ah

    ; 初始化测试调用门的代码段描述符
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, LABEL_SEG_CODE_DEST
    mov word [LABEL_DESC_CODE_DEST + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_CODE_DEST + 4], al
    mov byte [LABEL_DESC_CODE_DEST + 7], ah

    ; 初始化堆栈段（Ring3）
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_STACK3
    mov word [LABEL_DESC_STACK3 + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_STACK3 + 4], al
    mov byte [LABEL_DESC_STACK3 + 7], ah

    ; 初始化Ring3描述符
    xor eax, eax
    mov ax, ds  ; TODO:为什么是ds
    shl eax, 4
    add eax, LABEL_CODE_RING3
    mov word [LABEL_DESC_CODE_RING3 + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_CODE_RING3 + 4], al
    mov byte [LABEL_DESC_CODE_RING3 + 7], ah

    ; 初始化TSS
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_TSS
    mov word [LABEL_DESC_TSS + 2], ax
    shr eax, 16
    mov byte [LABEL_DESC_TSS + 4], al
    mov byte [LABEL_DESC_TSS + 7], ah

    ; 加载 GDTR
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [GdtPtr + 2], eax  ; [GdtPtr + 2] <- gdt 基地址
    lgdt [GdtPtr]

    ; 关中断
    cli

    ; 打开地址线A20
    in al, 92h
    or al, 00000010b
    out 92h, al

    ; 修改cr0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到保护模式
    jmp dword SelectorCode32:0

LABEL_REAL_ENTRY:   ; 从保护模式跳回实模式
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, [SPValueInRealMode]

    ; 关闭A20地址线
    in al, 92h
    and al, 11111101b
    out 92h, al

    ; 开中断
    sti  
    
    mov ax, 4c00h
    int 21h         ; 回到DOS



[SECTION .s32]  ; 保护模式
[BITS 32]   ; 32位代码段
LABEL_SEG_CODE32:
    mov ax, SelectorData
    mov ds, ax
    mov ax, SelectorTest
    mov es, ax
    mov ax, SelectorVideo
    mov gs, ax
    mov ax, SelectorStack
    mov ss, ax
    mov esp, TopOfStack

    ; 显示一个字符串
    mov ah, 0Ch
    xor esi, esi
    xor edi, edi
    mov esi, OffsetPMMessage
    mov edi, (80 * 10 + 0) * 2  ; 屏幕第10行，第0列
    cld                         ; 将flag方向标志位df清零

.1:
    lodsb               ; 将esi所指的一个字节装入al，后esi++
    test al, al         ; al做与运算，即当字符串结束时，设置zf = 1
    jz .2
    mov [gs:edi], ax    ; 一个像素点占据两个字节
    add edi, 2
    jmp .1

.2:
    call DisReturn
    call TestRead
    call TestWrite
    call TestRead

    ; 初始化TSS
    mov ax, SelectorTSS
    ltr ax

    ; 从0环跳转到3环
    push SelectorStack3
    push TopOfStack3
    push SelectorCodeRing3
    push 0
    retf

LABEL_REAL_LDT:
    ; 初始化LDT表
    mov ax, SelectorLDT
    lldt ax

    jmp SelectorLDTCodeA:0  ; 跳入局部任务

    ;jmp SelectorCode16:0    ; 跳转到保护模式下16位代码段

;------------------------------------
TestRead:
    push esi
    push ecx
    xor esi, esi
    mov ecx, 8
.loop:
    mov al, [es:esi]
    call DisAL
    inc esi
    loop .loop

    call DisReturn

    pop ecx
    pop esi 
    ret
;-------------------------------------

;-------------------------------------
TestWrite:
    push esi
    push edi

    xor esi, esi
    xor edi, edi
    mov esi, OffsetStrTest
    cld

.1:
    lodsb
    test al, al
    jz .2
    mov [es:edi], al
    inc edi
    jmp .1

.2:

    pop edi
    pop esi
    ret
;-------------------------------------

;-------------------------------------
DisAL:
    push ecx
    push edx

    mov ah, 0Ch
    mov dl, al
    shr al, 4
    mov ecx, 2

.begin:
    and al, 01111b
    cmp al, 9
    ja .1   ; al > 9发生跳转
    add al, '0'
    jmp .2
.1:
    sub al, 0Ah
    add al, 'A'
.2:
    mov [gs:edi], ax
    add edi, 2

    mov al, dl
    loop .begin
    add edi, 2

    pop edx
    pop ecx
    ret
;-------------------------------------

;-------------------------------------
DisReturn:
    push eax
    push ebx

    mov eax, edi
    mov bl, 160 ; 一行的字节数
    div bl      ; ax / bl = al ... ah
    and eax, 0FFh
    inc eax
    mov bl, 160
    mul bl      ; al * bl = ax
    mov edi, eax

    pop ebx
    pop eax
    ret
;-------------------------------------

SegCode32Len equ $ - LABEL_SEG_CODE32
OffsetLDT    equ LABEL_REAL_LDT - $$


[SECTION .ring3]    ; 3环代码段
ALIGN 32
[BITS 32]
LABEL_CODE_RING3:
    mov ax, SelectorVideo
    mov gs, ax

    mov edi, (80 * 15 + 1) * 2
    mov ah, 0ch
    mov al, '3'
    mov [gs:edi], ax

    call SelectorCallGateTest:0 ; 调用门

    jmp $   ; 不能进入该死循环
SegCodeRing3Len equ $ - LABEL_CODE_RING3



[SECTION .sdest]    ; 调用门目标段(0环)
ALIGN 32
[BITS 32]
LABEL_SEG_CODE_DEST:
    mov ax, SelectorVideo
    mov gs, ax

    mov edi, (80 * 15 + 2) * 2
    mov ah, 0ch
    mov al, '0'
    mov [gs:edi], ax

    jmp dword SelectorCode32:OffsetLDT    ; 回到32位主程序
    ;retf
SegCodeDestLen equ $ - LABEL_SEG_CODE_DEST



[SECTION .s16code]  ; 16位保护模式，用于跳出保护模式
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
    ; 跳回实模式
    mov ax, SelectorNormal
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, cr0
    and al, 11111110b
    mov cr0, eax

LABEL_GO_BACK_TO_REAL:
    jmp 0:LABEL_REAL_ENTRY  ; 段地址在开始时已被设置为正确值

Code16Len equ $ - LABEL_SEG_CODE16



[SECTION .la]   ; LDT, 32位代码段
ALIGN 32
[BITS 32]
LABEL_CODE_A:
    mov ax, SelectorVideo
    mov gs, ax

    mov edi, (80 * 15 + 0) * 2
    mov ah, 0ch
    mov al, 'L'
    mov [gs:edi], ax

    jmp SelectorCode16:0

CodeALen equ $ - LABEL_CODE_A
