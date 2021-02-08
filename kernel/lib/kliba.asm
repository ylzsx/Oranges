extern disp_pos

[section .text]

global disp_str
global disp_color_str
global out_byte
global in_byte

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