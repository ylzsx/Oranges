; loader
    org 0100h

BaseOfStack         equ 0100h   ; 堆栈基址，从该地址开始向低地址生长
MessageLength       equ 9       ; 为方便操作，屏幕显示字符串长度尽量设为9字节

    jmp LABEL_BEGIN

%include "fat12hdr.inc"
%include "load.inc"
%include "pm.inc"

; GDT
LABEL_GDT:          Descriptor       0,          0,                          0
LABEL_DESC_FLAT_C:  Descriptor       0,    0fffffh,    DA_CR|DA_32|DA_LIMIT_4K   ; 0~4G
LABEL_DESC_FLAT_RW: Descriptor       0,    0fffffh,   DA_DRW|DA_32|DA_LIMIT_4K   ; 0~4G
LABEL_DESC_VIDEO:   Descriptor 0B8000h,     0ffffh,             DA_DRW|DA_DPL3

GdtLen equ $ - LABEL_GDT
GdtPtr dw  GdtLen - 1
       dd  BaseOfLoaderPhyAddr + LABEL_GDT

SelectorFlatC   equ LABEL_DESC_FLAT_C - LABEL_GDT
SelectorFlatRW  equ LABEL_DESC_FLAT_RW - LABEL_GDT
SelectorVideo   equ LABEL_DESC_VIDEO - LABEL_GDT + SA_RPL3
; GDT end

; 变量
wRootDirSizeForLoop dw RootDirSectors   ; 根目录占用扇区数，即查找根目录时，最外层循环次数
wSectorNo           dw 0                ; 要读取的扇区号
bOdd                db 0                ; 读取FAT时，需要分奇偶扇区，0为偶数，1为奇数
dwKernelSize        dd 0                ; KERNEL.BIN 文件的大小
; 常量
KernelFileName      db "KERNEL  BIN", 0 ; 11个字节
LoadMessage         db "Loading  "      ; 字符数组0
ReadyMessage        db "LodReady."      ; 字符数组1
NoKernelMessage     db "No KERNEL"      ; 字符数组2

LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

    mov dh, 0
    call DispStrRealMode

    ; 得到内存数(实模式下才能使用int 15h中断)
    mov ebx, 0
    mov di, _MemChkBuf
.loop:
    mov eax, 0E820h
    mov ecx, 20
    mov edx, 0534D4150h     ; edx = 'SMAP'
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

    ; 软驱复位
    xor ah, ah
    mov dl, [BS_DrvNum]
    int 13h

    ; 在A盘根目录寻找 KERNEL.BIN
    ; 读入根目录中的每一个扇区，以此比较扇区中目录项文件名
    mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
    cmp word [wRootDirSizeForLoop], 0
    jz LABEL_NO_KERNELBIN           ; 根目录区已经读完
    dec word [wRootDirSizeForLoop]
    mov ax, BaseOfKernelFile
    mov es, ax
    mov bx, OffsetOfKernelFile      ; es:bx = BaseOfKernelFile:OffsetOfKernelFile
    mov ax, [wSectorNo]
    mov cl, 1
    call ReadSector

    mov si, KernelFileName
    mov di, OffsetOfKernelFile
    cld
    mov dx, EntriesPerSector        ; 一个扇区的目录条目个数
LABEL_SEARCH_FOR_KERNELBIN:
    cmp dx, 0
    jz LABEL_GOTO_NEXT_SECTION_IN_ROOT_DIR  ; 比较完一个扇区的所有条目,未找到则到下一个扇区
    dec dx
    mov cx, DirEntryFileNameLen
LABEL_CMP_FILENAME:
    cmp cx, 0
    jz LABEL_FILENAME_FOUND         ; 找到 KernelFileName
    dec cx
    lodsb                           ; al <- ds:si, si = si + 1
    cmp al, byte [es:di]
    jz LABEL_GO_ON
    jmp LABEL_DIFFERENT
LABEL_GO_ON:
    inc di
    jmp LABEL_CMP_FILENAME

LABEL_DIFFERENT:
    and di, 0FFE0h              ; 指向本条目的开头
    add di, RootDirEntryLen
    mov si, KernelFileName
    jmp LABEL_SEARCH_FOR_KERNELBIN

LABEL_GOTO_NEXT_SECTION_IN_ROOT_DIR:
    add word [wSectorNo], 1
    jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_KERNELBIN:
    mov dh, 2
    call DispStrRealMode
    jmp $                       ; 没有找到 KERNEL.BIN ，进入死循环

LABEL_FILENAME_FOUND:           ; 找到 KERNEL.BIN 目录项，根据FAT到数据区加载 KERNEL.BIN
    mov ax, RootDirSectors
    and di, 0FFE0h

    push eax
    mov eax, [es:di + 01Ch]
    mov dword [dwKernelSize], eax   ; 保存 KERNEL.BIN 文件大小
    pop eax

    add di, 01Ah
    mov cx, word [es:di]        ; cx <- 此条目中包含的文件对应的开始(簇号)扇区号
    push cx
    add cx, ax
    add cx, DeltaSelectorNo     ; cx <- KERNEL.BIN的起始扇区号(0-based)
    mov ax, BaseOfKernelFile
    mov es, ax
    mov bx, OffsetOfKernelFile
    mov ax, cx

LABEL_GOON_LOADING_FILE:
    push ax
    push bx
    mov ah, 0Eh
    mov al, '.'
    mov bl, 0Fh
    int 10h             ; 在“Booting”后每读一个扇区打印一个'.'
    pop bx
    pop ax

    mov cl, 1
    call ReadSector
    pop ax
    call GetFATEntry
    cmp ax, 0FFFh
    jz LABEL_FILE_LOADED    ; 读取结束
    push ax
    mov dx, RootDirSectors
    add ax, dx
    add ax, DeltaSelectorNo
    add bx, [BPB_BytsPerSec]
    jmp LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:
    call KillMotor          ; 关闭软驱马达

    mov dh, 1
    call DispStrRealMode

    ; 进入保护模式 ----------------------------------------------
    lgdt [GdtPtr]

    ; 关中断
    cli

    ; 打开地址线A20
    in al, 92h
    or al, 00000010b
    out 92h, al

    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp dword SelectorFlatC:(BaseOfLoaderPhyAddr + LABEL_PM_START)

    jmp $     ; 将控制权转交给操作系统的启动项KERNEL.BIN



; 打印字符串
; 传入参数：dh: 打印数组序号
DispStrRealMode:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es

    mov ax, MessageLength
    mul dh
    add ax, LoadMessage
    mov bp, ax
    mov ax, ds
    mov es, ax      ; es:bp 串地址
    mov cx, MessageLength
    mov ax, 01301h
    mov bx, 0007h
    mov dl, 0
    int 10h

    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret
; DispStrRealMode End



; 读取一个扇区
; 传入参数：cl: 要读取的扇区个数; ax: 读取的扇区号; es:bx: 读入数据指向的缓存区
; -----------------------------------------------------------------------
; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
; 注意数据在磁道上的存放是在不同面上交叉存放
; -----------------------------------------------------------------------
; 设扇区号为 x
;                          ┌ 柱面号 = y / BPB_NumHeads
;       x           ┌ 商 y ┤
; -------------- => ┤      └ 磁头号 = y % BPB_NumHeads
;  每磁道扇区数       │
;                   └ 余 z => 起始扇区号 = z + 1
ReadSector:
    push bp
    mov bp, sp
    sub esp, 2  ; 空出两个字节的堆栈区保存要读的扇区数：byte [bp-2]

    mov byte [bp-2], cl
    push bx
    mov bl, [BPB_SecPerTrk]
    div bl      ; ax / bl = al ... ah
    inc ah
    mov cl, ah  ; cl <- 起始扇区号
    and ax, 0FFh
    mov bl, [BPB_NumHeads]
    div bl
    mov ch, al  ; ch <- 柱面号
    mov dh, ah  ; dh <- 磁头号
    pop bx
    mov dl, [BS_DrvNum]
.GoOnReading:
    mov ah, 2
    mov al, byte [bp-2]
    int 13h
    jc .GoOnReading     ; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

    add esp, 2
    pop bp
    ret
; ReadSector End



; 取出FAT中的序号
; 传入参数：ax: FAT中的扇区号
; 传出参数：ax: FAT中该扇区号内存放的值
GetFATEntry:
    push es
    push bx
    push ax

    mov ax, BaseOfKernelFile
    sub ax, 0100h       ; 在BaseOfKernelFile前留出4K空间存放FAT
    mov es, ax
    pop ax
    mov byte [bOdd], 0
    mov bx, 3
    mul bx              ; dx:ax = ax * bx
    mov bx, 2
    div bx              ; dx:ax / bx = ax...dx
    cmp dx, 0
    jz LABEL_EVEN
    mov byte [bOdd], 1
LABEL_EVEN: ; 偶数
    ; ax为FATEntry在FAT中的偏移量，计算FATEntry在哪个扇区
    xor dx, dx
    mov bx, [BPB_BytsPerSec]
    div bx              ; 0:ax / [BPB_BytsPerSec] = ax...dx
    push dx
    mov bx, 0
    add ax, SelectorNoOfFAT1
    mov cl, 2           ; 因为一个 FATEntry 可能跨越两个扇区,所以一次读两，防止出现错误
    call ReadSector

    pop dx
    add bx, dx
    mov ax, [es:bx]
    cmp byte [bOdd], 1
    jnz LABEL_EVEN_2
    shr ax, 4
LABEL_EVEN_2:
    and ax, 0FFFh

    pop bx
    pop es
    ret

; 关闭软驱马达
KillMotor:
    push dx
    mov dx, 03F2h
    mov al, 0
    out dx, al

    pop dx
    ret
; KillMotor End


; 数据段
[SECTION .data1]
ALIGN 32
LABEL_DATA:
    ; 实模式下
    _szMemChkTitle      db  "BaseAddrL BaseAddrH LengthLow LengthHigh    Type", 0Ah, 0  ; 内存检查标题
    _szRAMSize          db  "RAM size:", 0
    _szReturn           db  0Ah, 0  ; 换行符
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
    szMemChkTitle       equ BaseOfLoaderPhyAddr + _szMemChkTitle
    szRAMSize           equ BaseOfLoaderPhyAddr + _szRAMSize
    szReturn            equ BaseOfLoaderPhyAddr + _szReturn
    dwMCRNumber         equ BaseOfLoaderPhyAddr + _dwMCRNumber
    dwDispPos           equ BaseOfLoaderPhyAddr + _dwDispPos
    dwMemSize           equ BaseOfLoaderPhyAddr + _dwMemSize
    ARDStruct:          equ BaseOfLoaderPhyAddr + _ARDStruct
        dwBaseAddrLow   equ BaseOfLoaderPhyAddr + _dwBaseAddrLow
        dwBaseAddrHigh  equ BaseOfLoaderPhyAddr + _dwBaseAddrHigh
        dwLengthLow     equ BaseOfLoaderPhyAddr + _dwLengthLow
        dwLengthHigh    equ BaseOfLoaderPhyAddr + _dwLengthHigh
        dwType          equ BaseOfLoaderPhyAddr + _dwType
    MemChkBuf           equ BaseOfLoaderPhyAddr + _MemChkBuf

; 堆栈段位于数据段末尾
StackSpace:
    times 1000h db  0
TopOfStack      equ BaseOfLoaderPhyAddr + $


; 32位保护模式代码段
[SECTION .s32]
ALIGN 32
[BITS 32]
LABEL_PM_START:
    mov ax, SelectorVideo
    mov gs, ax
    mov ax, SelectorFlatRW
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov esp, TopOfStack

    push szMemChkTitle
    call DispStr
    add esp, 4

    call DispMemInfo
    call SetupPaging

    mov ah, 0Fh
    mov al, 'P'
    mov [gs:((80 * 0 + 39) * 2)], ax

    call InitKernel

    ; 正式进入内核
    jmp SelectorFlatC:KernelEntryPointPhyAddr


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
    mov ax, SelectorFlatRW
    mov es, ax
    mov edi, PageDirBase
    xor eax, eax
    mov eax, PageTblBase | PG_P | PG_USU | PG_RWW   ; 使第一个PDE中的页表首地址为PageTblBase,属性为存在的可读可写用户级页表
.1:
    stosd   ; eax -> es:edi, edi = edi + 4
    add eax, 4096
    loop .1

    ; 初始化所有页表PTE
    pop eax             ; 页表个数
    mov ebx, 1024       ; 每个页表1024个PTE
    mul ebx             ; eax * ebx = edx,eax
    mov ecx, eax
    mov edi, PageTblBase
    xor eax, eax
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

; 显示内存信息
DispMemInfo:
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


; 将 KERNEL.BIN 的内容整理对齐后放到新的位置
; 遍历每个 Program Header，将对应段放到内存对应位置
InitKernel:
    xor esi, esi
    xor ecx, ecx
    mov cx, word [BaseOfKernelFilePhyAddr + 2Ch]    ; ecx <- pELFHdr->e_phnum, Program Header Table中的条目数
    mov esi, [BaseOfKernelFilePhyAddr + 1Ch]        ; esi <- pELFHdr->e_phoff, Program Header Table在文件中的偏移量
    add esi, BaseOfKernelFilePhyAddr                ; esi <- Program Header Table在内存中的首地址

.Begin: ; void *MemCpy(void* es:pDest, void* ds:pSrc, int size)
    mov eax, [esi + 0]
    cmp eax, 0                  ; PT_NULL
    jz .NoAction
    push dword [esi + 010h]     ; 段在文件中的长度
    mov eax, [esi + 04h]        ; 段的第一个字节在文件中的偏移
    add eax, BaseOfKernelFilePhyAddr
    push eax
    push dword [esi + 08h]      ; 段的第一个字节在内存中的虚拟地址
    call MemCpy
    add esp, 12

.NoAction:
    add esi, [BaseOfKernelFilePhyAddr + 2Ah]
    dec ecx
    jnz .Begin

    ret
; InitKernel End
%include "lib.inc"
