[section .text]

; void* memcpy(void* es:pDest, void* ds:pSrc, int iSize);
global memcpy

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