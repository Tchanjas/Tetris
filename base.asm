STACK SEGMENT PARA STACK ; define the stack segment
  DB 64 DUP('MYSTACK')
STACK ENDS

MYDATA SEGMENT PARA 'DATA'
; variables
MYDATA ENDS

MYCODE SEGMENT PARA 'CODE' ; define the code segment
MYPROC PROC FAR ; name of the procedure MYPROC

  RET ; return the control to DOS
MYPROC ENDP ; end of the procedure MYPROC

example1 PROC NEAR
  RET
example1 ENDP

MYCODE ENDS ; end of the code segment
END ; end of the program
