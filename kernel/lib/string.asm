[section .text]

; 导出函数
global memcpy
global memset

; void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);
memcpy:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx

    mov edi, [ebp + 8]  ; pDest
    mov esi, [ebp + 12] ; pSrc
    mov ecx, [ebp + 16] ; iSize
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
    mov eax, [ebp + 8]  ; 返回地址

    pop ecx
    pop edi
    pop esi
    pop ebp
    ret


; void memset(void* p_dst, char ch, int size);
memset:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ecx

    mov edi, [ebp + 8]  ; p_dest
    mov edx, [ebp + 12] ; ch
    mov ecx, [ebp + 16] ; size
.1:
    cmp ecx, 0
    jz .2
    mov byte [edi], dl
    inc edi
    dec ecx
    jmp .1
.2:

    pop ecx
    pop edi
    pop esi
    pop ebp
    ret