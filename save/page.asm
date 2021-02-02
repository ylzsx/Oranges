%define _BOOT_DEBUG_

%ifdef _BOOT_DEBUG_
    org 0100h
%else
    org 7c00h
%endif

%include "pm.inc"

PageDirBase equ 200000h ; 页目录起始地址：2M
PageTblBase equ 201000h ; 页表起始地址：2M + 4K

    jmp LABEL_BEGIN


; GDT
[SECTION .gdt]
LABEL_GDT:            Descriptor            0,                0,                    0
LABEL_DESC_NORMAL:    Descriptor            0,           0ffffh,               DA_DRW   ; 用于返回实模式
LABEL_DESC_PAGE_DIR:  Descriptor  PageDirBase,             4095,               DA_DRW   ; 页目录表
LABEL_DESC_PAGE_TBL:  Descriptor  PageTblBase,         4096*8-1,               DA_DRW   ; 页表，内存空间：32M
LABEL_DESC_CODE32:    Descriptor            0,   SegCode32Len-1,           DA_C+DA_32
LABEL_DESC_CODE16:    Descriptor            0,           0ffffh,                 DA_C
LABEL_DESC_DATA:      Descriptor            0,        DataLen-1,               DA_DRW
LABEL_DESC_STACK:     Descriptor            0,       TopOfStack,        DA_DRWA+DA_32
LABEL_DESC_VIDEO:     Descriptor      0B8000h,           0ffffh,               DA_DRW

GdtLen  equ     $ - LABEL_GDT
GdtPtr  dw      GdtLen - 1      ; GDT界限
        dd      0               ; GDT基地址

SelectorNomal   equ     LABEL_DESC_NORMAL - LABEL_GDT
SelectorPageDir equ     LABEL_DESC_PAGE_DIR - LABEL_GDT
SelectorPageTbl equ     LABEL_DESC_PAGE_TBL - LABEL_GDT
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
    _szMemChkTitle      db  "BaseAddrL BaseAddrH LengthLow LengthHigh    Type", 0Ah, 0  ; 内存检查标题
    _szRAMSize          db  "RAM size:", 0
    _szReturn           db  0Ah, 0  ; 换行符
    _wSPValueInRealMode dw  0
    _dwMCRNumber        dd  0       ; Memory Check Result Number
    _dwDispPos          dd  (80 * 6 + 0) * 2    ; 打印屏幕位置
    _dwMemSize          dd  0
    _ARDStruct: ; 地址范围描述符,20字节
        _dwBaseAddrLow  dd  0
        _dwBaseAddrHigh dd  0
        _dwLengthLow    dd  0
        _dwLengthHigh   dd  0
        _dwType         dd  0
    _MemChkBuf  times 256 db 0 ; 最多能放12个地址范围描述符

    ; 保护模式下
    szPMMessge          equ _szPMMessge - $$
    szMemChkTitle       equ _szMemChkTitle - $$
    szRAMSize           equ _szRAMSize - $$
    szReturn            equ _szReturn - $$
    dwMCRNumber         equ _dwMCRNumber - $$
    dwDispPos           equ _dwDispPos - $$
    dwMemSize           equ _dwMemSize - $$
    ARDStruct:          equ _ARDStruct - $$
        dwBaseAddrLow   equ _dwBaseAddrLow - $$
        dwBaseAddrHigh  equ _dwBaseAddrHigh - $$
        dwLengthLow     equ _dwLengthLow - $$
        dwLengthHigh    equ _dwLengthHigh - $$
        dwType          equ _dwType - $$
    MemChkBuf           equ _MemChkBuf - $$

DataLen equ $ - LABEL_DATA



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

    ; 得到内存数(实模式下才能使用int中断)
    mov ebx, 0
    mov di, _MemChkBuf
.loop:
    mov eax, 0E820h
    mov ecx, 20
    mov edx, 0534D4150h
    int 15h                 ; CF=1表示发生错误；ebx=0表示结束
    jc LABEL_MEM_CHK_FAIL   ; CF=1时跳转
    add di, 20                  ; do {
    inc dword [_dwMCRNumber]    ;   _asm {int 15h;}
    cmp ebx, 0                  ;   if (CF = 1) [_dwMCRNumber]=0; fail
    jne .loop                   ;   else {
    jmp LABEL_MEM_CHK_OK        ;       di = di +20;
LABEL_MEM_CHK_FAIL:             ;       [_dwMCRNumber] += 1;
    mov dword [_dwMCRNumber], 0 ;   }
LABEL_MEM_CHK_OK:               ; } while (ebx != 0);

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

    ; 加载GDTR
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [GdtPtr + 2], eax
    lgdt [GdtPtr]

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

    ; 关闭地址线A20
    in al, 92h
    and al, 11111101b
    out 92h, al

    ; 开中断
    sti

    ; 回到DOS
    mov ax, 4c00h
    int 21h




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

    push szMemChkTitle
    call DispStr
    add esp, 4

    call DispMemSize

    call SetupPaging

    jmp SelectorCode16:0    ; 跳转到16位保护模式，准备回到实模式

; 启动分页机制
SetupPaging:
    push eax
    push ebx
    push ecx
    push edx
    push edi

    xor edx, edx
    mov eax, [dwMemSize]
    mov ebx, 400000h        ; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
    div ebx                 ; eax / ebx = eax ... edx
    mov ecx, eax
    test edx, edx
    jz .no_remainder
    inc ecx
.no_remainder:
    push ecx                ; 暂存页表个数

    ; 简化处理，所有线性地址对应相等的物理地址，且不考虑内存空洞
    ; 初始化页目录表PDE
    mov ax, SelectorPageDir
    mov es, ax
    xor edi, edi
    xor eax, eax
    mov eax, PageTblBase | PG_P | PG_USU | PG_RWW   ; 使第一个PDE中的页表首地址为PageTblBase,属性为存在的可读可写用户级页表
.1:
    stosd   ; eax -> es:edi, edi = edi + 4
    add eax, 4096
    loop .1

    ; 初始化所有页表PTE
    mov ax, SelectorPageTbl
    mov es, ax
    pop eax             ; 页表个数
    mov ebx, 1024       ; 每个页表1024个PTE
    mul ebx             ; eax * ebx = edx,eax
    mov ecx, eax
    xor eax, eax
    xor edi, edi
    mov eax, PG_P | PG_USU | PG_RWW
.2:
    stosd
    add eax, 4096
    loop .2

    mov eax, PageDirBase
    mov cr3, eax
    mov eax, cr0
    or eax, 80000000h
    mov cr0, eax

    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
; SetupPaging End

DispMemSize:
    push esi
    push edi
    push eax
    push ecx
    push edx
    
    mov esi, MemChkBuf
    mov ecx, [dwMCRNumber]  ; for (i = 0; i < [dwMCRNumber]; i++) {
.loop:                      ;     
    mov edx, 5              ;     for (j = 0; j < 5; j++) {
    mov edi, ARDStruct      ; 
.1:                         ; 
    push dword [esi]        ; 
    call DispInt            ;         DispInt(MemChkBuf[j*4]);
    call DispSpace          ;         printf(" ");
    pop eax                 ;
    stosd                   ;         ARDStruct[j*4] = MemChkBuf[j*4];
    add esi, 4              ;
    dec edx                 ;
    cmp edx, 0              ;
    jnz .1                  ;     }
    call DispReturn         ;     printf("\n");
    cmp dword [dwType], 1   ;     if ([dwType] == AddressRangeMemory) {
    jne .2                  ;
    mov eax, [dwBaseAddrLow];
    add eax, [dwLengthLow]  ;         if ([dwBaseAddrLow] + [dwLengthLow] > [dwMemSize]) {
    cmp eax, [dwMemSize]    ;             [dwMemSize] = [dwBaseAddrLow] + [dwLengthLow];
    jb .2                   ;         }
    mov [dwMemSize], eax    ;             
.2:                         ;     }
    loop .loop              ; }

    call DispReturn          ; printf("\n");
    push szRAMSize          ;
    call DispStr            ; printf("RAM size:");
    add esp, 4
    push dword [dwMemSize]  ;
    call DispInt            ; printf("%d", [dwMemSize]);
    add esp, 4

    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    ret
; DispMemSize End

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