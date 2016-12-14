STACK SEGMENT PARA STACK ; define the stack segment
  DB 64 DUP('MYSTACK')
STACK ENDS

MYDATA SEGMENT PARA 'DATA'
  DB 64 DUP('MYSTACK')
  WAIT_TIME DW 1
  matrix DB 150 DUP(0), '$' ; game matrix
MYDATA ENDS

MYCODE SEGMENT PARA 'CODE' ; define the code segment
MYPROC PROC FAR ; name of the procedure MYPROC
  ASSUME CS:MYCODE, DS:MYDATA, SS:STACK
  PUSH DS ; store in the stack the segment DS
  XOR AX, AX ; guarantee zero in AX
  PUSH AX ; store zero in the stack
  MOV AX, MYDATA
  MOV DS, AX

  ; ---- graphics mode
  MOV AH, 00h ; prepare to define the graphical mode
  MOV AL, 04h ; graphic mode 320x200 color mode
  INT 10h ; 10h interruption

  ; ---- background
  mov ah, 11 ; prepare color palette config
  mov bh, 00 ; initialize the background color
  mov bl, 07 ; light grey background
  int 10h

  ; ---- foreground
  mov ah, 11 ; prepare color palette config
  mov bh, 01 ; initialize the foreground color
  mov bl, 06 ; red, black and green
  int 10h

  ; ---- show the pixel
  mov al, 02 ; black
  mov ah, 12 ; config int10h to the pixel plot
  mov dx, 64h ; line 100
  mov cx, 9Eh ; column 158
  int 10h

  ; ---- move the pixel up
  call moveUP

  ; ---- waits for a key to end it
  MOV AH, 01
  INT 21h

  ; ---- back to de text mode
  MOV AH, 00h ; define the graphic mode
  MOV AL, 02h ; text mode 80x25
  INT 10h

  RET ; return the control to DOS
MYPROC ENDP ; end of the procedure MYPROC

moveUP PROC NEAR
  moveUP_loop:
    ; ---- clean the previous pixel
    mov al, 04 ; same color as the background
    mov ah, 12 ; config int10h to the pixel plot
    int 10h

    ; ---- decrease the y coordinate and show the pixel
    mov al, 02 ; black
    mov ah, 12 ; config int10h to the pixel plot
    dec dx ; decrease the y coordinate (y = line)
    int 10h
    CALL DELAY ; delay so we can see it moving
    cmp dx, 1
    jge moveUP_loop
  moveUP_sair:
    RET
moveUP ENDP

DELAY PROC
  push ax
  push dx
  push cx

  TIMER:
    MOV     AH, 00H
    INT     1AH
    CMP     DX,WAIT_TIME
    JB      TIMER
    ADD     DX,3         ;1-18, where smaller is faster and 18 is close to 1 second
    MOV     WAIT_TIME,DX

  pop cx
  pop dx
  pop ax
RET
DELAY ENDP

MYCODE ENDS ; end of the code segment
END ; end of the program
