; 引导扇区
	org 07c00h

BaseOfStack 			equ	07c00h	; 堆栈基址，从该地址开始向低地址生长
BaseOfLoader 			equ 09000h	; LOADER.BIN 被加载到的段地址
OffsetOfLoader 			equ 0100h	; LOADER.BIN 被加载到的偏移地址
RootDirSectors 			equ 14		; 根目录所占扇区数 = (BPB_RootEntCnt * EntryLen) / BPB_BytsPerSec
SectorNoOfRootDirectory equ 19		; 根目录的开始扇区号
SelectorNoOfFAT1 		equ 1		; FAT1的第一个扇区号 = BPB_RsvdSecCnt
DeltaSelectorNo 		equ 17		; 作用：文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
EntriesPerSector		equ 16		; 每个扇区的目录条目个数 = BPB_BytsPerSec / EntryLen
EntryLen 				equ 32 		; 根目录中每个条目所占字节数
DirEntryFileNameLen 	equ 11 		; 根目录每个条目中文件名长度
MessageLength 			equ 9		; 为方便操作，屏幕显示字符串长度尽量设为9字节

	jmp short LABEL_START
	nop 	; 该nop不可少

	; FAT12 1.44MB软盘的头
	BS_OEMName 		DB 'ForrestY'	; 厂商名, 必须 8 个字节
	BPB_BytsPerSec 	DW 512			; 每扇区字节数
	BPB_SecPerClus	DB 1			; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1			; Boot 记录占用多少扇区（引导扇区）
	BPB_NumFATs		DB 2			; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224			; 根目录文件数最大值
	BPB_TotSec16	DW 2880			; 逻辑扇区总数
	BPB_Media		DB 0xF0			; 媒体描述符
	BPB_FATSz16		DW 9			; 每FAT扇区数
	BPB_SecPerTrk	DW 18			; 每磁道扇区数(1~18)
	BPB_NumHeads	DW 2			; 磁头数(面数)(0~1)[每面80个磁道:0~79]
	BPB_HiddSec		DD 0			; 隐藏扇区数
	BPB_TotSec32	DD 0			; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
	BS_DrvNum		DB 0			; 中断 13 的驱动器号
	BS_Reserved1	DB 0			; 未使用
	BS_BootSig		DB 29h			; 扩展引导标记 (29h)
	BS_VolID		DD 0			; 卷序列号
	BS_VolLab		DB 'OrangeS0.02'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

; 变量
wRootDirSizeForLoop dw RootDirSectors	; 根目录占用扇区数，即查找根目录时，最外层循环次数
wSectorNo 			dw 0				; 要读取的扇区号
bOdd 				db 0				; 读取FAT时，需要分奇偶扇区，0为偶数，1为奇数
; 常量
LoaderFileName 		db "LOADER  BIN", 0	; 11个字节
BootMessage 		db "Booting  " 		; 字符数组0
ReadyMessage		db "Ready.   "		; 字符数组1
NoLoaderMessage		db "No LOADER"		; 字符数组2
	
LABEL_START:
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BaseOfStack

	; 清屏
	mov ax, 0600h
	mov bx, 0700h
	mov cx, 0		; 左上角: (0, 0)
	mov dx, 0184fh	; 右下角: (80, 50)
	int 10h

	mov dh, 0
	call DispStr

	; 软驱复位
	xor ah, ah
	mov dl, [BS_DrvNum]
	int 13h

	; 在A盘根目录寻找 LOADER.BIN
	; 读入根目录中的每一个扇区，以此比较扇区中目录项文件名
	mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp word [wRootDirSizeForLoop], 0
	jz LABEL_NO_LOADERBIN			; 根目录区已经读完
	dec word [wRootDirSizeForLoop]
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader 			; es:bx = BaseOfLoader:OffsetOfLoader
	mov ax, [wSectorNo]
	mov cl, 1
	call ReadSector

	mov si, LoaderFileName
	mov di, OffsetOfLoader
	cld
	mov dx, EntriesPerSector		; 一个扇区的目录条目个数
LABEL_SEARCH_FOR_LOADERBIN:
	cmp dx, 0
	jz LABEL_GOTO_NEXT_SECTION_IN_ROOT_DIR	; 比较完一个扇区的所有条目,未找到则到下一个扇区
	dec dx
	mov cx, DirEntryFileNameLen
LABEL_CMP_FILENAME:
	cmp cx, 0
	jz LABEL_FILENAME_FOUND			; 找到 LoaderFileName
	dec cx
	lodsb 							; al <- ds:si, si = si + 1
	cmp al, byte [es:di]
	jz LABEL_GO_ON
	jmp LABEL_DIFFERENT
LABEL_GO_ON:
	inc di
	jmp LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and di, 0FFE0h 				; 指向本条目的开头
	add di, EntryLen
	mov si, LoaderFileName
	jmp LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTION_IN_ROOT_DIR:
	add word [wSectorNo], 1
	jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov dh, 2
	call DispStr
	jmp $						; 没有找到 LOADER.BIN ，进入死循环

LABEL_FILENAME_FOUND:			; 找到 LOADER.BIN 目录项，根据FAT到数据区加载 LOADER.BIN
	mov ax, RootDirSectors
	and di, 0FFE0h
	add di, 01Ah
	mov cx, word [es:di] 		; cx <- 此条目中包含的文件对应的开始(簇号)扇区号
	push cx
	add cx, ax
	add cx, DeltaSelectorNo 	; cx <- LOADER.BIN的起始扇区号(0-based)
	mov ax, BaseOfLoader
	mov es, ax
	mov bx, OffsetOfLoader
	mov ax, cx

LABEL_GOON_LOADING_FILE:
	push ax
	push bx
	mov ah, 0Eh
	mov al, '.'
	mov bl, 0Fh
	int 10h 			; 在“Booting”后每读一个扇区打印一个'.'
	pop bx
	pop ax

	mov cl, 1
	call ReadSector
	pop ax
	call GetFATEntry
	cmp ax, 0FFFh
	jz LABEL_FILE_LOADED	; 读取结束
	push ax
	mov dx, RootDirSectors
	add ax, dx
	add ax, DeltaSelectorNo
	add bx, [BPB_BytsPerSec]
	jmp LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:
	mov dh, 1
	call DispStr
	jmp BaseOfLoader:OffsetOfLoader 	; 将控制权转交给操作系统的启动项LOADER.BIN


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
	add ax, BootMessage
	mov bp, ax
	mov ax, ds
	mov es, ax		; es:bp 串地址
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
	sub esp, 2	; 空出两个字节的堆栈区保存要读的扇区数：byte [bp-2]

	mov byte [bp-2], cl
	push bx
	mov bl, [BPB_SecPerTrk]
	div bl		; ax / bl = al ... ah
	inc ah
	mov cl, ah	; cl <- 起始扇区号
	and ax, 0FFh
	mov bl, [BPB_NumHeads]
	div bl
	mov ch, al	; ch <- 柱面号
	mov dh, ah 	; dh <- 磁头号
	pop bx
	mov dl, [BS_DrvNum]
.GoOnReading:
	mov ah, 2
	mov al, byte [bp-2]
	int 13h
	jc .GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

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

	mov ax, BaseOfLoader
	sub ax, 0100h		; 在BaseOfLoader前留出4K空间存放FAT
	mov es, ax
	pop ax
	mov byte [bOdd], 0
	mov bx, 3
	mul bx				; dx:ax = ax * bx
	mov bx, 2
	div bx				; dx:ax / bx = ax...dx
	cmp dx, 0
	jz LABEL_EVEN
	mov byte [bOdd], 1
LABEL_EVEN:	; 偶数
	; ax为FATEntry在FAT中的偏移量，计算FATEntry在哪个扇区
	xor dx, dx
	mov bx, [BPB_BytsPerSec]
	div bx				; 0:ax / [BPB_BytsPerSec] = ax...dx
	push dx
	mov bx, 0
	add ax, SelectorNoOfFAT1
	mov cl, 2 			; 因为一个 FATEntry 可能跨越两个扇区,所以一次读两，防止出现错误
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

times 510-($-$$) db 0
dw 0xaa55