;x86_64, NASM-style assembly
;MS calling convention

%include "include.asm"

global init
global draw

extern glutInitDisplayMode
extern glutInitWindowSize
extern glutPostRedisplay
extern glutCreateWindow
extern glutDisplayFunc
extern glutMainLoop
extern glTranslatef
extern glVertex2f
extern glColor3f
extern glScalef
extern glFlush
extern glClear
extern glBegin
extern glEnd
extern Sleep

extern gameLoop

extern WTarraySeek
extern worldTiles
extern snakeLength
extern pointPos

section .rdata
winName:    db 'SnakeASM', 0

FPinverseTileSize:  dd 0.125    ; 2 / worldX   ;2 is the width of OpenGL screen (-1, 1)
FPpointMargin:      dd 0.025    ; ((1 - pointSizeConstant) / 2) * FPinverseTileSize
FPtwo:  dd  2.0
FPone:  dd  1.0
FPzero: dd  0.0

section .text
init:
    push rbp
    mov rbp, rsp
    and sp, 1111_1111_1111_0000b  ;align stack to 16-bit - seems to help glut

    xor ecx, ecx
    call glutInitDisplayMode
    mov ecx, 600    ;width
    mov edx, 600    ;height
    call glutInitWindowSize
    mov rcx, winName
    call glutCreateWindow
    mov rcx, draw
    call glutDisplayFunc
    call glutMainLoop

    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret

draw:
    push rbx
    push rbp

    call gameLoop

    mov ecx, 0x4000
    call glClear

    movss xmm0, [FPone] ;{
    movss xmm1, xmm0    ;white
    movss xmm2, xmm0    ;}
    call glColor3f

    mov ebx, [snakeLength]
    mov ebp, [WTarraySeek]
drawLoop:
    test ebp, ebp
    jnz short DLnoWrap
    mov ebp, worldArea - 1
DLnoWrap:
    mov ecx, [worldTiles + rbp * 4]
    call drawTile
    dec ebp
    dec ebx
    test ebx, ebx
    jnz short drawLoop

    pop rbp
    pop rbx

    movss xmm0, [FPone] ;{
    movss xmm1, [FPzero];red
    movss xmm2, xmm1    ;}
    call glColor3f
    mov ecx, [pointPos]
    call drawPoint

    call glFlush
    mov ecx, sleepTime
    call Sleep
	call glutPostRedisplay
    ret

drawPoint:
    sub rsp, 0x10
    push rcx
    mov ecx, 9
    call glBegin
    pop rcx
    call gameToScreen

    movss xmm2, xmm0    ;unpack two floats from xmm0
    psrlq xmm0, 0x20    ;shift right
    movss xmm1, xmm0
    movss xmm0, xmm2
    movss [rsp], xmm0 ;store converted coordinates for later
    movss [rsp + 4], xmm1

    movss xmm2, [FPpointMargin]
    addss xmm0, xmm2
    addss xmm1, xmm2
    call glVertex2f     ;bottom left corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    movss xmm2, [FPpointMargin]
    addss xmm0, [FPinverseTileSize]
    addss xmm1, xmm2
    subss xmm0, xmm2
    call glVertex2f     ;bottom right corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    movss xmm2, [FPpointMargin]
    movss xmm3, [FPinverseTileSize]
    addss xmm0, xmm3
    addss xmm1, xmm3
    subss xmm0, xmm2
    subss xmm1, xmm2
    call glVertex2f     ;top right corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    movss xmm2, [FPpointMargin]
    addss xmm1, [FPinverseTileSize]
    addss xmm0, xmm2
    subss xmm1, xmm2
    call glVertex2f     ;top left corner

    call glEnd
    add rsp, 0x10
    ret

drawTile:   ;void (int)
    sub rsp, 0x10
    push rcx
    mov ecx, 9
    call glBegin
    pop rcx
    call gameToScreen

    movss xmm2, xmm0    ;unpack two floats from xmm0
    psrlq xmm0, 0x20    ;shift right
    movss xmm1, xmm0
    movss xmm0, xmm2
    movss [rsp], xmm0 ;store converted coordinates for later
    movss [rsp + 4], xmm1
    call glVertex2f     ;bottom left corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    addss xmm0, [FPinverseTileSize]
    call glVertex2f     ;bottom right corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    movss xmm2, [FPinverseTileSize]
    addss xmm0, xmm2
    addss xmm1, xmm2
    call glVertex2f     ;top right corner

    movss xmm0, [rsp]
    movss xmm1, [rsp + 4]
    addss xmm1, [FPinverseTileSize]
    call glVertex2f     ;top left corner

    call glEnd
    add rsp, 0x10
    ret

gameToScreen:   ;double (int)
    sub rsp, 0x30

    movzx rax, cx   ;{spread packed word coordinates to whole 64 bits of rax
    shr ecx, 0x10   ;
    shl rcx, 0x20   ;
    or rax, rcx     ;}

    mov [rsp + 0x20], rax
    cvtpi2ps xmm0, [rsp + 0x20] ;convert two packed dword integers to two packed floats

    lea rax, [rsp + 0x20]
    and al, 1111_0000b      ;allign stack address to 16 bytes

    mov ecx, [FPinverseTileSize]
    mov edx, ecx
    shl rcx, 0x20
    or rcx, rdx

    mov [rax], rcx
    movaps xmm1, [rax]

    mov ecx, [FPone]    ;{loading 1f
    mov edx, ecx        ;
    shl rcx, 0x20       ;
    or rcx, rdx         ;

    mov [rax], rcx      ;
    movaps xmm2, [rax]  ;}

    mulps xmm0, xmm1    ;coordinates * tileSize
    subps xmm0, xmm2    ;shift result to OpenGL coordinate space (-1, 1)

    add rsp, 0x30
    ret
