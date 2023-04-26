;x86_64, NASM-style assembly
;MS calling convention

global gameLoop
global main

global WTarraySeek
global worldTiles
global snakeLength
global pointPos

extern isTurn

%include "include.asm"

section .bss
headPos:
headPosX:       resw    1
headPosY:       resw    1
pointPos:
pointPosX:      resw    1
pointPosY:      resw    1
heading:        resd    1
WTarraySeek:    resd    1
worldTiles:     resd    worldArea

section .data
snakeLength:    dd  3

section .text

checkBoundaries:    ;bool (void)
    mov eax, [headPos] ;both posX and posY in here
    cmp ax, worldX
    ja short CB_outside
    test ax, ax
    js short CB_outside

    shr eax, 0x10
    cmp ax, worldY
    ja short CB_outside
    test ax, ax
    js short CB_outside

    xor al, al
    ret
CB_outside:
    mov al, 1
    ret


;returns true if a collision occured
moveFore:   ;bool (void)
    mov al, [heading]
    and al, 11b         ;al = heading % 4
    test al, al
    jz short MF_up      ;switch (heading) {
    cmp al, 2
    ja short MF_left
    je short MF_down
    jmp short MF_right  ;}

MF_up:
    inc dword [headPosY]
    jmp short MF_collect
MF_right:
    inc dword [headPosX]
    jmp short MF_collect
MF_down:
    dec dword [headPosY]
    jmp short MF_collect
MF_left:
    dec dword [headPosX]
MF_collect:
    mov eax, [WTarraySeek]
    inc eax
    cmp eax, worldArea
    jne short MF_continue
    xor eax, eax
MF_continue:
    mov [WTarraySeek], eax
    mov ecx, [headPos]
    mov [worldTiles + rax * 4], ecx
    ;jmp checkCollision  ;equivalent of calling and then immediately returning
    ;ret

;checks whether the given position is within the snake (true) or not (false)
checkCollision:  ;bool (int pos)
    mov eax, [WTarraySeek]
    mov edx, [snakeLength]
    jmp short CC_checkWrap
    CC_loop:
        cmp [worldTiles + rax * 4], ecx
        je ret_true
        CC_checkWrap:
        dec eax
        jnc short CC_noWrap
        mov eax, worldArea - 1
    CC_noWrap:
        dec edx
        jnz short CC_loop

    xor al, al
    ret


placePoint:     ;void (int pos)
    rdrand ecx  ;put 32-bit random integer into ecx
    jnc short placePoint

    and cx, worldX - 1
    rol ecx, 16
    and cx, worldY - 1
    rol ecx, 16

    call checkCollision     ;random positon still in ecx
    jnz short placePoint
    ret

ret_true:
    mov al, 1
    ret

gameOver:
    ret

gameLoop:   ;void (void)
    mov ecx, [heading]
    call isTurn
    test al, al
    jz short GL_noTurn
    mov [heading], al
GL_noTurn:
    call moveFore
    test al, al
    jnz gameOver
    call checkBoundaries
    test al, al
    jnz gameOver

    mov edx, [headPos]
    cmp edx, [pointPos]
    jne short ret_true
    inc dword [snakeLength]
    ret
