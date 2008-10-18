; configuration
CONFIG_11 := 1
CONFIG_11A := 1
CONFIG_2 := 1
CONFIG_2A := 1
CONFIG_2B := 1

CONFIG_NO_POKE := 1
CONFIG_NO_READ_Y_IS_ZERO_HACK := 1
CONFIG_SAFE_NAMENOTFOUND := 1
CONFIG_SCRTCH_ORDER := 3
CONFIG_SMALL := 1
; INPUTBUFFER > $0100

; zero page
ZP_START0 = $00
ZP_START0A = $0F
ZP_START1 = $06
ZP_START2 = $15

JMPADRS         := $0093
LOWTRX          := $0094                        ; $AB also EXPSGN?

;POSX            := $0010
;LINNUM          := $0013

; overrides
Z17             := $06FC
Z18             := $06FD


TXPSV           := $0049

CONFIG_NO_INPUTBUFFER_ZP := 1

INPUTBUFFER     := $0700
INPUTBUFFERX    := $0700

Z96				:= $0096

; magic memory locations
L06FE			:= $06FE
L6874			:= $6874


; constants
STACK_TOP		:= $FE
SPACE_FOR_GOSUB := $49
CRLF_1 := LF
CRLF_2 := CR

; memory layout
RAMSTART2		:= $0300
CONST_MEMSIZ	:= $3FFF

; monitor functions
MONCOUT         := $FDFA
LC000			:= $C000
LC009			:= $C009
LDE24			:= $DE24
LDE42			:= $DE42 ; PRIMM ?
LDE48			:= $DE48
LDE53			:= $DE53
LDE7F			:= $DE7F
LDE8C			:= $DE8C


