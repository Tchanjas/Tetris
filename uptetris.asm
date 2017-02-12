stack segment para stack ; define the stack segment
db 64 dup('mystack')
stack ends

mydata segment para 'data'
db 64 dup('mystack')
wait_time dw 1
tick_time dw 18

msg_title db 'up_tetris', '$'
msg_lines_txt db 'lines eliminated: ', '$'
msg_lines_num db 0, '$'
msg_min_txt db 'minutes: ', '$'
msg_min_num db 0, '$'
msg_sec_txt db 'seconds: ', '$'
msg_sec_num db 0, '$'
msg_paused db 'paused', '$'
msg_clear db '            ', '$'

; game matrix is 10 columns and 15 lines
; that gives us 150 blocks with 10 pixels of width and height for each block
matrix db 150 dup(0), '$'
matrix_x_length dw 10, '$' ; width
matrix_y_length dw 15, '$' ; height
matrix_x dw 1, '$' ; x coordinate
matrix_y dw 1, '$' ; y coordinate

; declare the matrix pieces
piecelinefour db 1, 1, 1, 1, '$'
piecelinetwo  db 1, 1, '$'

piecelup      db 1, 0, 0, 1, 1, 1, '$'
piecelup90    db 1, 1, 1, 0, 1, 0, '$'
piecelup180   db 1, 1, 1, 0, 0, 1, '$'
piecelup270   db 0, 1, 0, 1, 1, 1, '$'

pieceldown    db 1, 1, 1, 1, 0, 0, '$'
pieceldown90  db 1, 1, 0, 1, 0, 1, '$'
pieceldown180 db 0, 0, 1, 1, 1, 1, '$'
pieceldown270 db 1, 0, 1, 0, 1, 1, '$'

piecez        db 1, 1, 0, 0, 1, 1, '$'
piecez90      db 0, 1, 1, 1, 1, 0, '$'

pieceType dw ?, '$'
pieceState dw 0, '$'


; declare piece coordinates and lengths
piece_x_length  dw 4, '$' ; width
piece_y_length  dw 2, '$' ; height
piece_x dw 5, '$' ; x coordinate
piece_y dw 14, '$' ; y coordinate

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
	mov al, 13h ; graphic mode 320x200 color mode
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

	;---------------------------------------------
 	call get_time
	mov msg_sec_num, dh
	;---------------------------------------------

	; ---- draw the game matrix border
	call draw_matrix_border
	; ---- generate one piece at a time and move them
	;---------------------------------------------
	call piece_generator
	;---------------------------------------------

	; ---- back to text mode
	mov ah, 00h ; define the graphic mode
	mov al, 02h ; text mode 80x25
	int 10h

	ret ; return the control to dos
myproc endp ; end of the procedure myproc


;--------------------------------------
;	PROCEDURES
;--------------------------------------
get_time proc near
	; --- get starting timestamp
	; --- dh => seconds
	mov ah, 2ch
	int 21h
	ret
get_time endp

; procedure to pause/unpause the game
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

; checks if there is a key in the buffer
listen_unpause:
	mov ah,01h
	int 16h
	jnz check_unpause
	jmp listen_unpause

; waits for 'p' in buffer
check_unpause:
	mov ah, 00h
	int 16h
	cmp al, 'p' ; p- pause button
	je exit_pause
	jmp listen_unpause

	;remove paused message by print blank chars
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
	push bx
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
	pop bx
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
	mov tick_time, 18
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
	;dx will hold the remainder of the division
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
  	call piecelinefourCombs
	jmp exit
loadlinetwo:
	call piecelinetwoCombs
	jmp exit
loadlup:
	call piecelupCombs
	jmp exit
loadldown:
	call pieceldownCombs
	jmp exit
loadz:
	call piecezCombs
	jmp exit

exit:
	pop dx
	pop cx
	pop bx
	ret
randompiece endp

piecelinefourCombs proc near
    lea ax, piecelinefour
    mov piece_x_length, 4
    mov piece_y_length, 1
    mov pieceType, 0
    mov pieceState, 1
    ret
piecelinefourCombs endp

piecelinetwoCombs proc near
    lea ax, piecelinetwo
    mov piece_x_length, 2
    mov piece_y_length, 1
    mov pieceType, 1
    mov pieceState, 1
    ret
piecelinetwoCombs endp

piecelupCombs proc near
	lea ax, piecelup
    mov piece_x_length, 3
    mov piece_y_length, 2
    mov pieceType, 2
    mov pieceState, 1
    ret
piecelupCombs endp

pieceldownCombs proc near
	lea ax, pieceldown
    mov piece_x_length, 3
    mov piece_y_length, 2
    mov pieceType, 3
    mov pieceState, 1
    ret
pieceldownCombs endp

piecezCombs proc near
	lea ax, piecez
    mov piece_x_length, 3
    mov piece_y_length, 2
    mov pieceType, 4
    mov pieceState, 1
    ret
piecezCombs endp

; --- move a piece up
move_up proc near
move_up_loop:
	mov color, 0
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
	cmp ax, 10 ; matrix_y
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
	call check_lines

	mov piece_x, 5
	mov piece_y, 14

	mov bl, piece_count
	inc bl
	mov piece_count, bl
	cmp bl, 20
	jl piece_generator_loop
	ret
piece_generator endp

; ---- put the current piece in the matrix
save_piece proc near
	xor si, si
	xor di, di

save_piece_loop:
	; get matrix index depending on the current piece block
	mov ax, 10
	mov bx, piece_y
	dec bx
	mul bx
	mov bx, piece_x
	dec bx
	add ax, bx
	add ax, si

	; mov the bit of current piece block to the matrix index
	mov cx, ax
	mov bx, draw_address
	add bx, di
	mov al, [bx]
	mov bx, cx
	mov matrix[bx], al

	inc di
	inc si

	mov ax, piece_x_length
	mul piece_y_length
	dec ax
	cmp di, ax
	jg save_piece_end

	mov ax, di
	div piece_x_length
	cmp dx, 0 ; module
	jne save_piece_loop

	add si, 7
	jmp save_piece_loop

save_piece_end:
ret
save_piece endp

print_chrono proc near
	mov dl, 15
	mov dh, 5
	mov ah, 02h
	mov bh, 0
	int 10h
	lea dx, msg_clear
	mov ah, 09h
	int 21h

	mov dl, 15
	mov dh, 5
	mov ah, 02h
	mov bh, 0
	int 10h

	lea dx, msg_sec_txt
	mov ah, 09h
	int 21h

	call get_time
	cmp dh, msg_sec_num
	jb correct_sec

show_time:
	; -- seconds
	sub dh, msg_sec_num
	xor ax, ax
	mov al, dh
	call convertNum

	cmp dh, 59
	je inc_minutes

	mov dl, 15
	mov dh, 4
	mov ah, 02h
	mov bh, 0
	int 10h
	lea dx, msg_clear
	mov ah, 09h
	int 21h

	; -- minutes
	mov dl, 15
	mov dh, 4
	mov ah, 02h
	mov bh, 0
	int 10h

	lea dx, msg_min_txt
	mov ah, 09h
	int 21h

	xor ax, ax
	mov al, msg_min_num
	call convertNum

chrono_out:
	ret

correct_sec:
	xor ax, ax
	mov ah, 60
	add dh, ah
	jmp show_time

inc_minutes:
	inc msg_min_num
	jmp chrono_out
print_chrono endp

print_lines proc near
	mov dl, 15
	mov dh, 6
	mov ah, 02h
	mov bh, 0
	int 10h
	lea dx, msg_lines_txt
	mov ah, 09h
	int 21h

	xor ax, ax
	mov al, msg_lines_num
	call convertNum
	ret
print_lines endp

jump_up proc near
	mov tick_time, 1
	ret
jump_up endp

; --- delay procedure
delay proc near
	push dx
	push cx

timer:
; -- Check for mouse button presses
	mov al, 05h
	mov bx, 0 ; left mouse
	int 33h
	cmp bx, 0
	jg call_rotate

	mov ah, 00h
	int 1ah
	cmp dx, wait_time
	jb timer
	add dx, tick_time ; 1-18, where smaller is faster and 18 is close to 1 second
	mov wait_time,dx

printInfo:
	call print_chrono
	call print_lines

; listens for keyboard inputs
listen_keys:
	mov ah,01h
	int 16h
	jnz check_key
	jmp stop_delay

call_pause:
	call pause
	jmp listen_keys

call_move_left:
	call move_left
	jmp listen_keys

call_move_right:
	call move_right
	jmp listen_keys

call_rotate:
	call rotate_piece
	jmp listen_keys

call_jump_up:
	call jump_up
	jmp listen_keys

call_end_game:
	; ---- back to text mode
	mov ah, 00h ; define the graphic mode
	mov al, 02h ; text mode 80x25
	int 10h

	xor ax, ax
	mov ah, 4Ch
	int 21h

check_key:
	mov ah, 00h
	int 16h
	cmp al, 'p' ; pause key
	je call_pause

	cmp al, 'j' ; move the current piece left key
	je call_move_left

	cmp al, 'l' ; move the current piece left right
	je call_move_right

	cmp al, 'q' ; end the game
	je call_end_game

	cmp al, 'i' ; rotate the current piece
	je call_rotate

	cmp al, 'k' ; jump to top
	je call_jump_up

	jmp listen_keys
	jmp printInfo

stop_delay:
	pop cx
	pop dx
	ret
delay endp

rotate_piece proc near
	mov color, 0
	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y ; y coordinate
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	mov color, 3

	mov ax, pieceType
	cmp ax, 0
	jne rotate_piece_cmp1
		rotate_piece_type_0:
			mov ax, piece_x_length
			mov cx, ax
		    mov bx, piece_y_length
		    mov dx, bx
		    mov piece_x_length, dx
		    mov piece_y_length, cx
			mov draw_x_length, dx
			mov draw_y_length, cx
			lea ax, piecelinefour
			jmp rotate_piece_address

	rotate_piece_cmp1:
	cmp ax, 1
	jne rotate_piece_cmp2
		rotate_piece_type_1:
			mov ax, piece_x_length
			mov cx, ax
		    mov bx, piece_y_length
		    mov dx, bx
		    mov piece_x_length, dx
		    mov piece_y_length, cx
			mov draw_x_length, dx
			mov draw_y_length, cx
			lea ax, piecelinetwo
			jmp rotate_piece_address

	rotate_piece_cmp2:
	cmp ax, 2
	jne rotate_piece_cmp3
	call rotate_piece_type_2
	ret

	rotate_piece_cmp3:
	cmp ax, 3
	jne rotate_piece_cmp4
	call rotate_piece_type_3
	ret

	rotate_piece_cmp4:
	cmp ax, 4
	jne rotate_piece_end
	call rotate_piece_type_4
	ret

	rotate_piece_address:
	mov draw_address, ax

	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y
	mov draw_y, ax

	call draw
	call delay
rotate_piece_end:
ret
rotate_piece endp

rotate_piece_type_2 proc near
	mov ax, pieceState
	cmp ax, 0
	je rotate_piece_type_2_state_0
	cmp ax, 1
	je rotate_piece_type_2_state_1
	cmp ax, 2
	je rotate_piece_type_2_state_2
	cmp ax, 3
	je rotate_piece_type_2_state_3

	rotate_piece_type_2_state_0:
	mov pieceState, 1
	lea ax, piecelup
	jmp rotate_piece_type_2_address

	rotate_piece_type_2_state_1:
	mov pieceState, 2
	lea ax, piecelup90
	jmp rotate_piece_type_2_address

	rotate_piece_type_2_state_2:
	mov pieceState, 3
	lea ax, piecelup180
	jmp rotate_piece_type_2_address

	rotate_piece_type_2_state_3:
	mov pieceState, 0
	lea ax, piecelup270
	jmp rotate_piece_type_2_address

rotate_piece_type_2_address:
	mov draw_address, ax

	mov ax, piece_x_length
	mov cx, ax
    mov bx, piece_y_length
    mov dx, bx
    mov piece_x_length, dx
    mov piece_y_length, cx
	mov draw_x_length, dx
	mov draw_y_length, cx

	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y
	mov draw_y, ax

	call draw
	call delay
	ret
rotate_piece_type_2 endp

rotate_piece_type_3 proc near
	mov ax, pieceState
	cmp ax, 0
	je rotate_piece_type_3_state_0
	cmp ax, 1
	je rotate_piece_type_3_state_1
	cmp ax, 2
	je rotate_piece_type_3_state_2
	cmp ax, 3
	je rotate_piece_type_3_state_3

	rotate_piece_type_3_state_0:
	mov pieceState, 1
	lea ax, pieceldown
	jmp rotate_piece_type_3_address

	rotate_piece_type_3_state_1:
	mov pieceState, 2
	lea ax, pieceldown90
	jmp rotate_piece_type_3_address

	rotate_piece_type_3_state_2:
	mov pieceState, 3
	lea ax, pieceldown180
	jmp rotate_piece_type_3_address

	rotate_piece_type_3_state_3:
	mov pieceState, 0
	lea ax, pieceldown270
	jmp rotate_piece_type_3_address

rotate_piece_type_3_address:
	mov draw_address, ax

	mov ax, piece_x_length
	mov cx, ax
    mov bx, piece_y_length
    mov dx, bx
    mov piece_x_length, dx
    mov piece_y_length, cx
	mov draw_x_length, dx
	mov draw_y_length, cx

	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y
	mov draw_y, ax

	call draw
	call delay
	ret
rotate_piece_type_3 endp

rotate_piece_type_4 proc near
	mov ax, pieceState
	cmp ax, 0
	je rotate_piece_type_4_state_0
	cmp ax, 1
	je rotate_piece_type_4_state_1
	cmp ax, 2
	je rotate_piece_type_4_state_2
	cmp ax, 3
	je rotate_piece_type_4_state_3

	rotate_piece_type_4_state_0:
	mov pieceState, 1
	lea ax, piecez
	jmp rotate_piece_type_4_address

	rotate_piece_type_4_state_1:
	mov pieceState, 2
	lea ax, piecez90
	jmp rotate_piece_type_4_address

	rotate_piece_type_4_state_2:
	mov pieceState, 3
	lea ax, piecez
	jmp rotate_piece_type_4_address

	rotate_piece_type_4_state_3:
	mov pieceState, 0
	lea ax, piecez90
	jmp rotate_piece_type_4_address

rotate_piece_type_4_address:
	mov draw_address, ax

	mov ax, piece_x_length
	mov cx, ax
    mov bx, piece_y_length
    mov dx, bx
    mov piece_x_length, dx
    mov piece_y_length, cx
	mov draw_x_length, dx
	mov draw_y_length, cx

	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y
	mov draw_y, ax

	call draw
	call delay
	ret
rotate_piece_type_4 endp

; procedure to convert a numeric value on AX to ascii and print it
convertNum proc near
	push dx
	push cx
	push bx

	xor cx,cx
	; decimal base
	mov bx, 10

dispx1:
	xor dx,dx
	div bx
	; remainder of division
	push dx
	; count remainders for later loop
	inc cx
	or ax,ax
	jnz dispx1

dispx2:
	pop dx
	mov ah, 6
	; convert digit to ascii
	add dl, 30h
	int 21h
	loop dispx2

	pop bx
	pop cx
	pop dx
	ret
convertNum endp

draw_matrix_border proc near
	mov cx, 9 ; matrix_x - 1
	mov dx, 9 ; matrix_y - 1

draw_matrix_border_loop_top:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	inc cx
	mov bx, 100
	add bx, 10 ; matrix_x
	cmp cx, bx
	jl draw_matrix_border_loop_top

draw_matrix_border_loop_right:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	inc dx
	mov bx, 150
	add bx, 10 ; matrix_y
	cmp dx, bx
	jl draw_matrix_border_loop_right

draw_matrix_border_loop_bottom:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	dec cx
	mov bx, 10 ; matrix_x
	dec bx
	cmp cx, bx
	jg draw_matrix_border_loop_bottom

draw_matrix_border_loop_left:
	mov al, color
	mov ah, 12 ; config int10h to the pixel plot
	int 10h
	dec dx
	mov bx, 10 ; matrix_y
	dec bx
	cmp dx, bx
	jg draw_matrix_border_loop_left

	ret
draw_matrix_border endp

move_left proc near
	mov ax, piece_x
	mov bx, 10
	mul bx
	cmp ax, 10
	jle move_left_end

	mov color, 0
	mov ax, piece_x
	mov draw_x, ax
	mov ax, piece_y ; y coordinate
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	mov color, 3
	; -------------
	mov ax, piece_x
	dec ax
	mov piece_x, ax
	mov draw_x, ax
	; -------------

	mov ax, piece_y
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	move_left_end:
	ret
move_left endp

move_right proc near
	mov ax, piece_x
	add ax, piece_x_length
	mov bx, 10
	mul bx
	mov cx, 100
	cmp ax, cx
	jg move_right_end

	mov color, 0
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
	; -------------
	mov ax, piece_x
	inc ax
	mov piece_x, ax
	mov draw_x, ax
	; -------------

	mov ax, piece_y
	mov draw_y, ax
	mov ax, piece_y_length ; height of the matrix
	mov draw_y_length, ax
	mov ax, piece_x_length ; width of the matrix
	mov draw_x_length, ax
	call draw

	move_right_end:
	ret
move_right endp

check_lines proc near
	xor si, si
	xor di, di
	mov bx, 0

check_lines_loop:
	mov cx, 15
	cmp bx, cx
	jg check_lines_end
	mov ax, bx
	mov cx, 10
	mul cx
	mov si, ax
	inc bx

	check_lines_loop2:
		cmp matrix[si], 1
		jne check_lines_loop
		inc si
		cmp si, 10 ; line length
		jl check_lines_loop2
		jge check_lines_eliminate

check_lines_end:
ret

check_lines_eliminate:
	inc msg_lines_num

	; ---- draw the game matrix
	mov color, 0
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

	mov ax, bx
	mov cx, 10
	mul cx
	mov di, ax
	sub di, 10

	check_lines_loop3:
		lea bx, matrix
		mov si, di
		add si, 10
		add bx, si
		mov cl, [bx]
		mov bx, di
		mov matrix[bx], cl

		inc di
		cmp di, 149
		jne check_lines_loop3

	; ---- draw the game matrix
	mov color, 3
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
ret
check_lines endp

mycode ends ; end of the code segment
end ; end of the program
