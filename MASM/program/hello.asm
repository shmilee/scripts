TITLE 'HELLO.EXE---PRINT HELLO ON SCREEN'
CR EQU 0DH
LF EQU 00H
CSEG SEGMENT PUBLIC 'CODE'
     ASSUME CS:CSEG,DS:DSEG,SS:STACK
PRINT PROC FAR
    PUSH BX
    PUSH AX
    PUSH DS
    MOV AX,DSEG
    MOV DS,AX
    MOV bX,OFFSET MESSAGE
    MOV AH,06h
    INT 10H
    INT 20H
    POP DS
    POP AX
    POP BX
    PRINT   ENDP
    CSEG ENDS
    ;
    DSEG SEGMENT 'DATA'
    MESSAGE DB CR,'HELLO!',CR,LF,'$'
    DSEG ENDS
    ;
    STACK SEGMENT STACK 'STACK'
    DW 64 DUP(9)
    STACK ENDS
    END PRINT

