%include "sconst.inc"

extern disp_pos

[section .text]

global disp_str
global disp_color_str
global out_byte
global in_byte
global enable_irq
global disable_irq
global enable_int
global disable_int

; void disp_str(char * pszInfo);
; 使用该函数 gs应指向显存
disp_str:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push esi
    push edi

    mov esi, [ebp + 8]  ; pszInfo
    mov edi, [disp_pos] ; edi <- 打印pos
    mov ah, 0Fh
.1:
    lodsb
    test al, al
    jz .2
    cmp al, 0Ah ; 是否回车
    jnz .3
    push eax
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0FFh
    inc eax
    mov bl, 160
    mul bl
    mov edi, eax
    pop eax
    jmp .1
.3:
    mov [gs:edi], ax
    add edi, 2
    jmp .1
.2:
    mov [disp_pos], edi

    pop edi
    pop esi
    pop ebx
    pop eax
    pop ebp
    ret
 
; void disp_color_str(char * info, int color);
disp_color_str:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push esi
    push edi

    mov esi, [ebp + 8]  ; pszInfo
    mov edi, [disp_pos] ; edi <- 打印pos
    mov ah, [ebp + 12]  ; color
.1:
    lodsb
    test al, al
    jz .2
    cmp al, 0Ah ; 是否回车
    jnz .3
    push eax
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0FFh
    inc eax
    mov bl, 160
    mul bl
    mov edi, eax
    pop eax
    jmp .1
.3:
    mov [gs:edi], ax
    add edi, 2
    jmp .1
.2:
    mov [disp_pos], edi

    pop edi
    pop esi
    pop ebx
    pop eax
    pop ebp
    ret



; void out_byte(u16 port, u8 value);
; 写8059A端口
out_byte:
    push ebp
    mov ebp, esp
    push edx

    mov edx, [ebp + 8]  ; port
    mov al, [ebp + 12]   ; value
    out dx, al
    nop                 ; 延迟
    nop

    pop edx
    pop ebp
    ret


; u8 in_byte(u16 port);
; 读8259A端口
in_byte:
    push ebp
    mov ebp, esp
    push edx

    mov edx, [ebp + 8]  ; port
    xor eax, eax
    in al, dx           ; 传出
    nop                 ; 延迟
    nop

    pop edx
    pop ebp
    ret


; void disable_irq(int irq);
; 屏蔽指定外部中断
; Equivalent code:
;   if(irq < 8)
;       out_byte(INT_M_CTLMASK, in_byte(INT_M_CTLMASK) | (1 << irq));
;   else
;       out_byte(INT_S_CTLMASK, in_byte(INT_S_CTLMASK) | (1 << irq));
; 寄存器影响：若在该函数进行了中断屏蔽则将eax置1，否则置0
disable_irq:
    mov ecx, [esp + 4]  ; irq
    pushf               ; 将标志寄存器压栈，以免之后操作会影响标志寄存器
    cli
    mov ah, 1
    rol ah, cl          ; 循环左移，ah = (1 << (irq % 8))
    cmp cl, 8
    jae disable_8
disable_0:
    in al, INT_M_CTLMASK
    test al, ah         ; 做与运算
    jnz dis_already     ; 已经中断屏蔽
    or al, ah
    out INT_M_CTLMASK, al
    popf
    mov eax, 1          ; 若在该函数进行了中断屏蔽则将eax置1，否则置0
    ret
disable_8:
    in al, INT_S_CTLMASK
    test al, ah
    jnz dis_already
    or al, ah
    out INT_S_CTLMASK, al
    popf
    mov eax, 1
    ret
dis_already:
    popf
    xor eax, eax
    ret


; void enable_irq(int irq);
; 使能指定外部中断
; Equivalent code:
;       if(irq < 8)
;               out_byte(INT_M_CTLMASK, in_byte(INT_M_CTLMASK) & ~(1 << irq));
;       else
;               out_byte(INT_S_CTLMASK, in_byte(INT_S_CTLMASK) & ~(1 << irq));
enable_irq:
    mov ecx, [esp + 4]  ; irq
    pushf
    cli
    mov ah, ~1
    rol ah, cl          ; ah = ~(1 << (irq % 8))
    cmp cl, 8
    jae enable_8
enable_0:
    in al, INT_M_CTLMASK
    and al, ah
    out INT_M_CTLMASK, al
    popf
    ret
enable_8:
    in al, INT_S_CTLMASK
    and al, ah
    out INT_S_CTLMASK, al
    popf
    ret


; void enable_int();
; 开中断
enable_int:
    sti
    ret

; void disable_int();
; 关中断
disable_int:
    cli
    ret
