WIDTH           .EQU     77
HEIGHT          .EQU     33

WIDTH_WB        .EQU     WIDTH+2
HEIGHT_WB       .EQU     HEIGHT+2

CR              .EQU     0DH
LF              .EQU     0AH
    
                .ORG     9000H

initBoard
                LD      DE, 0               ;Load generation
                LD      HL, board1
                CALL    inputBlankRow       ;Set the top row to empty
                LD      B,  HEIGHT

                
initBoardRow:
                PUSH    BC                  ;Save height for later
                LD      (HL), 0             ;Set the first colum to 0
                INC     HL                  
                LD      B,  WIDTH
initBoardCell:
                CALL    RandLFSR
                CP      256 / 4             ; 25% Chance cell is alive
                LD      (HL),0
                JR      NC, cellDead
                INC     (HL)
cellDead:       INC     HL
                DJNZ    initBoardCell       ;Compleate the row
                LD      (HL), 0             ;Set the last colum to 0
                INC     HL 
                POP     BC                  ;Retrive height
                DJNZ    initBoardRow        ;Compleate the board
                CALL    inputBlankRow

mainLoop:
                LD      HL, board1          ;Print board1
                CALL    printBoard
                LD      IX, board1          ;Board 1 is the old board  
                LD      HL, board2          ;Board 2 is the new board
                CALL    elvolve             ;evolve into board 2
                LD      HL, board2          ;Print the board2
                CALL    printBoard
                LD      IX, board2          ;Board 2 in the old baord
                LD      HL, board1          ;Board 1 is the old board 
                CALL    elvolve             ;evolve into board 2
                JR      mainLoop            ;Loop Forever
                RET




;***** Routine *****
inputBlankRow:
                LD      B,      WIDTH_WB
inputBlankRowLoop
                LD      (HL),   0
                INC     HL
                INC     IX
                DJNZ    inputBlankRowLoop
                RET
                
;Evolve
elvolve:
                CALL    inputBlankRow           ;Blank Row at the top
                LD      B,  HEIGHT
                
elvolveRow:
                PUSH    BC                      ;Save height for later   
                LD      (HL),0                  ;0 at the start
                INC     IX                      ;Skip over the colum start
                INC     HL
                LD      B,  WIDTH
elvolveCell:
                CALL    calcCell                ;Calculate a cell
                INC     HL
                INC     IX
                DJNZ    elvolveCell             ;Compleate the row

                LD      (HL),0                  ;0 at the end
                INC     HL                      ;Skip over the colum end
                INC     IX
                POP     BC                      ;Retrive height
                DJNZ    elvolveRow              ;Compleate the board

                CALL    inputBlankRow           ;Blank Row at the bottom
                INC     DE                      ;New generation
                RET

;Board
;1 2 3
;4 x 5
;6 7 8

calcCell:       
                LD      A,0                     ;Comp agaisnt zero 
                LD      C,0                     ;All cells start with no negbours
                CP      (ix - (WIDTH_WB + 1))   ;Pos 1
                CALL    NZ, incC
                CP      (ix - WIDTH_WB)         ;Pos 2
                CALL    NZ, incC
                CP      (ix - (WIDTH_WB - 1))   ;Pos 3
                CALL    NZ, incC
                CP      (ix - 1)                ;Pos 4
                CALL    NZ, incC
                CP      (ix + 1)                ;Pos 5
                CALL    NZ, incC
                CP      (ix + (WIDTH_WB - 1))   ;Pos 6
                CALL    NZ, incC
                CP      (ix + WIDTH_WB)         ;Pos 7
                CALL    NZ, incC
                CP      (ix + (WIDTH_WB +1))    ;Pos 8
                CALL    NZ, incC
                LD      A,C                     ;Copy C into A so we can CP
                CP      3                       
                JR      Z, life                 ;Eactly 3, then life
                JR      NC, death               ;More than 3, death by overpopulation
                CP      2
                JR      Z, maintain             ;Copies from the last generation
                                                ;Anything else, (0 or 1) dies from loneliness
death:
                LD      (HL), 0
                RET

maintain:
                LD      A,  (IX)    
                LD      (HL), A
                RET
life:
                LD      (HL), 1
                RET

incC
                INC     C
                RET

;print
printBoard:
                PUSH    HL
                LD      HL, cls                 ;Start at the top of the screen
                CALL    print
                POP     HL
                LD      B,  HEIGHT_WB           ;Print the board, with the boarder
                
printRow:
                PUSH    BC                      ;Save height for later   
                LD      B,  WIDTH_WB
printCell:
                LD      A,  (HL)
                AND     A                       ;Test for 0
                JR      Z, printDead
printAlive:                
                LD      A, '#'
                RST     08H
                JR      printCont     
printDead:     
                LD      A, ' '
                RST     08H
printCont:
                INC     HL                  ;Next Cell
                DJNZ    printCell           ;Compleate the row
                LD      A,  CR              ;New line
                RST     08H
                LD      A,  LF
                RST     08H
                POP     BC                  ;Retrive height
                DJNZ    printRow            ;Compleate the board
                LD      HL, generation      ;Print "Generation:"
                CALL    print
                PUSH    DE                  ;Copy DE into HL        
                POP     HL
                CALL    DispHL
                                            ;Check For Break Char
                RST		18H
				JR		Z, printDelay
                RST		10H
                CP      03h
                JR      Z, end                   

printDelay:
                LD      BC, 08888h
                CALL    DELAY
                RET

end:
                POP     HL
                LD      HL, showCursor
                CALL    print
                RET                         ;Pack to Prompt
                 
;LIBS
RandLFSR:
                PUSH    HL
                PUSH    DE
                PUSH    BC
                ld hl,LFSRSeed+4
                ld e,(hl)
                inc hl
                ld d,(hl)
                inc hl
                ld c,(hl)
                inc hl
                ld a,(hl)
                ld b,a
                rl e \ rl d
                rl c \ rla
                rl e \ rl d
                rl c \ rla
                rl e \ rl d
                rl c \ rla
                ld h,a
                rl e \ rl d
                rl c \ rla
                xor b
                rl e \ rl d
                xor h
                xor c
                xor d
                ld hl,LFSRSeed+6
                ld de,LFSRSeed+7
                ld bc,7
                lddr
                ld (de),a
                POP     BC
                POP     DE
                POP     HL
                ret

;BUSY LOOP
DELAY:
				NOP
				DEC 	BC
				LD 		A,B
				OR 		C
				RET 	Z
				JR 		DELAY

;Number in hl to decimal ASCII
;Thanks to z80 Bits
;inputs:	hl = number to ASCII
;example: hl=300 outputs '00300'
;destroys: af, bc, hl, used
DispHL:
				ld		bc,-10000
				call	Num1
				ld		bc,-1000
				call	Num1
				ld		bc,-100
				call	Num1
				ld		c,-10
				call	Num1
				ld		c,-1
Num1:			ld		a,'0'-1
Num2:			inc		a
				add		hl,bc
				jr		c,Num2
				sbc		hl,bc
				RST     08H
				ret

print:          LD      A,(HL)          ; Get character
                OR      A               ; Is it $00 ?
                RET     Z               ; Then RETurn on terminator
                RST     08H             ; Print it
                INC     HL              ; Next Character
                JR      print           ; Continue until $00

cls      	    .BYTE 1BH,"[H",1BH,"[?25l",0
showCursor:     .BYTE 1BH,"[?25h",0
generation      .BYTE "Generation:",0

board1:
    defs WIDTH_WB*HEIGHT_WB
board2:
    defs WIDTH_WB*HEIGHT_WB
LFSRSeed:
    .BYTE 1BH

