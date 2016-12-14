STACK SEGMENT PARA STACK ; define the stack segment
  DB 64 DUP('MYSTACK')
STACK ENDS

MYDATA SEGMENT PARA 'DATA'
  DB 64 DUP('MYSTACK')
  WAIT_TIME DW 1
  ; game matrix 320x200 divived by 20px for each blocks gives us 16x10 but we
  ; want the last row to have information so it's 16x9 = 144
  matrix DB 144 DUP(0), '$'
  matrixSize DW 143, '$' ; 143 because it starts at 0
  matrixIndex DB 0, '$'
  ; declare the pieces
  ; every piece is 4x2
  pieceLineFour DB 0, 0, 0, 0, 1, 1, 1, 1, '$'
  pieceLineTwo  DB 0, 0, 0, 0, 0, 1, 1, 0, '$'
  pieceLUp      DB 1, 0, 0, 0, 1, 1, 1, 0, '$'
  pieceLDown    DB 1, 1, 1, 0, 1, 0, 0, 0, '$'
  pieceZ        DB 1, 1, 0, 0, 0, 1, 1, 0, '$'
  CurrentBlock_X DW 0, '$'
  CurrentBlock_Y DW 0, '$'
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
  MOV AH, 11 ; prepare color palette config
  MOV BH, 00 ; initialize the background color
  MOV BL, 07 ; light grey background
  INT 10h

  ; ---- foreground
  MOV AH, 11 ; prepare color palette config
  MOV BH, 01 ; initialize the foreground color
  MOV BL, 06 ; red, black and green
  INT 10h

  ; change a element in the matrix just so we can test if it works
  MOV BL, 1
  MOV matrix[68], BL

  ; ---- print the elements of matrix
  CALL printMatrix

  ; ---- waits for a key to end it
  MOV AH, 01
  INT 21h

  ; ---- back to de text mode
  MOV AH, 00h ; define the graphic mode
  MOV AL, 02h ; text mode 80x25
  INT 10h

  RET ; return the control to DOS
MYPROC ENDP ; end of the procedure MYPROC

; ---- procedure to print all elements of the matrix
printMatrix PROC NEAR
  matrix_loop:
  ; get coordinates
  ; get width and height based on the index
  xor ax, ax
  xor bx, bx
  xor cx, cx
  xor dx, dx

  mov al, matrixIndex
  mov bl, 16
  div bl ; bx bl
  mov cl, ah ; width
  mov dl, al ; height

  ; multiply to get the real coordinates
  mov ax, dx
  mov bx, 20
  mul bx
  mov CurrentBlock_Y, ax
  mov ax, cx
  mul bx
  mov CurrentBlock_X, ax

  ; print block
  mov bl, matrix[SI]
  cmp bl, 0
  je matrix_loop_UpdateIndex
  call printBlock

  ; update index
  matrix_loop_UpdateIndex: xor ax, ax
  xor bx, bx
  xor cx, cx
  xor dx, dx
  mov al, matrixIndex
  inc al
  mov matrixIndex, al
  inc SI

  ; check if finished
  mov bx, matrixSize
  cmp ax, bx
  jle matrix_loop

  RET
printMatrix ENDP

; ---- procedure that prints a defined block of width and height
printBlock PROC NEAR
; ---- display pixels
mov dx, CurrentBlock_Y
add dx, 20
mov CurrentBlock_Y, dx
sub dx, 20

mov cx, CurrentBlock_X
add cx, 20
mov CurrentBlock_X, cx
sub cx, 20

printBlock_loop_y:
  printBlock_loop_x:
    mov al, 02 ; black
    mov ah, 12 ; config int10h to the pixel plot
    int 10h
    inc cx
    mov bx, CurrentBlock_X
    cmp cx, bx
    jle printBlock_loop_x
  inc dx
  xor cx, cx
  mov cx, CurrentBlock_X
  sub cx, 20
  mov bx, CurrentBlock_Y
  cmp dx, bx
  jle printBlock_loop_y

  RET
printBlock ENDP

MYCODE ENDS ; end of the code segment
END ; end of the program
