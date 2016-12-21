stack segment para stack ; define the stack segment
db 64 dup('mystack')
stack ends

mydata segment para 'data'
db 64 dup('mystack')
wait_time dw 1

; game matrix is 10 columns and 15 lines
; that gives us 150 blocks with 10 pixels of width and height for each block
matrix db 150 dup(0), '$'
matrix_x_length dw 10, '$' ; width
matrix_y_length dw 15, '$' ; height
matrix_x dw 0, '$' ; x coordinate
matrix_y dw 0, '$' ; y coordinate

; declare the matrix pieces
; every piece is 4x2
piecelinefour db 1, 1, 1, 1, 0, 0, 0, 0, '$'
piecelinetwo  db 1, 1, 0, 0, 0, 0, 0, 0, '$'
piecelup      db 1, 0, 0, 0, 1, 1, 1, 0, '$'
pieceldown    db 1, 1, 1, 0, 1, 0, 0, 0, '$'
piecez        db 1, 1, 0, 0, 0, 1, 1, 0, '$'
; declare piece coordinates and lengths
piece_x_length  dw 4, '$' ; width
piece_y_length  dw 2, '$' ; height
piece_x dw 5, '$' ; x coordinate
piece_y dw 5, '$' ; y coordinate

; declare our variables for the generic draw procedure
draw_address dw ?, '$'
draw_x_length dw 0, '$'
draw_y_length dw 0, '$'
draw_x dw 0, '$'
draw_y dw 0, '$'
draw_block_x dw 0, '$'
draw_block_y dw 0, '$'

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

	; ---- draw the game matrix
	mov ax, offset matrix ; address of the matrix
	mov draw_address, ax
	mov ax, matrix_x ; x coordinate
	mov draw_x, ax
	mov ax, matrix_y ; y coordinate
	mov draw_y, ax
	mov ax, matrix_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, matrix_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	; ---- draw a random piece
	call randompiece
	mov draw_address, ax
	mov ax, piece_x ; x coordinate
	mov draw_x, ax
	mov ax, piece_x ; y coordinate
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	; ---- waits for a key to end it
	mov ah, 01
	int 21h

	; ---- back to de text mode
	mov ah, 00h ; define the graphic mode
	mov al, 02h ; text mode 80x25
	int 10h

	ret ; return the control to dos
myproc endp ; end of the procedure myproc

; ---- generic procedure to draw a specified matrix object
draw proc near
	xor si, si
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx

	; get the real coordinates and put the length on the current coordinates
	mov bx, 10
	; x and width
	mov cx, draw_x ; get the real x coordinate
	mov ax, cx
	mul bx
	mov draw_block_x, ax
	mov draw_x, ax
	mov ax, draw_x_length ; get the real width
	mul bx
	add ax, draw_x
	mov draw_x_length, ax
	; y and height
	mov cx, draw_y ; get the real x coordinate
	mov ax, cx
	mul bx
	mov draw_block_y, ax
	mov draw_y, ax
	mov ax, draw_y_length ; get the real height
	mul bx
	add ax, draw_y
	mov draw_y_length, ax

; draw block
draw_loop:
	mov di, draw_address
	add di, si
	mov bl, [di]
	cmp bl, 1
	jne draw_update
	call printblock

; update index
draw_update:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	; increment x
	mov ax, draw_block_x
	add ax, 10
	mov draw_block_x, ax
	inc si
	; check if x is out of bounds
	cmp ax, draw_x_length
	jl draw_continue
	; moves the x to the initial position
	; and increments the y
	mov cx, draw_x
	mov draw_block_x, cx
	mov bx, draw_block_y
	add bx, 10
	mov draw_block_y, bx

; check if y is out of bounds
; if true then end the procedure
draw_continue:
	xor ax, ax
	xor bx, bx
	mov ax, draw_block_y
	mov bx, draw_y_length
	cmp ax, bx
	jl draw_loop
	ret
draw endp

; ---- procedure that draws a block of 10 pixels width and height in specific coordinates
printblock proc near
	; get the limit of width and height
	mov dx, draw_block_y
	add draw_block_y, 10

	mov cx, draw_block_x
	add draw_block_x, 10

	mov al, 03 ; green
	mov ah, 12 ; config int10h to the pixel plot

; draw each pixel
drawColumn:
	int 10h
	inc cx
	cmp cx, draw_block_x
	jb drawColumn

	sub cx, 10 ; starting x coordinate of current block
	inc dx ; new line
	cmp dx, draw_block_y
	jb drawColumn

	sub draw_block_x, 10
	sub draw_block_y, 10
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

; --- delay procedure
delay proc near
	push dx
	push cx
	
timer:
	mov ah, 00h
	int 1ah
	cmp dx, wait_time
	jb timer
	add dx, 3 ; 1-18, where smaller is faster and 18 is close to 1 second
	mov wait_time,dx
	
	pop cx
	pop dx
	ret
delay endp

mycode ends ; end of the code segment
end ; end of the program
