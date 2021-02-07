     1                                  
     2                                  SELECTOR_KERNEL_CS equ 8
     3                                  
     4                                  extern cstart
     5                                  extern gdt_ptr
     6                                  
     7                                  [section .bss]
     8 00000000 <res 00000800>          StackSpace resb 2 * 1024
     9                                  StackTop:
    10                                  
    11                                  
    12                                  
    13                                  [section .text]     ; 代码段
    14                                  
    15                                  global _start
    16                                  
    17                                  _start:
    18                                      ; 切换堆栈
    19 00000000 66BC[00080000]              mov esp, StackTop
    20                                  
    21                                      ; 切换GDT
    22 00000006 0F0106[0000]                sgdt [gdt_ptr]
    22          ******************       error: binary output format does not support external references
    23 0000000B E8(0000)                    call cstart
    23          ******************       error: binary output format does not support external references
    24 0000000E 0F0116[0000]                lgdt [gdt_ptr]
    24          ******************       error: binary output format does not support external references
    25                                  
    26 00000013 EA[1800]0800                jmp SELECTOR_KERNEL_CS:csinit
    27                                  
    28                                  csinit:
    29 00000018 6A00                        push 0
    30 0000001A 669D                        popfd   ; Pop top of stack into EFLAGS
    31 0000001C F4                          hlt
