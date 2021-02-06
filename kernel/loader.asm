; loader
    org 0100h

BaseOfStack         equ 0100h   ; 堆栈基址，从该地址开始向低地址生长
BaseOfKernelFile    equ 08000h  ; KERNEL.BIN 被加载到的段地址
OffsetOfKernelFile  equ 0h      ; KERNEL.BIN 被加载到的偏移地址
MessageLength       equ 9       ; 为方便操作，屏幕显示字符串长度尽量设为9字节

    jmp LABEL_BEGIN

%include "fat12hdr.inc"

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
    call DispStr

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
    call DispStr
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
    call DispStr
    jmp BaseOfKernelFile:OffsetOfKernelFile     ; 将控制权转交给操作系统的启动项KERNEL.BIN




; 打印字符串
; 传入参数：dh: 打印数组序号
DispStr:
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
; DispStr End


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