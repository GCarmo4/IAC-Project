;display
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh

;stack pointer
SP_INIT         EQU     7000h

;timer
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0
TIMERCOUNT_MAX  EQU     20
TIMERCOUNT_MIN  EQU     1
TIMERCOUNT_INIT EQU     10

;interruption mask
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     80FFh 

;control variable
KEY0            EQU     0

                ORIG    0
                
TIMER_COUNTVAL  WORD    TIMERCOUNT_INIT ; states the current counting period
TIMER_TICK      WORD    0               ; indicates the number of unattended
                                        ; timer interruptions
TIME            WORD    0               ; time elapsed

MAIN:           MVI     R6,SP_INIT
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ENI
                MVI     R2,TIMERCOUNT_INIT
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          
                MVI     R1,TIMER_TICK
                STOR    M[R1],R0          ; clear all timer ticks
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; start timer
                
                MVI     R5,TIMER_TICK
.LOOP:          
                LOAD    R1,M[R5]
                CMP     R1,R0
                JAL.NZ  PROCESS_TIMER_EVENT
                BR      .LOOP
PROCESS_TIMER_EVENT:
                MVI     R2,TIMER_TICK
                DSI     ; critical region: if an interruption occurs, value might become wrong
                LOAD    R1,M[R2]
                DEC     R1
                STOR    M[R2],R1
                ENI
                
                ;waits for '0' to be pressed
ciclo_inicio:   MVI     R2, KEY0
                LOAD    R1, M[R2]
                MVI     R2, 1
                CMP     R1, R2
                JMP.NZ   R7
                
                ; UPDATE TIME
                MVI     R1,TIME
                LOAD    R2,M[R1]
                INC     R2
                STOR    M[R1],R2
                ; SHOW TIME ON DISP7_D4
                MVI     R3, 0
                MVI     R1, 10000        ;convert to decimal
POS4:           CMP     R2, R1
                BR.N    .POS4_SUB
                SUB     R2, R2, R1
                INC     R3
                BR      POS4
.POS4_SUB:      MVI     R1,DISP7_D4
                STOR    M[R1],R3
                ; SHOW TIME ON DISP7_D3
                MVI     R3, 0
                MVI     R1, 1000
POS3:           CMP     R2, R1
                BR.N    .POS3_SUB
                SUB     R2, R2, R1
                INC     R3
                BR      POS3
.POS3_SUB:      MVI     R1,DISP7_D3
                STOR    M[R1],R3
                ; SHOW TIME ON DISP7_D2
                MVI     R3, 0
                MVI     R1, 100
POS2:           CMP     R2, R1
                BR.N    .POS2_SUB
                SUB     R2, R2, R1
                INC     R3
                BR      POS2
.POS2_SUB:      MVI     R1,DISP7_D2
                STOR    M[R1],R3
                ; SHOW TIME ON DISP7_D1
                MVI     R3, 0
                MVI     R1, 10
POS1:           CMP     R2, R1
                BR.N    .POS1_SUB
                SUB     R2, R2, R1
                INC     R3
                BR      POS1
.POS1_SUB:      MVI     R1,DISP7_D1
                STOR    M[R1],R3
                ; SHOW TIME ON DISP7_D0
                MVI     R3, 0
                MVI     R1, 1
POS0:           CMP     R2, R1
                BR.N    .POS0_SUB
                SUB     R2, R2, R1
                INC     R3
                BR      POS0
.POS0_SUB:      MVI     R1,DISP7_D0
                STOR    M[R1],R3
                JMP     R7
                
AUX_TIMER_ISR:  ; SAVE CONTEXT
                DEC     R6
                STOR    M[R6],R1
                DEC     R6
                STOR    M[R6],R2
                ; RESTART TIMER
                MVI     R1,TIMER_COUNTVAL
                LOAD    R2,M[R1]
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          ; set timer to count value
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; start timer
                ; INC TIMER FLAG
                MVI     R2,TIMER_TICK
                LOAD    R1,M[R2]
                INC     R1
                STOR    M[R2],R1
                ; RESTORE CONTEXT
                LOAD    R2,M[R6]
                INC     R6
                LOAD    R1,M[R6]
                INC     R6
                JMP     R7

                ORIG    7FF0h
TIMER_ISR:      ; SAVE CONTEXT
                DEC     R6
                STOR    M[R6],R7
                ; CALL AUXILIARY FUNCTION
                JAL     AUX_TIMER_ISR
                ; RESTORE CONTEXT
                LOAD    R7,M[R6]
                INC     R6
                RTI

                ORIG    7F00h
                
KEYzero:        MVI     R1, 1
                MVI     R2, KEY0
                STOR    M[R2], R1
                RTI

