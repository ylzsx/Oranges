BaseOfLoader            equ 09000h                  ; LOADER.BIN 被加载到的段地址
OffsetOfLoader          equ 0100h                   ; LOADER.BIN 被加载到的偏移地址
BaseOfLoaderPhyAddr     equ BaseOfLoader * 10h      ; LOADER.BIN 加载到的物理地址

BaseOfKernelFile        equ 08000h                  ; KERNEL.BIN 被加载到的段地址
OffsetOfKernelFile      equ 0h                      ; KERNEL.BIN 被加载到的偏移地址
BaseOfKernelFilePhyAddr equ BaseOfKernelFile * 10h  ; KERNEL.BIN 加载到的物理地址
KernelEntryPointPhyAddr equ 030400h                 ; 必须与 MAKEFILE 中参数 -Ttext 的值相同

PageDirBase             equ 200000h                 ; 页目录开始地址， 2M
PageTblBase             equ 201000h                 ; 页表开始地址, 2M + 4K