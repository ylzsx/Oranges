[section .data]

disp_pos dd 0

; void disp_str(char * pszInfo);
global disp_str

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
    