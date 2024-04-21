;terminal
TERM_READ       EQU     FFFFh
TERM_WRITE      EQU     FFFEh
TERM_STATUS     EQU     FFFDh
TERM_CURSOR     EQU     FFFCh

; interruption mask
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     80FFh 

altura          EQU     2             ;altura (geracato)
comprimento     EQU     80            ;table/game field length

;display
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh

;stack pointer for timer
SP_INIT         EQU     7000h

;timer
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0
TIMERCOUNT_MAX  EQU     20
TIMERCOUNT_MIN  EQU     1
TIMERCOUNT_INIT EQU     2

;control variables
KEYUP           EQU     1001h
KEY0            EQU     1000h

ORIG            4000h   

Campo           TAB     comprimento

ORIG            0000h

TIMER_COUNTVAL  WORD    TIMERCOUNT_INIT ; states the current counting period
TIMER_TICK      WORD    0               ; indicates the number of unattended
                                        ; timer interruptions
TIME            WORD    0

                ; interrupt mask
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                
                ;save height pointer
                MVI     R6, 7FF8h
                MVI     R1, 2B0Ah
                STOR    M[R6], R1
                
                ENI
                
                JAL     ciclo_inicio
                
                ;waits for '0' to be pressed
ciclo_inicio:   MVI     R6, 1E00h
                STOR    M[R6], R7
                
                MVI     R2, KEY0
                LOAD    R1, M[R2]
                MVI     R2, 1
                CMP     R1, R2
                BR.NZ   ciclo_inicio
                
                DSI     
                
                ;clears display
                MVI     R2, DISP7_D0
                MVI     R1, 0
                STOR    M[R2], R1
                MVI     R2, DISP7_D1
                STOR    M[R2], R1
                MVI     R2, DISP7_D2
                STOR    M[R2], R1
                MVI     R2, DISP7_D3
                STOR    M[R2], R1
                MVI     R2, DISP7_D4
                STOR    M[R2], R1
                MVI     R2, DISP7_D5
                STOR    M[R2], R1
                MVI     R2, TIME
                STOR    M[R2],R1
                
                MVI     R2, TERM_CURSOR
                MVI     R1, FFFFh
                STOR    M[R2], R1
                
                MVI     R5, 10         ;geracato seed
                MVI     R6, Campo     ;sets R6 to the 1st position in Campo
                MVI     R4, 4
                STOR    M[R6], R4
                MVI     R1, comprimento
                DEC     R1
                ADD     R6, R6, R1
                MVI     R4, 3
                STOR    M[R6], R4 
                

                ;writes the floor
                MVI     R2, TERM_CURSOR
                MVI     R1, 2C00h
                STOR    M[R2], R1
                MVI     R4, comprimento
chao:           MVI     R2, TERM_WRITE
                MVI     R1, 205
                STOR    M[R2], R1
                DEC     R4
                CMP     R4, R0
                BR.NZ   chao
                MVI     R2, TERM_CURSOR
                MVI     R1, 2B0Ah
                STOR    M[R2],R1
                MVI     R2, TERM_WRITE
                MVI     R1, 3
                STOR    M[R2], R1
                
                ENI
                
TIMER:          MVI     R6,SP_INIT
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ENI
                MVI     R2,TIMERCOUNT_INIT
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          ; set timer to count 2x100ms
                MVI     R1,TIMER_TICK
                STOR    M[R1],R0          ; clear all timer ticks
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; start timer

                
LOOP:           MVI     R6, SP_INIT
                MVI     R4,TIMER_TICK
                LOAD    R1,M[R4]
                CMP     R1,R0
                JAL.NZ  PROCESS_TIMER_EVENT
                BR      LOOP
                
PROCESS_TIMER_EVENT:

                MVI     R2,TIMER_TICK
                DSI     ; critical region: if an interruption occurs, value might become wrong
                LOAD    R1,M[R2]
                DEC     R1
                STOR    M[R2],R1
                ENI

                ; UPDATE TIME
                MVI     R1,TIME
                LOAD    R2,M[R1]
                INC     R2
                STOR    M[R1],R2
                ; SHOW TIME ON DISP7_D4
                MVI     R3, 0
                MVI     R1, 10000        ;convertso to decimal
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
                
                JAL     OUTPUT
                
AUX_TIMER_ISR:  ; SAVE CONTEXT
                MVI     R6, SP_INIT
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
                
                ;updates Campo/game field
atualizajogo:   MVI     R6, Campo
                MVI     R1, comprimento
                DEC     R1
                ADD     R6, R6, R1
                LOAD    R4, M[R6]
                STOR    M[R6], R3
                
recuar:         DEC     R6            ;shifts every Campo element 1 position to the left
                LOAD    R2, M[R6]
                STOR    M[R6], R4
                MVI     R1, 4000h
                CMP     R6, R1
                JAL.Z    LOOP
                DEC     R6
                LOAD    R4, M[R6]
                STOR    M[R6], R2
                BR        recuar
                
                ;generates a number to add to Campo
geracato:       MVI     R1, altura    ;x => R2
                MVI     R2, 1         ;altura => R1
                AND     R4, R5, R2    ;bit => R4
                SHR     R5
                CMP     R4, R0
                BR.Z    bit0
                MVI     R2, b400h
                XOR     R5, R5, R2
                                
bit0:           MVI     R2, 62258
                CMP     R2, R5
                BR.NC   zero
                DEC     R1
                AND     R3, R5, R1
                INC     R3
                BR      atualizajogo
                
zero:           MOV     R3, R0
                BR      atualizajogo
                
                ;translates numbers to symbols to write in the terminal
OUTPUT:         MVI     R6, 4000h


                ;goes through every position in campo (4000h-4050h) and writes in terminal
OUTPUT2:        MVI     R2, TERM_CURSOR
                MOV     R1, R6
                MVIH    R1, 2Bh
                STOR    M[R2], R1

                LOAD    R1, M[R6]
                INC     R6
                DEC     R1
                CMP     R1, R0
                BR.Z    CACTO1
                BR.P    CACTO2
                MVI     R2, TERM_WRITE
                INC     R1
                STOR    M[R2], R1
                
OUTPUT3:        MVI     R1, 4050h
                CMP     R6, R1
                BR.Z    pos_dino
                BR      OUTPUT2
                
                ;determines dino position and writes on terminal
pos_dino:       MVI     R2, KEYUP
                LOAD    R1, M[R2]
                MVI     R2, 1
                CMP     R1, R2
                BR.Z    .salto
                
                ;when 'up' is not pressed, keep lowering the dino until it reaches the floor
                MVI     R6, 7FF8h
                LOAD    R1, M[R6]
                MVI     R2, 2B0Ah
                CMP     R1, R2
                BR.Z    .pos_chao
                MVI     R2, TERM_CURSOR
                STOR    M[R2],R1
                MVI     R4, 0100h
                ADD     R1, R1, R4
                STOR    M[R6], R1
                MVI     R2, TERM_WRITE
                MVI     R1, 0
                STOR    M[R2], R1
.pos_chao:      MVI     R2, TERM_CURSOR
                LOAD    R1, M[R6]
                STOR    M[R2],R1
                MVI     R2, TERM_WRITE
                MVI     R1, 3
                STOR    M[R2], R1
                ;check if there is a collision            
                LOAD    R1, M[R6]
                MVI     R2,2B0Ah
                CMP     R1, R2
                BR.NZ   .sem_colisao
                MVI     R6, 400Ah
                LOAD    R1, M[R6]
                CMP     R1, R0
                BR.NZ    game_over

.sem_colisao:   JAL     geracato
                
                ;if 'up' is pressed, jump
.salto:         MVI     R6, 7FF8h
                LOAD    R1, M[R6]
                MVI     R2, TERM_CURSOR
                STOR    M[R2],R1
                MVI     R4, 0100h
                SUB     R1, R1, R4
                STOR    M[R6], R1
                MVI     R2, TERM_WRITE
                MVI     R1, 0
                STOR    M[R2], R1
                MVI     R2, TERM_CURSOR
                LOAD    R1, M[R6]
                STOR    M[R2],R1
                MVI     R2, TERM_WRITE
                MVI     R1, 3
                STOR    M[R2], R1
                ;checks if there is a collision
                LOAD    R1, M[R6]
                MVI     R2,2A0Ah
                CMP     R1, R2
                BR.NZ   .sem_colisao2
                MVI     R6, 400Ah
                LOAD    R1, M[R6]
                MVI     R2, 1
                CMP     R1, R2
                BR.P    game_over
.sem_colisao2:  MVI     R2, 280Ah
                CMP     R1, R2
                JAL.NZ  geracato
                MVI     R1, 0
                MVI     R2, KEYUP
                STOR    M[R2], R1
                JAL     geracato
                
                ;if number in Campo = 1
CACTO1:         MVI     R2, TERM_WRITE
                MVI     R1, 204
                STOR    M[R2], R1
                BR      OUTPUT3

                ;if number in Campo = 2
CACTO2:         MVI     R2, TERM_WRITE
                MVI     R1, 206
                STOR    M[R2], R1
                MVI     R2, TERM_CURSOR
                MOV     R1, R6
                DEC     R1
                MVIH    R1, 2Ah
                STOR    M[R2], R1
                MVI     R2, TERM_WRITE
                MVI     R1, 206
                STOR    M[R2], R1
                MVI     R2, TERM_CURSOR
                MOV     R1, R6
                MVIH    R1, 2Ah
                STOR    M[R2], R1
                MVI     R2, TERM_WRITE
                STOR    M[R2], R0
                MVI     R2, TERM_CURSOR
                MVI     R1, 2A00h
                STOR    M[R2], R1
                MVI     R2, TERM_WRITE
                STOR    M[R2], R0
                MVI     R2, TERM_CURSOR
                MVI     R1, 2B00h
                STOR    M[R2], R1
                MVI     R2, TERM_WRITE
                STOR    M[R2], R0
                JAL     OUTPUT3

                ;if there is a collision 
                ;clears terminal
game_over:      MVI     R2, TERM_CURSOR
                MVI     R1, FFFFh
                STOR    M[R2], R1
                MVI     R1, 1725h
                STOR    M[R2], R1
                MVI     R2, TERM_WRITE
                MVI     R1, 71
                STOR    M[R2], R1
                MVI     R1, 65
                STOR    M[R2], R1
                MVI     R1, 77
                STOR    M[R2], R1
                MVI     R1, 69
                STOR    M[R2], R1
                MVI     R1, 0
                STOR    M[R2], R1
                MVI     R1, 79
                STOR    M[R2], R1
                MVI     R1, 86
                STOR    M[R2], R1
                MVI     R1, 69
                STOR    M[R2], R1
                MVI     R1, 82
                STOR    M[R2], R1
                MVI     R2, KEY0
                MVI     R1, 0
                STOR    M[R2], R1
                MVI     R6, 1E00h
                LOAD    R7, M[R6]
                
                ;sets all Campo numbers to 0
                MVI     R6, Campo
.reset_campo:   MVI     R1, 0
                STOR    M[R6], R1
                INC     R6
                MVI     R2, 4050h
                CMP     R6, R2
                BR.NZ   .reset_campo
                JMP     R7
                
;*******************************************************************
;INTERRUPT ROUTINES
;*******************************************************************

                ORIG    7F30h
                
KEYseta:        MVI     R1, 1
                MVI     R2, KEYUP
                STOR    M[R2], R1
                RTI
                
                ORIG    7F00h
                
KEYzero:        MVI     R1, 1
                MVI     R2, KEY0
                STOR    M[R2], R1
                RTI
                
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
                
                
                
                
                
                