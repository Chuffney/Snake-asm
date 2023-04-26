;x86_64, NASM-style assembly
;uses Windows API (user32.dll)
;MS calling convention

global isTurn

extern GetAsyncKeyState ;short GetAsyncKeyState(int vkey)

;compile-time constants
up:     equ 0
right:  equ 1
down:   equ 2
left:   equ 3

%define arrow(dir) (((dir + 1) % 4) + 0x25) ;virtual key codes defined in WinAPI

section .bss
keyAlreadyPressed:  resb 4

section .text

;if no key is pressed returns special value (100b)
absoluteDirection:  ;char (void)
    push rbx
    push rsi    ;newly pressed
    push r12
    xor ebx, ebx
    xor esi, esi
    mov r12d, [keyAlreadyPressed]

    mov ecx, arrow(up)
    call GetAsyncKeyState
    test al, al
    jz short AD_notUp   ;key in not pressed
    test r12b, r12b
    jnz short AD_checkRight  ;key was already pressed
    xor bl, 1           ;else toggle up/down counter
    mov r12b, 1         ;set up to pressed
    mov sil, 1          ;up newly pressed to true
    jmp short AD_checkRight
AD_notUp:
    xor r12b, r12b  ;reset up
AD_checkRight:
    ror r12d, 8
    rol esi, 16

    mov ecx, arrow(right)
    call GetAsyncKeyState
    test al, al
    jz short AD_notRight
    test r12b, r12b
    jnz short AD_checkDown
    xor bl, 10b
    mov r12b, 1
    mov sil, 1
    jmp short AD_checkDown
AD_notRight:
    xor r12b, r12b  ;reset right
AD_checkDown:
    ror r12d, 8
    rol esi, 8

    mov ecx, arrow(down)
    call GetAsyncKeyState
    test al, al
    jz short AD_notDown
    test r12b, r12b
    jnz short AD_checkLeft
    xor bl, 1     ;toggle once more if up was pressed as well in this tick
    mov r12b, 1
    mov sil, 1
    jmp short AD_checkLeft
AD_notDown:
    xor r12b, r12b  ;reset down
AD_checkLeft:
    ror r12d, 8
    rol esi, 16

    mov ecx, arrow(left)
    call GetAsyncKeyState
    test al, al
    jz short AD_notLeft
    test r12b, r12b
    jnz short AD_collect
    xor bl, 10b
    mov r12b, 1
    mov sil, 1
    jmp short AD_collect
AD_notLeft:
    xor r12b, r12b  ;reset left

AD_collect:
    ror r12d, 8
    rol esi, 8
    mov [keyAlreadyPressed], r12d
    mov al, 100b    ;special value for the case below
    test bl, bl     ;check if any key was pressed / two keys were pressed at once
    jp short AD_ret

    test bl, bl
    jz short AD_horizontal
    xor al, al  ;mov al, up
    test sil, sil
    jnz short AD_ret
    mov al, down
    jmp short AD_ret
AD_horizontal:
    shr esi, 16
    mov al, right
    test sil, sil
    jnz short AD_ret
    mov al, left
    ;jmp short AD_ret

AD_ret:
    pop r12
    pop rsi
    pop rbx
    ret


direction:
    sub rsp, 0x20

    mov ecx, arrow(up)
    call GetAsyncKeyState
    test ax, ax
    jz short DIR_notUp
    mov al, up
    jmp short DIR_ret
DIR_notUp:
    mov ecx, arrow(right)
    call GetAsyncKeyState
    test ax, ax
    jz short DIR_notRight
    mov al, right
    jmp short DIR_ret
DIR_notRight:
    mov ecx, arrow(down)
    call GetAsyncKeyState
    test ax, ax
    jz short DIR_notDown
    mov al, down
    jmp short DIR_ret
DIR_notDown:
    mov ecx, arrow(left)
    call GetAsyncKeyState
    test ax, ax
    jz short DIR_notLeft
    mov al, left
    jmp short DIR_ret
DIR_notLeft:
    mov al, 100b    ;special case (no keys pressed)
DIR_ret:
    add rsp, 0x20
    ret

;if this function returns zero it means there is no turn
;otherwise the two low bits indicate new heading
isTurn:     ;char (char currentHeading)
    and cl, 11b     ;cl % 4
    push rcx
    call direction
    pop rcx
    test al, 100b   ;check for special case in absoluteDirection
    jnz short ret_false
    sub cl, al  ;current heading - input heading
    test cl, 1
    jz short ret_false
    or al, 1000b
    ret

ret_true:
    mov eax, 1
    ret

ret_false:
    xor eax, eax
    ret