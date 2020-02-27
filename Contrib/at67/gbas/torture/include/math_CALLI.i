; do *NOT* use register4 to register7 during time slicing if you call realTimeProc
mathX               EQU     register8
mathY               EQU     register9
mathSum             EQU     register12
mathMask            EQU     register13
mathRem             EQU     register12
mathSign            EQU     register13
mathScratch         EQU     register14
mathShift           EQU     register15
mathBase            EQU     register10
mathPow             EQU     register11
mathResult          EQU     register14


%SUB                power16bit
                    ; accumulator = mathX ** mathY, (result 16bit)
power16bit          LDW     mathX
                    BNE     power16_cont0
                    LDI     0
                    RET

power16_cont0       SUBI    1
                    BNE     power16_cont1
                    LDI     1
                    RET
                    
power16_cont1       LDW     mathY
                    BNE     power16_cont2
                    LDI     1
                    RET

power16_cont2       SUBI    1
                    BNE     power16_cont3
                    LDW     mathX               ; return mathX
                    RET
                    
power16_cont3       LDWI    SYS_LSRW1_48
                    STW     giga_sysFn          ; setup right shift
                    LDW     mathX
                    STW     mathBase
                    LDW     mathY
                    STW     mathPow
                    LDI     1
                    STW     mathResult
                    PUSH
                    CALLI   power16bitExt
                    POP
                    RET
%ENDS

%SUB                power16bitExt
power16bitExt       PUSH
                    LDW     mathPow
                    
power16E_loop       ANDI    1
                    BEQ     power16E_skip
                    LDW     mathBase
                    STW     mathX
                    LDW     mathResult
                    STW     mathY
                    CALLI   multiply16bit
                    STW     mathResult          ; mathResult = mathBase * mathResult                    
                    
power16E_skip       LDW     mathBase
                    STW     mathX
                    STW     mathY
                    CALLI   multiply16bit
                    STW     mathBase            ; mathBase = mathBase * mathBase
                    LDW     mathPow
                    SYS     48
                    STW     mathPow             ; mathPow = mathPow / 2
                    BNE     power16E_loop       ; while mathPow > 0
                    POP
                    LDW     mathResult
                    RET
%ENDS

%SUB                multiply16bit
                    ; accumulator = mathX * mathY, (result 16bit)
multiply16bit       LDI     0
                    STW     mathSum
                    LDW     mathX
                    BEQ     multiply16_exit     ; if x=0 then return 0
                    LDWI    SYS_LSRW1_48
                    STW     giga_sysFn
                    LDW     mathY
                    
multiply16_loop     BEQ     multiply16_exit     ; if y=0 then return
                    ANDI    1
                    BEQ     multiply16_skip
                    LDW     mathSum
                    ADDW    mathX
                    STW     mathSum             ; mathSum += mathX
                    
multiply16_skip     LDW     mathX
                    LSLW
                    STW     mathX               ; mathX = mathX <<1
                    LDW     mathY
                    SYS     48
                    STW     mathY               ; mathY = mathY >>1
                    BRA     multiply16_loop

multiply16_exit     PUSH
                    CALLI   realTimeProc
                    POP
                    LDW     mathSum
                    RET
%ENDS   
    
%SUB                multiply16bit_1
                    ; accumulator = mathX * mathY, (result 16bit)
multiply16bit_1     LDI     0
                    STW     mathSum
                    LDI     1
    
multiply161_loop    STW     mathMask
                    ANDW    mathY
                    BEQ     multiply161_skip
                    LDW     mathSum
                    ADDW    mathX
                    STW     mathSum
                    
multiply161_skip    LDW     mathX
                    ADDW    mathX
                    STW     mathX
                    LDW     mathMask
                    ADDW    mathMask
                    BNE     multiply161_loop
                    PUSH
                    CALLI   realTimeProc
                    POP
                    LDW     mathSum
                    RET
%ENDS   
    
%SUB                divide16bit
                    ; accumulator:mathRem = mathX / mathY, (results 16bit)
divide16bit         LDW     mathX
                    XORW    mathY
                    STW     mathSign
                    LDW     mathX
                    BGE     divide16_skip0
                    LDI     0
                    SUBW    mathX
                    STW     mathX
                    
divide16_skip0      LDW     mathY                     
                    BGE     divide16_skip1
                    LDI     0
                    SUBW    mathY
                    STW     mathY
                    
divide16_skip1      LDI     0
                    STW     mathRem
    
divide16_loop       STW     mathScratch
                    LDW     mathRem
                    ADDW    mathRem
                    STW     mathRem
                    LDW     mathX
                    BGE     divide16_skip3
                    INC     mathRem
                    
divide16_skip3      LDW     mathX
                    ADDW    mathX
                    STW     mathX
                    LDW     mathRem
                    SUBW    mathY
                    BLT     divide16_skip4
                    STW     mathRem
                    INC     mathX
                    
divide16_skip4      PUSH
                    CALLI   realTimeProc
                    POP
                    LDW     mathScratch
                    ADDI    1
                    ANDI    0x0F
                    BNE     divide16_loop
                    LDW     mathSign
                    BGE     divide16_exit
                    LDI     0
                    SUBW    mathX
                    RET
                    
divide16_exit       LDW     mathX
                    RET
%ENDS   
    
%SUB                rand16bit
rand16bit           LDWI    SYS_Random_34
                    STW     giga_sysFn
                    SYS     34
                    RET
%ENDS

%SUB                randMod16bit
randMod16bit        PUSH
                    LDWI    SYS_Random_34
                    STW     giga_sysFn
                    SYS     34
                    STW     mathX
                    CALLI   divide16bit
                    LDW     mathRem
                    POP
                    RET
%ENDS

%SUB                shiftLeft4bit
shiftLeft4bit       LDWI    SYS_LSLW4_46
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     46
                    RET
%ENDS   
    
%SUB                shiftLeft8bit
shiftLeft8bit       LDWI    SYS_LSLW8_24
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     28
                    RET
%ENDS   
    
%SUB                shiftRight1bit
shiftRight1bit      LDWI    SYS_LSRW1_48
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     48
                    RET
%ENDS   
    
%SUB                shiftRight2bit
shiftRight2bit      LDWI    SYS_LSRW2_52
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     52
                    RET
%ENDS   
    
%SUB                shiftRight3bit
shiftRight3bit      LDWI    SYS_LSRW3_52
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     52
                    RET
%ENDS   
    
%SUB                shiftRight4bit
shiftRight4bit      LDWI    SYS_LSRW4_50
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     50
                    RET
%ENDS   
    
%SUB                shiftRight5bit
shiftRight5bit      LDWI    SYS_LSRW5_50
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     50
                    RET
%ENDS   
    
%SUB                shiftRight6bit
shiftRight6bit      LDWI    SYS_LSRW6_48
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     48
                    RET
%ENDS   
    
%SUB                shiftRight7bit
shiftRight7bit      LDWI    SYS_LSRW7_30
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     30
                    RET
%ENDS   
    
%SUB                shiftRight8bit
shiftRight8bit      LDWI    SYS_LSRW8_24
                    STW     giga_sysFn
                    LDW     mathShift
                    SYS     28
                    RET
%ENDS

%SUB                shiftRightSgn1bit
shiftRightSgn1bit   LDWI    SYS_LSRW1_48
                    STW     giga_sysFn
                    LDWI    0x8000
                    STW     mathSign
                    ANDW    mathShift
                    BEQ     shiftRS1_pos        ; check sign
                    LDW     mathShift
                    SYS     48                  ; shift right 1
                    ORW     mathSign            ; fix sign
                    RET

shiftRS1_pos        LDW     mathShift           ; positive number
                    SYS     48
                    RET
%ENDS   
    
%SUB                shiftRightSgn2bit
shiftRightSgn2bit   LDWI    SYS_LSRW2_52
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS2_pos        ; check sign
                    LDWI    0xC000
                    STW     mathSign
                    LDW     mathShift
                    SYS     52                  ; shift right 2
                    ORW     mathSign            ; fix sign
                    RET

shiftRS2_pos        LDW     mathShift           ; positive number
                    SYS     52
                    RET
%ENDS   
    
%SUB                shiftRightSgn3bit
shiftRightSgn3bit   LDWI    SYS_LSRW3_52
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS3_pos        ; check sign
                    LDWI    0xE000
                    STW     mathSign
                    LDW     mathShift
                    SYS     52                  ; shift right 3
                    ORW     mathSign            ; fix sign
                    RET

shiftRS3_pos        LDW     mathShift           ; positive number
                    SYS     52
                    RET
%ENDS   

%SUB                shiftRightSgn4bit
shiftRightSgn4bit   LDWI    SYS_LSRW4_50
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS4_pos        ; check sign
                    LDWI    0xF000
                    STW     mathSign
                    LDW     mathShift
                    SYS     50                  ; shift right 4
                    ORW     mathSign            ; fix sign
                    RET

shiftRS4_pos        LDW     mathShift           ; positive number
                    SYS     50
                    RET
%ENDS
                    
%SUB                shiftRightSgn5bit
shiftRightSgn5bit   LDWI    SYS_LSRW5_50
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS5_pos        ; check sign
                    LDWI    0xF800
                    STW     mathSign
                    LDW     mathShift
                    SYS     50                  ; shift right 5
                    ORW     mathSign            ; fix sign
                    RET

shiftRS5_pos        LDW     mathShift           ; positive number
                    SYS     50
                    RET
%ENDS   

%SUB                shiftRightSgn6bit
shiftRightSgn6bit   LDWI    SYS_LSRW6_48
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS6_pos        ; check sign
                    LDWI    0xFC00
                    STW     mathSign
                    LDW     mathShift
                    SYS     48                  ; shift right 6
                    ORW     mathSign            ; fix sign
                    RET

shiftRS6_pos        LDW     mathShift           ; positive number
                    SYS     48
                    RET
%ENDS   
    
%SUB                shiftRightSgn7bit
shiftRightSgn7bit   LDWI    SYS_LSRW7_30
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS7_pos        ; check sign
                    LDWI    0xFE00
                    STW     mathSign
                    LDW     mathShift
                    SYS     30                  ; shift right 7
                    ORW     mathSign            ; fix sign
                    RET

shiftRS7_pos        LDW     mathShift           ; positive number
                    SYS     30
                    RET
%ENDS   
    
%SUB                shiftRightSgn8bit
shiftRightSgn8bit   LDWI    SYS_LSRW8_24
                    STW     giga_sysFn
                    LD      mathShift + 1
                    ANDI    0x80
                    BEQ     shiftRS8_pos        ; check sign
                    LDWI    0xFF00
                    STW     mathSign
                    LDW     mathShift
                    SYS     28                  ; shift right 8
                    ORW     mathSign            ; fix sign
                    RET

shiftRS8_pos        LDW     mathShift           ; positive number
                    SYS     28
                    RET
%ENDS