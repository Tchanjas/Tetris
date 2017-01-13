stack segment para stack ; define the stack segment
db 64 dup('mystack')
stack ends

mydata segment para 'data'
db 64 dup('mystack')
wait_time dw 1

msg_title db 'up_tetris', '$'
msg_lines_txt db 'lines eliminated: ', '$'
msg_lines_num db 0, '$'
msg_min_txt db 'minutes: ', '$'
msg_min_num db 0, '$'
msg_sec_txt db 'seconds: ', '$'
msg_sec_num db 0, '$'
msg_paused db 'paused', '$'
msg_clear db '      ', '$'

; game matrix is 10 columns and 15 lines
; that gives us 150 blocks with 10 pixels of width and height for each block
matrix db 150 dup(0), '$'
matrix_x_length dw 10, '$' ; width
matrix_y_length dw 15, '$' ; height
matrix_x dw 10, '$' ; x coordinate
matrix_y dw 10, '$' ; y coordinate

; declare the matrix pieces
; every piece is 4x2
piecelinefour db 1, 1, 1, 1, 0, 0, 0, 0, '$'
piecelinetwo  db 1, 1, 0, 0, 0, 0, 0, 0, '$'
piecelup      db 1, 0, 0, 0, 1, 1, 1, 0, '$'
pieceldown    db 1, 1, 1, 0, 1, 0, 0, 0, '$'
piecez        db 1, 1, 0, 0, 0, 1, 1, 0, '$'
erase					db 0, 0, 0, 0, 0, 0, 0, 0, '$'
; declare piece coordinates and lengths
piece_x_length  dw 4, '$' ; width
piece_y_length  dw 2, '$' ; height
piece_x dw 5, '$' ; x coordinate
piece_y dw 10, '$' ; y coordinate

piece_count db 0, '$'
; declare our variables for the generic draw procedure
draw_address dw ?, '$'
draw_x_length dw 0, '$'
draw_y_length dw 0, '$'
draw_x dw 0, '$'
draw_y dw 0, '$'
draw_block_x dw 0, '$'
draw_block_y dw 0, '$'

color db 3, '$' ; green

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

	; ---- title of the game
	mov dl, 15 ; x
	mov dh, 1 ; y
	mov ah, 02h ; move cursor to the right place
	mov bh, 0 ; video page 0
	int 10h
	mov dx, offset msg_title
	mov ah, 09h ; display de strings
	int 21h

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

	; ---- draw the game matrix border
	call draw_matrix_border
	; ---- generate one piece at a time and move them
;---------------------------------------------
	call piece_generator
;---------------------------------------------

	; ---- waits for a key to end it
	mov ah, 01
	int 21h

	; ---- back to de text mode
	mov ah, 00h ; define the graphic mode
	mov al, 02h ; text mode 80x25
	int 10h

	ret ; return the control to dos
myproc endp ; end of the procedure myproc

;--------------------------------------
;	PROCS
;--------------------------------------
pause proc near
	push ax

	mov dl, 15
	mov dh, 3
	mov ah, 02h
	mov bh, 0
	int 10h
	lea dx, msg_paused
	mov ah, 09h
	int 21h

listen_unpause:
	mov ah,01h
	int 16h
	jnz check_unpause
	jmp listen_unpause

check_unpause:
	mov ah, 00h
	int 16h
	cmp al, 'p' ; p- pause button
	je exit_pause
	jmp listen_unpause

	exit_pause:
	mov dl, 15
	mov dh, 3
	mov ah, 02h
	mov bh, 0
	int 10h
	lea dx, msg_clear
	mov ah, 09h
	int 21h

	pop ax
	ret
pause endp

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

	mov al, color
	mov ah, 12 ; config int10h to the pixel plot

; draw each pixel
drawcolumn:
	int 10h
	inc cx
	cmp cx, draw_block_x
	jb drawcolumn

	sub cx, 10 ; starting x coordinate of current block
	inc dx ; new line
	cmp dx, draw_block_y
	jb drawcolumn

	sub draw_block_x, 10
	sub draw_block_y, 10
	ret
printblock endp

; --- selects a piece at random using system clock ticks
randompiece proc near
	push bx
	push cx
	push dx
	xor ax, ax
	; --- system time cx:dx
	mov ah, 00h
	int 1ah
	;we used a middle-square method to generate pseudorandom numbers
	add dx, 0fh
	mov ax, dx
	mul ax
	mov bl, ah
	mov bh, al
	mov ax, bx
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

; --- move a piece up
move_up proc near
move_up_loop:
	mov color, 2
	mov ax, piece_x ; x coordinate
	mov draw_x, ax
	mov ax, piece_y ; y coordinate
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	mov color, 3
	mov ax, piece_x ; x coordinate
	mov draw_x, ax

	; -------------
	mov ax, piece_y
	sub ax, 1
	mov piece_y, ax
	; -------------

	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	call delay

	mov ax, 9
	mov bx, piece_y
	sub bx, 2
	mul bx
	mov bx, piece_x

	add ax, bx
	mov bx, ax

	cmp matrix[bx], 1
	je move_up_hit

	mov ax, draw_y
	cmp ax, matrix_y
  jg move_up_loop
move_up_hit:
  ret
move_up endp

; ---- generate one piece at a time, move them up and put them in the matrix
piece_generator proc near
piece_generator_loop:
	; ---- draw a random piece
	call randompiece
	mov draw_address, ax
	mov ax, piece_x ; x coordinate
	mov draw_x, ax
	mov ax, piece_y ; y coordinate
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw
	call move_up
	call save_piece

	mov piece_x_length, 4
	mov piece_y_length, 2
	mov piece_x, 5
	mov piece_y, 10

	mov bl, piece_count
	inc bl
	mov piece_count, bl
	cmp bl, 4
	jl piece_generator_loop
	ret
piece_generator endp

; ---- put the current piece in the matrix
save_piece proc near
	xor si, si
	xor di, di

save_piece_loop:
	; get matrix index depending on the current piece block
	mov ax, 9
	mov bx, piece_y
	sub bx, 1
	mul bx
	mov bx, piece_x
	sub bx, 1
	add ax, bx
	add ax, si

	; mov the bit of current piece block to the matrix index
	mov cx, ax
	mov bx, draw_address
	add bx, di
	mov ax, [bx]
	mov bx, cx
	mov matrix[bx], al

	inc di
	inc si

	; if si is 3 means we will need to move y to +1
	cmp si, 4
	je save_piece_increasey

	cmp si, 13
	jle save_piece_loop

	ret

; instead of adding +1 to y we can just add 7
; which is the number of blocks to a new line
; x length = 10, si = 4 => 10 - 4 = 6
save_piece_increasey:
	add si, 6
	jmp save_piece_loop
save_piece endp

; --- delay procedure
delay proc near
	push dx
	push cx

timer:
	mov ah, 00h
	int 1ah
	cmp dx, wait_time
	jb timer
	add dx, 6 ; 1-18, where smaller is faster and 18 is close to 1 second
	mov wait_time,dx

listen_keys:
	mov ah,01h
	int 16h
	jnz check_key
	jmp stop_delay

call_pause:
	call pause
	jmp listen_keys

check_key:
	mov ah, 00h
	int 16h
	cmp al, 'p'
	je call_pause
	jmp listen_keys

stop_delay:
	pop cx
	pop dx
	ret
delay endp

draw_matrix_border proc near
	mov cx, matrix_x
	mov dx, matrix_y

draw_matrix_border_loop_top:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	inc cx
	mov bx, 100
	add bx, matrix_x
	cmp cx, bx
	jl draw_matrix_border_loop_top

draw_matrix_border_loop_right:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	inc dx
	mov bx, 150
	add bx, matrix_y
	cmp dx, bx
	jl draw_matrix_border_loop_right

draw_matrix_border_loop_bottom:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	dec cx
	mov bx, matrix_x
	cmp cx, bx
	jg draw_matrix_border_loop_bottom

draw_matrix_border_loop_left:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	dec dx
	mov bx, matrix_y
	cmp dx, bx
	jg draw_matrix_border_loop_left

	ret
draw_matrix_border endp

mycode ends ; end of the code segment
end ; end of the program
