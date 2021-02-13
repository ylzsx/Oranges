[section .text]

; 导出函数
global memcpy
global memset
global strcpy

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


; char* strcpy(char* p_dst, char* p_src);
strcpy:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push eax

    mov edi, [ebp + 8]  ; p_dst
    mov esi, [ebp + 12] ; p_src

.1:
    mov al, [esi]
    inc esi
    mov byte [edi], al
    inc edi
    cmp al, 0
    jnz .1

    mov eax, [ebp + 8]  ; return

    pop eax
    pop edi
    pop esi
    pop ebp
    ret