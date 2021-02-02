; 显示AL中的字符
; 参数：AL
DispAL:
    push ecx
    push edx
    push edi
    push eax

    mov edi, [dwDispPos]
    mov ah, 0Ch     ; 黑底 红字
    mov dl, al
    shr al, 4
    mov ecx, 2
.begin:
    and al, 0Fh
    cmp al, 9
    ja .1
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

    mov [dwDispPos], edi

    pop eax
    pop edi
    pop edx
    pop ecx
    ret
; DispAL End


; 显示一个整形数
; 参数：堆栈ss:esp为显示字符串的首地址
DispInt:
    push ebp
    mov ebp, esp
    push eax
    push edi

    mov eax, [ebp + 8]
    shr eax, 24
    call DispAL

    mov eax, [ebp + 8]
    shr eax, 16
    call DispAL

    mov eax, [ebp + 8]
    shr eax, 8
    call DispAL

    mov eax, [ebp + 8]
    call DispAL

    mov ah, 0Fh     ; 黑底 白字
    mov al, 'h'
    mov edi, [dwDispPos]
    mov [gs:edi], ax
    add edi, 2
    mov [dwDispPos], edi

    pop edi
    pop eax
    pop ebp
    ret
; DispInt End


; 显示一个空格
DispSpace:
    push edi

    mov edi, [dwDispPos]
    add edi, 2
    mov [dwDispPos], edi

    pop edi
    ret
; DispSpace End


; 显示一个字符串
; 参数：堆栈ds:esp为显示字符串的首地址
DispStr:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, [ebp + 8]  ; 要显示字符串的首地址。esp: ebp, 返回地址，参数
    mov edi, [dwDispPos]
    mov ah, 0Ch
.1:
    lodsb       ; ds:esi的一个字节 -> al, esi = esi + 1
    test al, al ; 字符串是否结束
    jz .2
    cmp al, 0Ah ; 是否为回车
    jnz .3
    push eax    ; if (al == 0Ah)
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
    mov [dwDispPos], edi

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
; DispStr End



; 打印一个回车
DispReturn:
    push szReturn
    call DispStr
    add esp, 4
    
    ret
; DispReturn End


; 内存拷贝
; 参数：堆栈传参 void *MemCpy(void* es:pDest, void* ds:pSrc, int size)
; 返回值：返回目的地址，eax
MemCpy:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx

    mov edi, [ebp + 8]  ; pDest
    mov esi, [ebp + 12] ; pSrc
    mov ecx, [ebp + 16] ; size
.1:
    cmp ecx, 0
    jz .2
    mov al, [ds:esi]
    inc esi
    mov byte [es:edi], al
    inc edi
    dec ecx
    jmp .1
.2:
    mov eax, [ebp + 8]  ; 返回值

    pop ecx
    pop edi
    pop esi
    pop ebp
    ret
;MemCpy End