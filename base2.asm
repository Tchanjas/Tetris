stack segment para stack ; define the stack segment
db 64 dup('mystack')
stack ends

mydata segment para 'data'
db 64 dup('mystack')
wait_time dw 1
; game matrix 320x200 divived by 20px for each blocks gives us 16x10 but we
; want the last row to have information so it's 16x9 = 144
matrix db 150 dup(0), '$'
matrixindexlength dw 149, '$' ; 143 because it starts at 0
matrixlinelength db 15, '$'

draw dw ?, '$'
drawindex db 0, '$'
drawindexlength dw 0, '$'
drawlinelength db 0, '$'

currentblock_x dw 0, '$'
currentblock_y dw 0, '$'

; declare the matrix pieces
; every piece is 4x2
piecelinefour db 1, 1, 1, 1, 0, 0, 0, 0, '$'
piecelinetwo  db 1, 1, 0, 0, 0, 0, 0, 0, '$'
piecelup      db 1, 0, 0, 0, 1, 1, 1, 0, '$'
pieceldown    db 1, 1, 1, 0, 1, 0, 0, 0, '$'
piecez        db 1, 1, 0, 0, 0, 1, 1, 0, '$'

currentpiece  db ?, '$'
currentpiecex db 0, '$'
currentpiecey db 0, '$'
mydata ends

mycode segment para 'code' ; define the code segment
myproc proc far ; name of the procedure myproc
assume cs:mycode, ds:mydata, ss:stack
	push ds ; store in the stack the segment ds
	xor ax, ax ; guarantee zero in ax
	push ax ; store zero in the stack
	mov ax, mydata
	mov ds, ax

	; ---- graphics mode
	mov ah, 00h ; prepare to define the graphical mode
	mov al, 04h ; graphic mode 320x200 color mode
	int 10h ; 10h interruption

	; ---- background
	mov ah, 11 ; prepare color palette config
	mov bh, 00 ; initialize the background color
	mov bl, 00 ; black background
	int 10h

	; ---- foreground
	mov ah, 11 ; prepare color palette config
	mov bh, 01 ; initialize the foreground color
	mov bl, 06 ; red, black and green
	int 10h

	; change a element in the matrix just so we can test if it works
	;mov bl, 1
	;mov matrix[68], bl

	; ---- draw the elements of background matrix
	mov ax, offset matrix ; get address of matrix 
	mov draw, ax
	mov ax, matrixindexlength ; size of the matrix
	mov drawindexlength, ax
	mov al, matrixlinelength ; size for each line of the matrix
	mov drawlinelength, al
	call drawmatrix

	; ---- draw the elements of a piece matrix
	;mov currentpiecex, 5
	;mov currentpiecey, 5

	call randompiece
	mov draw, ax
	mov drawindexlength, 7
	mov drawlinelength, 4
	call drawmatrix

	; ---- waits for a key to end it
	mov ah, 01
	int 21h

	; ---- back to de text mode
	mov ah, 00h ; define the graphic mode
	mov al, 02h ; text mode 80x25
	int 10h

	ret ; return the control to dos
myproc endp ; end of the procedure myproc

; ---- procedure to draw the elements of the a specified matrix
drawmatrix proc near
	xor si, si
matrix_loop:
	; get coordinates
	; get width and height based on the index
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx

	mov al, drawindex
	mov bl, drawlinelength
	div bl ; bx bl
	mov cl, ah ; width
	mov dl, al ; height

	; multiply to get the real coordinates
	mov ax, dx
	mov bx, 10
	mul bx
	mov currentblock_y, ax
	mov ax, cx
	mul bx
	mov currentblock_x, ax

	; print block
	mov di, draw
	add di, si
	mov bl, [di]
	cmp bl, 1
	jne matrix_loop_updateindex
	call printblock

	; update index
matrix_loop_updateindex:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	mov al, drawindex
	inc al
	mov drawindex, al
	inc si

	; check if finished
	mov bx, drawindexlength
	cmp ax, bx
	jle matrix_loop

	mov drawindex, 0
	mov drawindexlength, 0
	mov drawlinelength, 0
	ret
drawmatrix endp

; ---- procedure that draws a defined block of width and height in specific coordinates
printblock proc near
	; ---- display pixels
	add currentblock_y, 10
	mov dx, currentblock_y
	sub dx, 10

	add currentblock_x, 10
	mov cx, currentblock_x
	sub cx, 10

	mov al, 03 ; green
	mov ah, 12 ; config int10h to the pixel plot

	; ---- start drawing block
drawColumn:
	int 10h
	inc cx
	cmp cx, currentblock_x
	jb drawColumn

	sub cx, 10 ; starting x coordinate of current block
	inc dx ; new line
	cmp dx, currentblock_y
	jb drawColumn
	ret  
printblock endp

; --- selects a piece at random using system clock ticks
randompiece proc near
	push bx
	push cx
	push dx
	; --- system time cx:dx
	mov ah, 00h
	int 1ah
	mov ax, dx
	xor dx, dx
	mov cx, 5 
	div cx

	cmp dx, 0
	je loadlinefour
	cmp dx, 1
	je loadlinetwo
	cmp dx, 2
	je loadlup
	cmp dx, 3
	je loadldown
	cmp dx, 4
	je loadz

loadlinefour:
	lea ax, piecelinefour
	jmp exit
loadlinetwo:
	lea ax, piecelinetwo
	jmp exit
loadlup:
	lea ax, piecelup
	jmp exit
loadldown:
	lea ax, pieceldown
	jmp exit
loadz:
	lea ax, piecez
	jmp exit

exit:
	pop dx
	pop cx
	pop bx
	ret
randompiece endp

delay proc near
	push dx
	push cx
	timer:
	mov ah, 00h
	int 1ah
	cmp dx,wait_time
	jb timer
	add dx,3         ;1-18, where smaller is faster and 18 is close to 1 second
	mov wait_time,dx
	pop cx
	pop dx
	ret
delay endp

mycode ends ; end of the code segment
end ; end of the program
