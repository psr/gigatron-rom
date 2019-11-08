              address
              |    encoding
              |    |     instruction
              |    |     |    operands
              |    |     |    |
              V    V     V    V
              0000 0000  ld   $00         ;LEDs |OOOO|
              0001 1880  ld   $80,out
              0002 18c0  ld   $c0,out
              0003 c17c  ctrl $7c         ;SCLK=0; Disable SPI slaves; Bank=01; Enable RAM
              0004 0001  ld   $01         ;RAM test and count
.countMem0:   0005 d601  st   [$01],y
              0006 00ff  ld   $ff
              0007 6900  xora [y,$00]
              0008 ca00  st   [y,$00]
              0009 c200  st   [$00]
              000a 6900  xora [y,$00]
              000b ec0b  bne  $000b
              000c 00ff  ld   $ff
              000d 6900  xora [y,$00]
              000e ca00  st   [y,$00]
              000f 6100  xora [$00]
              0010 f014  beq  .countMem1
              0011 0101  ld   [$01]
              0012 fc05  bra  .countMem0
              0013 8200  adda ac
.countMem1:   0014 00ff  ld   $ff         ;Debounce reset button
.debounce:    0015 c200  st   [$00]
              0016 ec16  bne  $0016
              0017 a001  suba $01
              0018 0100  ld   [$00]
              0019 ec15  bne  .debounce
              001a a001  suba $01
              001b 0001  ld   $01         ;LEDs |*OOO|
              001c 1880  ld   $80,out
              001d 18c0  ld   $c0,out
              001e 0000  ld   $00         ;Collect entropy from RAM
              001f d218  st   [$18],x
              0020 d619  st   [$19],y
.initEnt0:    0021 0106  ld   [$06]
              0022 f425  bge  .initEnt1
              0023 8d00  adda [y,x]
              0024 60bf  xora $bf
.initEnt1:    0025 c206  st   [$06]
              0026 0107  ld   [$07]
              0027 f42a  bge  .initEnt2
              0028 8106  adda [$06]
              0029 60c1  xora $c1
.initEnt2:    002a c207  st   [$07]
              002b 8108  adda [$08]
              002c c208  st   [$08]
              002d 0118  ld   [$18]
              002e 8001  adda $01
              002f ec21  bne  .initEnt0
              0030 d218  st   [$18],x
              0031 0119  ld   [$19]
              0032 8001  adda $01
              0033 ec21  bne  .initEnt0
              0034 d619  st   [$19],y
              0035 0003  ld   $03         ;LEDs |**OO|
              0036 1880  ld   $80,out
              0037 18c0  ld   $c0,out
              0038 00ee  ld   $ee         ;Setup vCPU reset handler
              0039 c216  st   [$16]
              003a 9002  adda $02,x
              003b 0001  ld   $01
              003c d617  st   [$17],y
              003d dc59  st   $59,[y,x++] ;LDI
              003e dc5e  st   $5e,[y,x++] ;SYS_Reset_88
              003f dc2b  st   $2b,[y,x++] ;STW
              0040 dc22  st   $22,[y,x++] ;sysFn
              0041 dcb4  st   $b4,[y,x++] ;SYS -> SYS_Reset_88 -> SYS_Exec_88
              0042 dce2  st   $e2,[y,x++] ;270-88/2
              0043 dc00  st   $00,[y,x++]
              0044 dc00  st   $00,[y,x++]
              0045 dc00  st   $00,[y,x++]
              0046 dc00  st   $00,[y,x++] ;videoTop
              0047 0002  ld   $02         ;Active interpreter (vCPU,v6502) = vCPU
              0048 c205  st   [$05]
              0049 00ff  ld   $ff         ;Setup serial input
              004a c20e  st   [$0e]
              004b c20f  st   [$0f]
              004c c210  st   [$10]
              004d c211  st   [$11]
              004e c212  st   [$12]
              004f 0007  ld   $07         ;LEDs |***O|
              0050 1880  ld   $80,out
              0051 18c0  ld   $c0,out
              0052 0000  ld   $00
              0053 c200  st   [$00]       ;Carry lookup ([0x80] in first line of vBlank)
              0054 c202  st   [$02]
              0055 c22c  st   [$2c]
              0056 000f  ld   $0f         ;LEDs |****|
              0057 1880  ld   $80,out
              0058 18c0  ld   $c0,out
              0059 c213  st   [$13]
              005a c214  st   [$14]
              005b 1401  ld   $01,y       ;Enter video loop at vertical blank
              005c e003  jmp  y,$03
              005d c22e  st   [$2e]
SYS_Reset_88: 005e 00f8  ld   $f8         ;Set ROM type/version and clear channel mask
              005f c221  st   [$21]
              0060 0000  ld   $00
              0061 c21c  st   [$1c]       ;vSP
              0062 1401  ld   $01,y
              0063 caf9  st   [y,$f9]     ;Show all 120 pixel rows
              0064 c22c  st   [$2c]       ;soundTimer
              0065 c21a  st   [$1a]       ;vLR
              0066 0002  ld   $02
              0067 c21b  st   [$1b]
              0068 00f6  ld   $f6         ;Video mode 3 (fast)
              0069 c20a  st   [$0a]
              006a c20b  st   [$0b]
              006b c20c  st   [$0c]
              006c 00ad  ld   $ad         ;SYS_Exec_88
              006d c222  st   [$22]
              006e 0055  ld   $55         ;Reset.gt1 from EPROM
              006f c224  st   [$24]
              0070 0018  ld   $18
              0071 c225  st   [$25]
              0072 0116  ld   [$16]       ;Force second SYS call
              0073 a002  suba $02
              0074 c216  st   [$16]
              0075 0200  nop
              0076 1403  ld   $03,y
              0077 e0cb  jmp  y,$cb
              0078 00ea  ld   $ea
              0079 0200  nop              ;7 fillers
              007a 0200  nop
              007b 0200  nop
              * 7 times
              0080 1403  ld   $03,y
              0081 e0cb  jmp  y,$cb
              0082 00f6  ld   $f6
              0083 1403  ld   $03,y
              0084 e0cb  jmp  y,$cb
              0085 00f6  ld   $f6
              0086 1403  ld   $03,y
              0087 e0cb  jmp  y,$cb
              0088 00f6  ld   $f6
              0089 1403  ld   $03,y
              008a e0cb  jmp  y,$cb
              008b 00f6  ld   $f6
              008c 1403  ld   $03,y
              008d e0cb  jmp  y,$cb
              008e 00f6  ld   $f6
              008f 1403  ld   $03,y
              0090 e0cb  jmp  y,$cb
              0091 00f6  ld   $f6
              0092 1403  ld   $03,y
              0093 e0cb  jmp  y,$cb
              0094 00f6  ld   $f6
              0095 1403  ld   $03,y
              0096 e0cb  jmp  y,$cb
              0097 00f6  ld   $f6
              0098 1403  ld   $03,y
              0099 e0cb  jmp  y,$cb
              009a 00f6  ld   $f6
              009b 1403  ld   $03,y
              009c e0cb  jmp  y,$cb
              009d 00f6  ld   $f6
              009e 1403  ld   $03,y
              009f e0cb  jmp  y,$cb
              00a0 00f6  ld   $f6
              00a1 1403  ld   $03,y
              00a2 e0cb  jmp  y,$cb
              00a3 00f6  ld   $f6
              00a4 1403  ld   $03,y
              00a5 e0cb  jmp  y,$cb
              00a6 00f6  ld   $f6
              00a7 1403  ld   $03,y
              00a8 e0cb  jmp  y,$cb
              00a9 00f6  ld   $f6
              00aa 1403  ld   $03,y
              00ab e0cb  jmp  y,$cb
              00ac 00f6  ld   $f6
SYS_Exec_88:  00ad 1411  ld   $11,y
              00ae e0fc  jmp  y,$fc
              00af 0000  ld   $00
              00b0 1403  ld   $03,y
              00b1 e0cb  jmp  y,$cb
              00b2 00f6  ld   $f6
              00b3 1403  ld   $03,y
              00b4 e0cb  jmp  y,$cb
              00b5 00f6  ld   $f6
              00b6 1403  ld   $03,y
              00b7 e0cb  jmp  y,$cb
              00b8 00f6  ld   $f6
              00b9 1403  ld   $03,y
              00ba e0cb  jmp  y,$cb
              00bb 00f6  ld   $f6
              00bc 1403  ld   $03,y
              00bd e0cb  jmp  y,$cb
              00be 00f6  ld   $f6
              00bf 1403  ld   $03,y
              00c0 e0cb  jmp  y,$cb
              00c1 00f6  ld   $f6
              00c2 1403  ld   $03,y
              00c3 e0cb  jmp  y,$cb
              00c4 00f6  ld   $f6
              00c5 1403  ld   $03,y
              00c6 e0cb  jmp  y,$cb
              00c7 00f6  ld   $f6
              00c8 1403  ld   $03,y
              00c9 e0cb  jmp  y,$cb
              00ca 00f6  ld   $f6
              00cb 1403  ld   $03,y
              00cc e0cb  jmp  y,$cb
              00cd 00f6  ld   $f6
              00ce 1403  ld   $03,y
              00cf e0cb  jmp  y,$cb
              00d0 00f6  ld   $f6
              00d1 1403  ld   $03,y
              00d2 e0cb  jmp  y,$cb
              00d3 00f6  ld   $f6
              00d4 1403  ld   $03,y
              00d5 e0cb  jmp  y,$cb
              00d6 00f6  ld   $f6
              00d7 1403  ld   $03,y
              00d8 e0cb  jmp  y,$cb
              00d9 00f6  ld   $f6
              00da 1403  ld   $03,y
              00db e0cb  jmp  y,$cb
              00dc 00f6  ld   $f6
              00dd 1403  ld   $03,y
              00de e0cb  jmp  y,$cb
              00df 00f6  ld   $f6
              00e0 1403  ld   $03,y
              00e1 e0cb  jmp  y,$cb
              00e2 00f6  ld   $f6
              00e3 1403  ld   $03,y
              00e4 e0cb  jmp  y,$cb
              00e5 00f6  ld   $f6
              00e6 1403  ld   $03,y
              00e7 e0cb  jmp  y,$cb
              00e8 00f6  ld   $f6
              00e9 1403  ld   $03,y
              00ea e0cb  jmp  y,$cb
              00eb 00f6  ld   $f6
              00ec 1403  ld   $03,y
              00ed e0cb  jmp  y,$cb
              00ee 00f6  ld   $f6
              00ef 1403  ld   $03,y
              00f0 e0cb  jmp  y,$cb
              00f1 00f6  ld   $f6
              00f2 0200  nop              ;2 fillers
              00f3 0200  nop
SYS_Out_22:   00f4 1924  ld   [$24],out
              00f5 0200  nop
              00f6 1403  ld   $03,y
              00f7 e0cb  jmp  y,$cb
              00f8 00f5  ld   $f5
SYS_In_24:    00f9 c318  st   in,[$18]
              00fa 0000  ld   $00
              00fb c219  st   [$19]
              00fc 0200  nop
              00fd 1403  ld   $03,y
              00fe e0cb  jmp  y,$cb
              00ff 00f4  ld   $f4
videoZ:       0100 1505  ld   [$05],y     ;Run vCPU for 280 cycles gross (---- novideo)
              0101 e0ff  jmp  y,$ff
              0102 0078  ld   $78
startVideo:   0103 00c0  ld   $c0
vBlankStart:  0104 c21f  st   [$1f]       ;Start of vertical blank interval
              0105 0080  ld   $80
              0106 c220  st   [$20]
              0107 00b3  ld   $b3
              0108 c209  st   [$09]
              0109 0001  ld   $01         ;Reinitialize carry lookup, for robustness
              010a c280  st   [$80]
              010b 810e  adda [$0e]       ;Frame counter
              010c c20e  st   [$0e]
              010d 6107  xora [$07]       ;Mix entropy
              010e 610f  xora [$0f]
              010f 8106  adda [$06]
              0110 c206  st   [$06]
              0111 8108  adda [$08]
              0112 c208  st   [$08]
              0113 e816  blt  $0116
              0114 fc17  bra  $0117
              0115 6053  xora $53
              0116 606c  xora $6c
              0117 8107  adda [$07]
              0118 c207  st   [$07]
              0119 012d  ld   [$2d]       ;Blinkenlight sequencer
              011a f01d  beq  $011d
              011b fc1e  bra  $011e
              011c a001  suba $01
              011d 012f  ld   [$2f]
              011e c22d  st   [$2d]
              011f f022  beq  $0122
              0120 fc23  bra  $0123
              0121 0000  ld   $00
              0122 0001  ld   $01
              0123 812e  adda [$2e]
              0124 ec27  bne  $0127
              0125 fc28  bra  $0128
              0126 00e8  ld   $e8
              0127 e42c  bgt  .leds#65
              0128 c22e  st   [$2e]
              0129 8048  adda $48
              012a fe00  bra  ac
              012b fc48  bra  .leds#69
.leds#65:     012c 000f  ld   $0f
              012d c22e  st   [$2e]
              012e fc48  bra  .leds#69
              012f 2114  anda [$14]
              0130 000f  ld   $0f         ;LEDs |****|
              0131 0007  ld   $07         ;LEDs |***O|
              0132 0003  ld   $03         ;LEDs |**OO|
              0133 0001  ld   $01         ;LEDs |*OOO|
              0134 0002  ld   $02         ;LEDs |O*OO|
              0135 0004  ld   $04         ;LEDs |OO*O|
              0136 0008  ld   $08         ;LEDs |OOO*|
              0137 0004  ld   $04         ;LEDs |OO*O|
              0138 0002  ld   $02         ;LEDs |O*OO|
              0139 0001  ld   $01         ;LEDs |*OOO|
              013a 0003  ld   $03         ;LEDs |**OO|
              013b 0007  ld   $07         ;LEDs |***O|
              013c 000f  ld   $0f         ;LEDs |****|
              013d 000e  ld   $0e         ;LEDs |O***|
              013e 000c  ld   $0c         ;LEDs |OO**|
              013f 0008  ld   $08         ;LEDs |OOO*|
              0140 0004  ld   $04         ;LEDs |OO*O|
              0141 0002  ld   $02         ;LEDs |O*OO|
              0142 0001  ld   $01         ;LEDs |*OOO|
              0143 0002  ld   $02         ;LEDs |O*OO|
              0144 0004  ld   $04         ;LEDs |OO*O|
              0145 0008  ld   $08         ;LEDs |OOO*|
              0146 000c  ld   $0c         ;LEDs |OO**|
              0147 000e  ld   $0e         ;LEDs |O***|
.leds#69:     0148 c214  st   [$14]
              0149 0010  ld   $10
              014a c20d  st   [$0d]
              014b 0050  ld   $50         ;Run vCPU for 114 cycles gross (---D line 0)
              014c c21e  st   [$1e]
              014d 1505  ld   [$05],y
              014e e0ff  jmp  y,$ff
              014f 0024  ld   $24
              0150 0121  ld   [$21]       ;Normalize channelMask, for robustness
              0151 20fb  anda $fb
              0152 c221  st   [$21]
              0153 012c  ld   [$2c]       ;Sound on/off
              0154 ec57  bne  $0157
              0155 fc58  bra  $0158
              0156 0000  ld   $00
              0157 00f0  ld   $f0
              0158 4114  ora  [$14]
              0159 c214  st   [$14]
              015a 012c  ld   [$2c]       ;Sound timer
              015b f05e  beq  $015e
              015c fc5f  bra  $015f
              015d a001  suba $01
              015e 0000  ld   $00
              015f c22c  st   [$2c]
              0160 191f  ld   [$1f],out   ;<New scan line start>
sound1:       0161 0102  ld   [$02]       ;Advance to next sound channel
              0162 2121  anda [$21]
              0163 8001  adda $01
              0164 1920  ld   [$20],out   ;Start horizontal pulse
              0165 d602  st   [$02],y
              0166 007f  ld   $7f         ;Update sound channel
              0167 29fe  anda [y,$fe]
              0168 89fc  adda [y,$fc]
              0169 cafe  st   [y,$fe]
              016a 3080  anda $80,x
              016b 0500  ld   [x]
              016c 89ff  adda [y,$ff]
              016d 89fd  adda [y,$fd]
              016e caff  st   [y,$ff]
              016f 20fc  anda $fc
              0170 69fb  xora [y,$fb]
              0171 1200  ld   ac,x
              0172 09fa  ld   [y,$fa]
              0173 1407  ld   $07,y
              0174 8d00  adda [y,x]
              0175 e878  blt  $0178
              0176 fc79  bra  $0179
              0177 203f  anda $3f
              0178 003f  ld   $3f
              0179 8103  adda [$03]
              017a c203  st   [$03]
              017b 0113  ld   [$13]       ;Gets copied to XOUT
              017c 1409  ld   $09,y
              017d 191f  ld   [$1f],out   ;End horizontal pulse
              017e 0109  ld   [$09]
              017f f4ac  bge  .vBlankLast#32
              0180 8002  adda $02
              0181 c209  st   [$09]
              0182 a0bd  suba $bd         ;Prepare sync values
              0183 ec88  bne  .prepSync36
              0184 a10d  suba [$0d]
              0185 0040  ld   $40
              0186 fc8d  bra  .prepSync39
              0187 c21f  st   [$1f]
.prepSync36:  0188 ec8c  bne  .prepSync38
              0189 00c0  ld   $c0
              018a fc8e  bra  .prepSync40
              018b c21f  st   [$1f]
.prepSync38:  018c 011f  ld   [$1f]
.prepSync39:  018d 0200  nop
.prepSync40:  018e 6040  xora $40
              018f c220  st   [$20]
              0190 0109  ld   [$09]       ;Capture serial input
              0191 60cf  xora $cf
              0192 ec95  bne  $0195
              0193 fc96  bra  $0196
              0194 c30f  st   in,[$0f]
              0195 c000  st   $00,[$00]   ;Reinitialize carry lookup, for robustness
              0196 0109  ld   [$09]
              0197 2006  anda $06
              0198 f0a1  beq  vBlankSample
              0199 0103  ld   [$03]
vBlankNormal: 019a 009f  ld   $9f         ;Run vCPU for 148 cycles gross (AB-D line 1-36)
              019b c21e  st   [$1e]
              019c 1505  ld   [$05],y
              019d e0ff  jmp  y,$ff
              019e 0035  ld   $35
              019f fc61  bra  sound1
              01a0 191f  ld   [$1f],out   ;<New scan line start>
vBlankSample: 01a1 400f  ora  $0f         ;New sound sample is ready
              01a2 2114  anda [$14]
              01a3 c213  st   [$13]
              01a4 c003  st   $03,[$03]   ;Reset for next sample
              01a5 00aa  ld   $aa         ;Run vCPU for 144 cycles gross (--C- line 3-39)
              01a6 c21e  st   [$1e]
              01a7 1505  ld   [$05],y
              01a8 e0ff  jmp  y,$ff
              01a9 0033  ld   $33
              01aa fc61  bra  sound1
              01ab 191f  ld   [$1f],out   ;<New scan line start>
.vBlankLast#32:
              01ac e0de  jmp  y,$de       ;Jump out of page for space reasons
              01ad 1401  ld   $01,y
vBlankLast#52:
              01ae 0111  ld   [$11]       ;Check [Start] for soft reset
              01af 60ef  xora $ef
              01b0 ecb9  bne  .restart#56
              01b1 0112  ld   [$12]
              01b2 a001  suba $01         ;Pressed and counting
              01b3 c212  st   [$12]
              01b4 207f  anda $7f
              01b5 f0c1  beq  .restart#61
              01b6 00ee  ld   $ee
              01b7 fcc0  bra  .restart#63
              01b8 fcbf  bra  .restart#64
.restart#56:  01b9 0001  ld   $01         ;Wait 6 cycles
              01ba ecba  bne  $01ba
              01bb a001  suba $01
              01bc 0200  nop
              01bd 0080  ld   $80         ;Not pressed, reset the timer
              01be c212  st   [$12]
.restart#64:  01bf fcc6  bra  .restart#66
.restart#63:  01c0 0200  nop
.restart#61:  01c1 c216  st   [$16]       ;Point vPC at vReset
              01c2 0001  ld   $01
              01c3 c217  st   [$17]
              01c4 0002  ld   $02         ;Set active interpreter to vCPU
              01c5 c205  st   [$05]
.restart#66:  01c6 0111  ld   [$11]       ;Check [Select] to switch modes
              01c7 60df  xora $df
              01c8 ecdd  bne  .select#70
              01c9 010b  ld   [$0b]
              01ca e8d0  blt  .select#72
              01cb 010a  ld   [$0a]
              01cc c20b  st   [$0b]
              01cd 010c  ld   [$0c]
              01ce c20a  st   [$0a]
              01cf fcd5  bra  .select#77
.select#72:   01d0 00f6  ld   $f6
              01d1 000a  ld   $0a
              01d2 c20b  st   [$0b]
              01d3 c20a  st   [$0a]
              01d4 0200  nop
.select#77:   01d5 c20c  st   [$0c]
              01d6 0035  ld   $35         ;Wait 110 cycles
              01d7 ecd7  bne  $01d7
              01d8 a001  suba $01
              01d9 0200  nop
              01da c211  st   [$11]
              01db fce5  bra  vBlankEnd#191
              01dc 0000  ld   $00
.select#70:   01dd 0102  ld   [$02]       ;Normalize channel, for robustness
              01de 2003  anda $03
              01df c202  st   [$02]
              01e0 00e5  ld   $e5         ;Run vCPU for 118 cycles gross (---D line 40)
              01e1 c21e  st   [$1e]
              01e2 1505  ld   [$05],y
              01e3 e0ff  jmp  y,$ff
              01e4 0026  ld   $26
vBlankEnd#191:
              01e5 1401  ld   $01,y
              01e6 09f9  ld   [y,$f9]
              01e7 c209  st   [$09]
              01e8 c21f  st   [$1f]
              01e9 ecec  bne  $01ec
              01ea fced  bra  $01ed
              01eb 0001  ld   $01
              01ec 00ec  ld   $ec
              01ed c20d  st   [$0d]
              01ee 0102  ld   [$02]
              01ef 2121  anda [$21]       ;<New scan line start>
              01f0 8001  adda $01
              01f1 1402  ld   $02,y
              01f2 e0b1  jmp  y,$b1
              01f3 1880  ld   $80,out
              01f4 0200  nop              ;11 fillers
              01f5 0200  nop
              01f6 0200  nop
              * 11 times
              01ff fcae  bra  sound3      ;<New scan line start>
              0200 0102  ld   [$02]
videoA:       0201 00ca  ld   $ca         ;1st scanline of 4 (always visible)
              0202 c20d  st   [$0d]
              0203 1401  ld   $01,y
              0204 1109  ld   [$09],x
              0205 0d00  ld   [y,x]
              0206 de00  st   [y,x++]
              0207 c220  st   [$20]
              0208 0d00  ld   [y,x]
              0209 911f  adda [$1f],x
pixels:       020a 1520  ld   [$20],y
              020b 00c0  ld   $c0
              020c 5d00  ora  [y,x++],out ;Pixel burst
              020d 5d00  ora  [y,x++],out
              020e 5d00  ora  [y,x++],out
              * 160 times
              02ac 18c0  ld   $c0,out     ;<New scan line start>
              02ad 0102  ld   [$02]       ;Advance to next sound channel
sound3:       02ae 2121  anda [$21]
              02af 8001  adda $01
              02b0 1880  ld   $80,out     ;Start horizontal pulse
sound2:       02b1 d602  st   [$02],y
              02b2 007f  ld   $7f
              02b3 29fe  anda [y,$fe]
              02b4 89fc  adda [y,$fc]
              02b5 cafe  st   [y,$fe]
              02b6 3080  anda $80,x
              02b7 0500  ld   [x]
              02b8 89ff  adda [y,$ff]
              02b9 89fd  adda [y,$fd]
              02ba caff  st   [y,$ff]
              02bb 20fc  anda $fc
              02bc 69fb  xora [y,$fb]
              02bd 1200  ld   ac,x
              02be 09fa  ld   [y,$fa]
              02bf 1407  ld   $07,y
              02c0 8d00  adda [y,x]
              02c1 e8c4  blt  $02c4
              02c2 fcc5  bra  $02c5
              02c3 203f  anda $3f
              02c4 003f  ld   $3f
              02c5 8103  adda [$03]
              02c6 c203  st   [$03]
              02c7 0113  ld   [$13]       ;Gets copied to XOUT
              02c8 fd0d  bra  [$0d]
              02c9 18c0  ld   $c0,out     ;End horizontal pulse
videoB:       02ca 00d3  ld   $d3         ;2nd scanline of 4
              02cb c20d  st   [$0d]
              02cc 1401  ld   $01,y
              02cd 0109  ld   [$09]
              02ce 9001  adda $01,x
              02cf 011f  ld   [$1f]
              02d0 8d00  adda [y,x]
              02d1 fd0a  bra  [$0a]
              02d2 d21f  st   [$1f],x
videoC:       02d3 00dc  ld   $dc         ;3rd scanline of 4
              02d4 c20d  st   [$0d]
              02d5 0103  ld   [$03]       ;New sound sample is ready
              02d6 400f  ora  $0f
              02d7 2114  anda [$14]
              02d8 c213  st   [$13]
              02d9 c003  st   $03,[$03]   ;Reset for next sample
              02da fd0b  bra  [$0b]
              02db 111f  ld   [$1f],x
videoD:       02dc 111f  ld   [$1f],x     ;4th scanline of 4
              02dd 0109  ld   [$09]
              02de a0ee  suba $ee
              02df f0e5  beq  .lastpixels#34
              02e0 80f0  adda $f0         ;More pixel rows to go
              02e1 c209  st   [$09]
              02e2 0001  ld   $01
              02e3 fd0c  bra  [$0c]
              02e4 c20d  st   [$0d]
.lastpixels#34:
              02e5 c003  st   $03,[$03]   ;Sound continuity
              02e6 00e9  ld   $e9         ;No more pixel rows to go
              02e7 fd0c  bra  [$0c]
              02e8 c20d  st   [$0d]
videoE:       02e9 1401  ld   $01,y       ;Return to vertical blank interval
              02ea e004  jmp  y,$04
              02eb 00c0  ld   $c0
videoF:       02ec 0120  ld   [$20]       ;Completely black pixel row
              02ed 8080  adda $80
              02ee d220  st   [$20],x
              02ef 011f  ld   [$1f]
              02f0 a500  suba [x]
              02f1 f0f4  beq  .videoF#36
              02f2 c21f  st   [$1f]
              02f3 fcf6  bra  nopixels
.videoF#36:   02f4 0001  ld   $01
              02f5 c20d  st   [$0d]
nopixels:     02f6 00ff  ld   $ff         ;Run vCPU for 162 cycles gross (ABCD line 40-520)
              02f7 c21e  st   [$1e]
              02f8 1505  ld   [$05],y
              02f9 e0ff  jmp  y,$ff
              02fa 003c  ld   $3c
              02fb 0200  nop
              02fc 0200  nop
              02fd 0200  nop
              02fe 0200  nop
ENTER:        02ff fc03  bra  .next2      ;vCPU interpreter
              0300 1517  ld   [$17],y
NEXT:         0301 8115  adda [$15]       ;Track elapsed ticks
              0302 e80b  blt  EXIT        ;Escape near time out
.next2:       0303 c215  st   [$15]
              0304 0116  ld   [$16]       ;Advance vPC
              0305 8002  adda $02
              0306 d216  st   [$16],x
              0307 0d00  ld   [y,x]       ;Fetch opcode
              0308 de00  st   [y,x++]
              0309 fe00  bra  ac          ;Dispatch
              030a 0d00  ld   [y,x]       ;Prefetch operand
EXIT:         030b 800e  adda $0e
              030c e40c  bgt  $030c       ;Resync
              030d a001  suba $01
              030e 1401  ld   $01,y
              030f e11e  jmp  y,[$1e]     ;To video driver
              0310 0000  ld   $00
LDWI:         0311 c218  st   [$18]
              0312 de00  st   [y,x++]
              0313 0d00  ld   [y,x]
              0314 c219  st   [$19]
              0315 0116  ld   [$16]
              0316 8001  adda $01
              0317 c216  st   [$16]
              0318 00f6  ld   $f6
              0319 fc01  bra  NEXT
LD:           031a 1200  ld   ac,x
              031b 0500  ld   [x]
              031c 1404  ld   $04,y
              031d e013  jmp  y,$13
              031e c218  st   [$18]
CMPHS_DEVROM: 031f 140b  ld   $0b,y
              0320 e0ea  jmp  y,$ea
LDW:          0321 1200  ld   ac,x
              0322 8001  adda $01
              0323 c21d  st   [$1d]
              0324 0500  ld   [x]
              0325 c218  st   [$18]
              0326 111d  ld   [$1d],x
              0327 0500  ld   [x]
              0328 c219  st   [$19]
              0329 fc01  bra  NEXT
              032a 00f6  ld   $f6
STW:          032b 1200  ld   ac,x
              032c 8001  adda $01
              032d c21d  st   [$1d]
              032e 0118  ld   [$18]
              032f c600  st   [x]
              0330 111d  ld   [$1d],x
              0331 0119  ld   [$19]
              0332 c600  st   [x]
              0333 fc01  bra  NEXT
              0334 00f6  ld   $f6
BCC:          0335 0119  ld   [$19]
              0336 ec40  bne  .bcc#13
              0337 c21d  st   [$1d]
              0338 0118  ld   [$18]
              0339 f043  beq  .bcc#16
              033a 0001  ld   $01
              033b c21d  st   [$1d]
              033c 0d00  ld   [y,x]
.bcc#18:      033d fe00  bra  ac
              033e 011d  ld   [$1d]
EQ:           033f ec45  bne  .bcc#22
.bcc#13:      0340 f048  beq  .bcc#23     ;AC=0 in EQ, AC!=0 from BCC...
              0341 0d00  ld   [y,x]
              0342 0200  nop
.bcc#16:      0343 fc3d  bra  .bcc#18
              0344 0d00  ld   [y,x]
.bcc#22:      0345 0116  ld   [$16]       ;False condition
              0346 fc4a  bra  .bcc#25
              0347 8001  adda $01
.bcc#23:      0348 de00  st   [y,x++]     ;True condition
              0349 0d00  ld   [y,x]
.bcc#25:      034a c216  st   [$16]
              034b fc01  bra  NEXT
              034c 00f2  ld   $f2
GT:           034d f845  ble  .bcc#22
              034e e448  bgt  .bcc#23
              034f 0d00  ld   [y,x]
LT:           0350 f445  bge  .bcc#22
              0351 e848  blt  .bcc#23
              0352 0d00  ld   [y,x]
GE:           0353 e845  blt  .bcc#22
              0354 f448  bge  .bcc#23
              0355 0d00  ld   [y,x]
LE:           0356 e445  bgt  .bcc#22
              0357 f848  ble  .bcc#23
              0358 0d00  ld   [y,x]
LDI:          0359 c218  st   [$18]
              035a 0000  ld   $00
              035b c219  st   [$19]
              035c 00f8  ld   $f8
              035d fc01  bra  NEXT
ST:           035e 1200  ld   ac,x
              035f 0118  ld   [$18]
              0360 c600  st   [x]
              0361 00f8  ld   $f8
              0362 fc01  bra  NEXT
POP:          0363 111c  ld   [$1c],x
              0364 0500  ld   [x]
              0365 c21a  st   [$1a]
              0366 011c  ld   [$1c]
              0367 9001  adda $01,x
              0368 0500  ld   [x]
              0369 c21b  st   [$1b]
              036a 011c  ld   [$1c]
              036b 8002  adda $02
              036c c21c  st   [$1c]
.pop#20:      036d 0116  ld   [$16]
              036e a001  suba $01
              036f c216  st   [$16]
              0370 00f3  ld   $f3
              0371 fc01  bra  NEXT
NE:           0372 f045  beq  .bcc#22
              0373 ec48  bne  .bcc#23
              0374 0d00  ld   [y,x]
PUSH:         0375 011c  ld   [$1c]
              0376 b001  suba $01,x
              0377 011b  ld   [$1b]
              0378 c600  st   [x]
              0379 011c  ld   [$1c]
              037a a002  suba $02
              037b d21c  st   [$1c],x
              037c 011a  ld   [$1a]
              037d fc6d  bra  .pop#20
              037e c600  st   [x]
LUP:          037f 1519  ld   [$19],y
              0380 e0fb  jmp  y,$fb       ;Trampoline offset
              0381 8118  adda [$18]
ANDI:         0382 1404  ld   $04,y
              0383 e011  jmp  y,$11
              0384 2118  anda [$18]
CALLI_DEVROM: 0385 140b  ld   $0b,y
              0386 e0de  jmp  y,$de
              0387 0116  ld   [$16]
ORI:          0388 4118  ora  [$18]
              0389 c218  st   [$18]
              038a fc01  bra  NEXT
              038b 00f9  ld   $f9
XORI:         038c 6118  xora [$18]
              038d c218  st   [$18]
              038e fc01  bra  NEXT
              038f 00f9  ld   $f9
BRA:          0390 c216  st   [$16]
              0391 00f9  ld   $f9
              0392 fc01  bra  NEXT
INC:          0393 1200  ld   ac,x
              0394 1404  ld   $04,y
              0395 e0f5  jmp  y,$f5
              0396 0001  ld   $01
CMPHU_DEVROM: 0397 140b  ld   $0b,y
              0398 e0f6  jmp  y,$f6
ADDW:         0399 1200  ld   ac,x
              039a 8001  adda $01
              039b c21d  st   [$1d]
              039c 0118  ld   [$18]
              039d 8500  adda [x]
              039e c218  st   [$18]
              039f e8a3  blt  .addw#18
              03a0 a500  suba [x]
              03a1 fca5  bra  .addw#20
              03a2 4500  ora  [x]
.addw#18:     03a3 2500  anda [x]
              03a4 0200  nop
.addw#20:     03a5 3080  anda $80,x
              03a6 0500  ld   [x]
              03a7 8119  adda [$19]
              03a8 111d  ld   [$1d],x
              03a9 8500  adda [x]
              03aa c219  st   [$19]
              03ab fc01  bra  NEXT
              03ac 00f2  ld   $f2
PEEK:         03ad 1404  ld   $04,y
              03ae e062  jmp  y,$62
.sys#13:      03af 0116  ld   [$16]       ;Retry until sufficient time
              03b0 a002  suba $02
              03b1 c216  st   [$16]
              03b2 fccb  bra  REENTER
              03b3 00f6  ld   $f6
SYS:          03b4 8115  adda [$15]
              03b5 e8af  blt  .sys#13
              03b6 1523  ld   [$23],y
              03b7 e122  jmp  y,[$22]
SUBW:         03b8 1200  ld   ac,x
              03b9 8001  adda $01
              03ba c21d  st   [$1d]
              03bb 0118  ld   [$18]
              03bc e8c1  blt  .subw#16
              03bd a500  suba [x]
              03be c218  st   [$18]
              03bf fcc4  bra  .subw#19
              03c0 4500  ora  [x]
.subw#16:     03c1 c218  st   [$18]
              03c2 2500  anda [x]
              03c3 0200  nop
.subw#19:     03c4 3080  anda $80,x
              03c5 0119  ld   [$19]
              03c6 a500  suba [x]
              03c7 111d  ld   [$1d],x
              03c8 a500  suba [x]
              03c9 c219  st   [$19]
REENTER_28:   03ca 00f2  ld   $f2
REENTER:      03cb fc01  bra  NEXT        ;Return from SYS calls
              03cc 1517  ld   [$17],y
DEF:          03cd 1404  ld   $04,y
              03ce e007  jmp  y,$07
CALL:         03cf c21d  st   [$1d]
              03d0 0116  ld   [$16]
              03d1 8002  adda $02         ;Point to instruction after CALL
              03d2 c21a  st   [$1a]
              03d3 0117  ld   [$17]
              03d4 c21b  st   [$1b]
              03d5 111d  ld   [$1d],x
              03d6 0500  ld   [x]
              03d7 a002  suba $02         ;Because NEXT will add 2
              03d8 c216  st   [$16]
              03d9 011d  ld   [$1d]
              03da 9001  adda $01,x
              03db 0500  ld   [x]
              03dc d617  st   [$17],y
              03dd fc01  bra  NEXT
              03de 00f3  ld   $f3
ALLOC:        03df 811c  adda [$1c]
              03e0 c21c  st   [$1c]
              03e1 fc01  bra  NEXT
              03e2 00f9  ld   $f9
ADDI:         03e3 1404  ld   $04,y
              03e4 e018  jmp  y,$18
              03e5 c21d  st   [$1d]
SUBI:         03e6 1404  ld   $04,y
              03e7 e026  jmp  y,$26
              03e8 c21d  st   [$1d]
LSLW:         03e9 1404  ld   $04,y
              03ea e035  jmp  y,$35
              03eb 0118  ld   [$18]
STLW:         03ec 1404  ld   $04,y
              03ed e041  jmp  y,$41
LDLW:         03ee 1404  ld   $04,y
              03ef e04c  jmp  y,$4c
POKE:         03f0 1404  ld   $04,y
              03f1 e057  jmp  y,$57
              03f2 c21d  st   [$1d]
DOKE:         03f3 1404  ld   $04,y
              03f4 e06d  jmp  y,$6d
              03f5 c21d  st   [$1d]
DEEK:         03f6 1404  ld   $04,y
              03f7 e07a  jmp  y,$7a
ANDW:         03f8 1404  ld   $04,y
              03f9 e086  jmp  y,$86
ORW:          03fa 1404  ld   $04,y
              03fb e091  jmp  y,$91
XORW:         03fc 1404  ld   $04,y
              03fd e09c  jmp  y,$9c
              03fe c21d  st   [$1d]
RET:          03ff 011a  ld   [$1a]
              0400 a002  suba $02
              0401 c216  st   [$16]
              0402 011b  ld   [$1b]
              0403 c217  st   [$17]
              0404 1403  ld   $03,y
              0405 e0cb  jmp  y,$cb
              0406 00f6  ld   $f6
def:          0407 0116  ld   [$16]
              0408 8002  adda $02
              0409 c218  st   [$18]
              040a 0117  ld   [$17]
              040b c219  st   [$19]
              040c 011d  ld   [$1d]
              040d c216  st   [$16]
              040e 1403  ld   $03,y
              040f 00f3  ld   $f3
              0410 e0cb  jmp  y,$cb
andi:         0411 0200  nop
              0412 c218  st   [$18]
ld:           0413 0000  ld   $00
              0414 c219  st   [$19]
              0415 1403  ld   $03,y
              0416 e0cb  jmp  y,$cb
              0417 00f5  ld   $f5
addi:         0418 8118  adda [$18]
              0419 c218  st   [$18]
              041a e81e  blt  .addi#17
              041b a11d  suba [$1d]
              041c fc20  bra  .addi#19
              041d 411d  ora  [$1d]
.addi#17:     041e 211d  anda [$1d]
              041f 0200  nop
.addi#19:     0420 3080  anda $80,x
              0421 0500  ld   [x]
              0422 8119  adda [$19]
              0423 1403  ld   $03,y
              0424 e0ca  jmp  y,$ca
              0425 c219  st   [$19]
subi:         0426 0118  ld   [$18]
              0427 e82c  blt  .subi#16
              0428 a11d  suba [$1d]
              0429 c218  st   [$18]
              042a fc2f  bra  .subi#19
              042b 411d  ora  [$1d]
.subi#16:     042c c218  st   [$18]
              042d 211d  anda [$1d]
              042e 0200  nop
.subi#19:     042f 3080  anda $80,x
              0430 0119  ld   [$19]
              0431 a500  suba [x]
              0432 1403  ld   $03,y
              0433 e0ca  jmp  y,$ca
              0434 c219  st   [$19]
lslw:         0435 3080  anda $80,x
              0436 8118  adda [$18]
              0437 c218  st   [$18]
              0438 0500  ld   [x]
              0439 8119  adda [$19]
              043a 8119  adda [$19]
              043b c219  st   [$19]
              043c 0116  ld   [$16]
              043d a001  suba $01
              043e 1403  ld   $03,y
              043f e0ca  jmp  y,$ca
              0440 c216  st   [$16]
stlw:         0441 811c  adda [$1c]
              0442 c21d  st   [$1d]
              0443 9001  adda $01,x
              0444 0119  ld   [$19]
              0445 c600  st   [x]
              0446 111d  ld   [$1d],x
              0447 0118  ld   [$18]
              0448 c600  st   [x]
              0449 1403  ld   $03,y
              044a e0cb  jmp  y,$cb
              044b 00f3  ld   $f3
ldlw:         044c 811c  adda [$1c]
              044d c21d  st   [$1d]
              044e 9001  adda $01,x
              044f 0500  ld   [x]
              0450 c219  st   [$19]
              0451 111d  ld   [$1d],x
              0452 0500  ld   [x]
              0453 c218  st   [$18]
              0454 1403  ld   $03,y
              0455 e0cb  jmp  y,$cb
              0456 00f3  ld   $f3
poke:         0457 9001  adda $01,x
              0458 0500  ld   [x]
              0459 1600  ld   ac,y
              045a 111d  ld   [$1d],x
              045b 0500  ld   [x]
              045c 1200  ld   ac,x
              045d 0118  ld   [$18]
              045e ce00  st   [y,x]
              045f 1403  ld   $03,y
              0460 e0cb  jmp  y,$cb
              0461 00f3  ld   $f3
peek:         0462 a001  suba $01
              0463 c216  st   [$16]
              0464 1118  ld   [$18],x
              0465 1519  ld   [$19],y
              0466 0d00  ld   [y,x]
              0467 c218  st   [$18]
lupReturn:    0468 0000  ld   $00
              0469 c219  st   [$19]
              046a 1403  ld   $03,y
              046b e0cb  jmp  y,$cb
              046c 00f3  ld   $f3
doke:         046d 9001  adda $01,x
              046e 0500  ld   [x]
              046f 1600  ld   ac,y
              0470 111d  ld   [$1d],x
              0471 0500  ld   [x]
              0472 1200  ld   ac,x
              0473 0118  ld   [$18]
              0474 de00  st   [y,x++]
              0475 0119  ld   [$19]
              0476 ce00  st   [y,x]
              0477 1403  ld   $03,y
              0478 e0cb  jmp  y,$cb
              0479 00f2  ld   $f2
deek:         047a 0116  ld   [$16]
              047b a001  suba $01
              047c c216  st   [$16]
              047d 1118  ld   [$18],x
              047e 1519  ld   [$19],y
              047f 0d00  ld   [y,x]
              0480 de00  st   [y,x++]
              0481 c218  st   [$18]
              0482 0d00  ld   [y,x]
              0483 1403  ld   $03,y
              0484 e0ca  jmp  y,$ca
              0485 c219  st   [$19]
andw:         0486 c21d  st   [$1d]
              0487 9001  adda $01,x
              0488 0500  ld   [x]
              0489 2119  anda [$19]
              048a c219  st   [$19]
              048b 111d  ld   [$1d],x
              048c 0500  ld   [x]
              048d 2118  anda [$18]
              048e c218  st   [$18]
              048f 1403  ld   $03,y
              0490 e0ca  jmp  y,$ca
orw:          0491 c21d  st   [$1d]
              0492 9001  adda $01,x
              0493 0500  ld   [x]
              0494 4119  ora  [$19]
              0495 c219  st   [$19]
              0496 111d  ld   [$1d],x
              0497 0500  ld   [x]
              0498 4118  ora  [$18]
              0499 c218  st   [$18]
              049a 1403  ld   $03,y
              049b e0ca  jmp  y,$ca
xorw:         049c 9001  adda $01,x
              049d 0500  ld   [x]
              049e 6119  xora [$19]
              049f c219  st   [$19]
              04a0 111d  ld   [$1d],x
              04a1 0500  ld   [x]
              04a2 6118  xora [$18]
              04a3 c218  st   [$18]
              04a4 1403  ld   $03,y
              04a5 e0cb  jmp  y,$cb
              04a6 00f3  ld   $f3
SYS_Random_34:
              04a7 010e  ld   [$0e]
              04a8 6107  xora [$07]
              04a9 610f  xora [$0f]
              04aa 8106  adda [$06]
              04ab c206  st   [$06]
              04ac c218  st   [$18]
              04ad 8108  adda [$08]
              04ae c208  st   [$08]
              04af e8b2  blt  .sysRnd0
              04b0 fcb3  bra  .sysRnd1
              04b1 6053  xora $53
.sysRnd0:     04b2 606c  xora $6c
.sysRnd1:     04b3 8107  adda [$07]
              04b4 c207  st   [$07]
              04b5 c219  st   [$19]
              04b6 1403  ld   $03,y
              04b7 e0cb  jmp  y,$cb
              04b8 00ef  ld   $ef
SYS_LSRW7_30: 04b9 0118  ld   [$18]
              04ba 3080  anda $80,x
              04bb 0119  ld   [$19]
              04bc 8200  adda ac
              04bd 4500  ora  [x]
              04be c218  st   [$18]
              04bf 0119  ld   [$19]
              04c0 3080  anda $80,x
              04c1 0500  ld   [x]
              04c2 c219  st   [$19]
              04c3 1403  ld   $03,y
              04c4 e0cb  jmp  y,$cb
              04c5 00f1  ld   $f1
SYS_LSRW8_24: 04c6 0119  ld   [$19]
              04c7 c218  st   [$18]
              04c8 0000  ld   $00
              04c9 c219  st   [$19]
              04ca 1403  ld   $03,y
              04cb e0cb  jmp  y,$cb
              04cc 00f4  ld   $f4
SYS_LSLW8_24: 04cd 0118  ld   [$18]
              04ce c219  st   [$19]
              04cf 0000  ld   $00
              04d0 c218  st   [$18]
              04d1 1403  ld   $03,y
              04d2 e0cb  jmp  y,$cb
              04d3 00f4  ld   $f4
SYS_Draw4_30: 04d4 1128  ld   [$28],x
              04d5 1529  ld   [$29],y
              04d6 0124  ld   [$24]
              04d7 de00  st   [y,x++]
              04d8 0125  ld   [$25]
              04d9 de00  st   [y,x++]
              04da 0126  ld   [$26]
              04db de00  st   [y,x++]
              04dc 0127  ld   [$27]
              04dd de00  st   [y,x++]
              04de 1403  ld   $03,y
              04df e0cb  jmp  y,$cb
              04e0 00f1  ld   $f1
SYS_VDrawBits_134:
              04e1 1128  ld   [$28],x
              04e2 0000  ld   $00
.vdb0:        04e3 c21d  st   [$1d]
              04e4 9529  adda [$29],y
              04e5 0126  ld   [$26]
              04e6 e8e9  blt  .vdb1
              04e7 fcea  bra  .vdb2
              04e8 0124  ld   [$24]
.vdb1:        04e9 0125  ld   [$25]
.vdb2:        04ea ce00  st   [y,x]
              04eb 0126  ld   [$26]
              04ec 8200  adda ac
              04ed c226  st   [$26]
              04ee 011d  ld   [$1d]
              04ef a007  suba $07
              04f0 ece3  bne  .vdb0
              04f1 8008  adda $08
              04f2 1403  ld   $03,y
              04f3 e0cb  jmp  y,$cb
              04f4 00bd  ld   $bd
inc:          04f5 8500  adda [x]
              04f6 c600  st   [x]
              04f7 00f5  ld   $f5
              04f8 1403  ld   $03,y
              04f9 e0cb  jmp  y,$cb
              04fa 0200  nop
              04fb 0200  nop              ;5 fillers
              04fc 0200  nop
              04fd 0200  nop
              * 5 times
shiftTable:   0500 0000  ld   $00         ;0b0000000x >> 1
              0501 0000  ld   $00         ;0b000000xx >> 2
              0502 0001  ld   $01         ;0b0000001x >> 1
              0503 0000  ld   $00         ;0b00000xxx >> 3
              0504 0002  ld   $02         ;0b0000010x >> 1
              0505 0001  ld   $01         ;0b000001xx >> 2
              0506 0003  ld   $03         ;0b0000011x >> 1
              0507 0000  ld   $00         ;0b0000xxxx >> 4
              0508 0004  ld   $04         ;0b0000100x >> 1
              0509 0002  ld   $02         ;0b000010xx >> 2
              050a 0005  ld   $05         ;0b0000101x >> 1
              050b 0001  ld   $01         ;0b00001xxx >> 3
              050c 0006  ld   $06         ;0b0000110x >> 1
              050d 0003  ld   $03         ;0b000011xx >> 2
              050e 0007  ld   $07         ;0b0000111x >> 1
              050f 0000  ld   $00         ;0b000xxxxx >> 5
              0510 0008  ld   $08         ;0b0001000x >> 1
              0511 0004  ld   $04         ;0b000100xx >> 2
              0512 0009  ld   $09         ;0b0001001x >> 1
              0513 0002  ld   $02         ;0b00010xxx >> 3
              0514 000a  ld   $0a         ;0b0001010x >> 1
              0515 0005  ld   $05         ;0b000101xx >> 2
              0516 000b  ld   $0b         ;0b0001011x >> 1
              0517 0001  ld   $01         ;0b0001xxxx >> 4
              0518 000c  ld   $0c         ;0b0001100x >> 1
              0519 0006  ld   $06         ;0b000110xx >> 2
              051a 000d  ld   $0d         ;0b0001101x >> 1
              051b 0003  ld   $03         ;0b00011xxx >> 3
              051c 000e  ld   $0e         ;0b0001110x >> 1
              051d 0007  ld   $07         ;0b000111xx >> 2
              051e 000f  ld   $0f         ;0b0001111x >> 1
              051f 0000  ld   $00         ;0b00xxxxxx >> 6
              0520 0010  ld   $10         ;0b0010000x >> 1
              0521 0008  ld   $08         ;0b001000xx >> 2
              0522 0011  ld   $11         ;0b0010001x >> 1
              0523 0004  ld   $04         ;0b00100xxx >> 3
              0524 0012  ld   $12         ;0b0010010x >> 1
              0525 0009  ld   $09         ;0b001001xx >> 2
              0526 0013  ld   $13         ;0b0010011x >> 1
              0527 0002  ld   $02         ;0b0010xxxx >> 4
              0528 0014  ld   $14         ;0b0010100x >> 1
              0529 000a  ld   $0a         ;0b001010xx >> 2
              052a 0015  ld   $15         ;0b0010101x >> 1
              052b 0005  ld   $05         ;0b00101xxx >> 3
              052c 0016  ld   $16         ;0b0010110x >> 1
              052d 000b  ld   $0b         ;0b001011xx >> 2
              052e 0017  ld   $17         ;0b0010111x >> 1
              052f 0001  ld   $01         ;0b001xxxxx >> 5
              0530 0018  ld   $18         ;0b0011000x >> 1
              0531 000c  ld   $0c         ;0b001100xx >> 2
              0532 0019  ld   $19         ;0b0011001x >> 1
              0533 0006  ld   $06         ;0b00110xxx >> 3
              0534 001a  ld   $1a         ;0b0011010x >> 1
              0535 000d  ld   $0d         ;0b001101xx >> 2
              0536 001b  ld   $1b         ;0b0011011x >> 1
              0537 0003  ld   $03         ;0b0011xxxx >> 4
              0538 001c  ld   $1c         ;0b0011100x >> 1
              0539 000e  ld   $0e         ;0b001110xx >> 2
              053a 001d  ld   $1d         ;0b0011101x >> 1
              053b 0007  ld   $07         ;0b00111xxx >> 3
              053c 001e  ld   $1e         ;0b0011110x >> 1
              053d 000f  ld   $0f         ;0b001111xx >> 2
              053e 001f  ld   $1f         ;0b0011111x >> 1
              053f 0000  ld   $00         ;0b00xxxxxx >> 6
              0540 0020  ld   $20         ;0b0100000x >> 1
              0541 0010  ld   $10         ;0b010000xx >> 2
              0542 0021  ld   $21         ;0b0100001x >> 1
              0543 0008  ld   $08         ;0b01000xxx >> 3
              0544 0022  ld   $22         ;0b0100010x >> 1
              0545 0011  ld   $11         ;0b010001xx >> 2
              0546 0023  ld   $23         ;0b0100011x >> 1
              0547 0004  ld   $04         ;0b0100xxxx >> 4
              0548 0024  ld   $24         ;0b0100100x >> 1
              0549 0012  ld   $12         ;0b010010xx >> 2
              054a 0025  ld   $25         ;0b0100101x >> 1
              054b 0009  ld   $09         ;0b01001xxx >> 3
              054c 0026  ld   $26         ;0b0100110x >> 1
              054d 0013  ld   $13         ;0b010011xx >> 2
              054e 0027  ld   $27         ;0b0100111x >> 1
              054f 0002  ld   $02         ;0b010xxxxx >> 5
              0550 0028  ld   $28         ;0b0101000x >> 1
              0551 0014  ld   $14         ;0b010100xx >> 2
              0552 0029  ld   $29         ;0b0101001x >> 1
              0553 000a  ld   $0a         ;0b01010xxx >> 3
              0554 002a  ld   $2a         ;0b0101010x >> 1
              0555 0015  ld   $15         ;0b010101xx >> 2
              0556 002b  ld   $2b         ;0b0101011x >> 1
              0557 0005  ld   $05         ;0b0101xxxx >> 4
              0558 002c  ld   $2c         ;0b0101100x >> 1
              0559 0016  ld   $16         ;0b010110xx >> 2
              055a 002d  ld   $2d         ;0b0101101x >> 1
              055b 000b  ld   $0b         ;0b01011xxx >> 3
              055c 002e  ld   $2e         ;0b0101110x >> 1
              055d 0017  ld   $17         ;0b010111xx >> 2
              055e 002f  ld   $2f         ;0b0101111x >> 1
              055f 0001  ld   $01         ;0b01xxxxxx >> 6
              0560 0030  ld   $30         ;0b0110000x >> 1
              0561 0018  ld   $18         ;0b011000xx >> 2
              0562 0031  ld   $31         ;0b0110001x >> 1
              0563 000c  ld   $0c         ;0b01100xxx >> 3
              0564 0032  ld   $32         ;0b0110010x >> 1
              0565 0019  ld   $19         ;0b011001xx >> 2
              0566 0033  ld   $33         ;0b0110011x >> 1
              0567 0006  ld   $06         ;0b0110xxxx >> 4
              0568 0034  ld   $34         ;0b0110100x >> 1
              0569 001a  ld   $1a         ;0b011010xx >> 2
              056a 0035  ld   $35         ;0b0110101x >> 1
              056b 000d  ld   $0d         ;0b01101xxx >> 3
              056c 0036  ld   $36         ;0b0110110x >> 1
              056d 001b  ld   $1b         ;0b011011xx >> 2
              056e 0037  ld   $37         ;0b0110111x >> 1
              056f 0003  ld   $03         ;0b011xxxxx >> 5
              0570 0038  ld   $38         ;0b0111000x >> 1
              0571 001c  ld   $1c         ;0b011100xx >> 2
              0572 0039  ld   $39         ;0b0111001x >> 1
              0573 000e  ld   $0e         ;0b01110xxx >> 3
              0574 003a  ld   $3a         ;0b0111010x >> 1
              0575 001d  ld   $1d         ;0b011101xx >> 2
              0576 003b  ld   $3b         ;0b0111011x >> 1
              0577 0007  ld   $07         ;0b0111xxxx >> 4
              0578 003c  ld   $3c         ;0b0111100x >> 1
              0579 001e  ld   $1e         ;0b011110xx >> 2
              057a 003d  ld   $3d         ;0b0111101x >> 1
              057b 000f  ld   $0f         ;0b01111xxx >> 3
              057c 003e  ld   $3e         ;0b0111110x >> 1
              057d 001f  ld   $1f         ;0b011111xx >> 2
              057e 003f  ld   $3f         ;0b0111111x >> 1
              057f 0001  ld   $01         ;0b01xxxxxx >> 6
              0580 0040  ld   $40         ;0b1000000x >> 1
              0581 0020  ld   $20         ;0b100000xx >> 2
              0582 0041  ld   $41         ;0b1000001x >> 1
              0583 0010  ld   $10         ;0b10000xxx >> 3
              0584 0042  ld   $42         ;0b1000010x >> 1
              0585 0021  ld   $21         ;0b100001xx >> 2
              0586 0043  ld   $43         ;0b1000011x >> 1
              0587 0008  ld   $08         ;0b1000xxxx >> 4
              0588 0044  ld   $44         ;0b1000100x >> 1
              0589 0022  ld   $22         ;0b100010xx >> 2
              058a 0045  ld   $45         ;0b1000101x >> 1
              058b 0011  ld   $11         ;0b10001xxx >> 3
              058c 0046  ld   $46         ;0b1000110x >> 1
              058d 0023  ld   $23         ;0b100011xx >> 2
              058e 0047  ld   $47         ;0b1000111x >> 1
              058f 0004  ld   $04         ;0b100xxxxx >> 5
              0590 0048  ld   $48         ;0b1001000x >> 1
              0591 0024  ld   $24         ;0b100100xx >> 2
              0592 0049  ld   $49         ;0b1001001x >> 1
              0593 0012  ld   $12         ;0b10010xxx >> 3
              0594 004a  ld   $4a         ;0b1001010x >> 1
              0595 0025  ld   $25         ;0b100101xx >> 2
              0596 004b  ld   $4b         ;0b1001011x >> 1
              0597 0009  ld   $09         ;0b1001xxxx >> 4
              0598 004c  ld   $4c         ;0b1001100x >> 1
              0599 0026  ld   $26         ;0b100110xx >> 2
              059a 004d  ld   $4d         ;0b1001101x >> 1
              059b 0013  ld   $13         ;0b10011xxx >> 3
              059c 004e  ld   $4e         ;0b1001110x >> 1
              059d 0027  ld   $27         ;0b100111xx >> 2
              059e 004f  ld   $4f         ;0b1001111x >> 1
              059f 0002  ld   $02         ;0b10xxxxxx >> 6
              05a0 0050  ld   $50         ;0b1010000x >> 1
              05a1 0028  ld   $28         ;0b101000xx >> 2
              05a2 0051  ld   $51         ;0b1010001x >> 1
              05a3 0014  ld   $14         ;0b10100xxx >> 3
              05a4 0052  ld   $52         ;0b1010010x >> 1
              05a5 0029  ld   $29         ;0b101001xx >> 2
              05a6 0053  ld   $53         ;0b1010011x >> 1
              05a7 000a  ld   $0a         ;0b1010xxxx >> 4
              05a8 0054  ld   $54         ;0b1010100x >> 1
              05a9 002a  ld   $2a         ;0b101010xx >> 2
              05aa 0055  ld   $55         ;0b1010101x >> 1
              05ab 0015  ld   $15         ;0b10101xxx >> 3
              05ac 0056  ld   $56         ;0b1010110x >> 1
              05ad 002b  ld   $2b         ;0b101011xx >> 2
              05ae 0057  ld   $57         ;0b1010111x >> 1
              05af 0005  ld   $05         ;0b101xxxxx >> 5
              05b0 0058  ld   $58         ;0b1011000x >> 1
              05b1 002c  ld   $2c         ;0b101100xx >> 2
              05b2 0059  ld   $59         ;0b1011001x >> 1
              05b3 0016  ld   $16         ;0b10110xxx >> 3
              05b4 005a  ld   $5a         ;0b1011010x >> 1
              05b5 002d  ld   $2d         ;0b101101xx >> 2
              05b6 005b  ld   $5b         ;0b1011011x >> 1
              05b7 000b  ld   $0b         ;0b1011xxxx >> 4
              05b8 005c  ld   $5c         ;0b1011100x >> 1
              05b9 002e  ld   $2e         ;0b101110xx >> 2
              05ba 005d  ld   $5d         ;0b1011101x >> 1
              05bb 0017  ld   $17         ;0b10111xxx >> 3
              05bc 005e  ld   $5e         ;0b1011110x >> 1
              05bd 002f  ld   $2f         ;0b101111xx >> 2
              05be 005f  ld   $5f         ;0b1011111x >> 1
              05bf 0002  ld   $02         ;0b10xxxxxx >> 6
              05c0 0060  ld   $60         ;0b1100000x >> 1
              05c1 0030  ld   $30         ;0b110000xx >> 2
              05c2 0061  ld   $61         ;0b1100001x >> 1
              05c3 0018  ld   $18         ;0b11000xxx >> 3
              05c4 0062  ld   $62         ;0b1100010x >> 1
              05c5 0031  ld   $31         ;0b110001xx >> 2
              05c6 0063  ld   $63         ;0b1100011x >> 1
              05c7 000c  ld   $0c         ;0b1100xxxx >> 4
              05c8 0064  ld   $64         ;0b1100100x >> 1
              05c9 0032  ld   $32         ;0b110010xx >> 2
              05ca 0065  ld   $65         ;0b1100101x >> 1
              05cb 0019  ld   $19         ;0b11001xxx >> 3
              05cc 0066  ld   $66         ;0b1100110x >> 1
              05cd 0033  ld   $33         ;0b110011xx >> 2
              05ce 0067  ld   $67         ;0b1100111x >> 1
              05cf 0006  ld   $06         ;0b110xxxxx >> 5
              05d0 0068  ld   $68         ;0b1101000x >> 1
              05d1 0034  ld   $34         ;0b110100xx >> 2
              05d2 0069  ld   $69         ;0b1101001x >> 1
              05d3 001a  ld   $1a         ;0b11010xxx >> 3
              05d4 006a  ld   $6a         ;0b1101010x >> 1
              05d5 0035  ld   $35         ;0b110101xx >> 2
              05d6 006b  ld   $6b         ;0b1101011x >> 1
              05d7 000d  ld   $0d         ;0b1101xxxx >> 4
              05d8 006c  ld   $6c         ;0b1101100x >> 1
              05d9 0036  ld   $36         ;0b110110xx >> 2
              05da 006d  ld   $6d         ;0b1101101x >> 1
              05db 001b  ld   $1b         ;0b11011xxx >> 3
              05dc 006e  ld   $6e         ;0b1101110x >> 1
              05dd 0037  ld   $37         ;0b110111xx >> 2
              05de 006f  ld   $6f         ;0b1101111x >> 1
              05df 0003  ld   $03         ;0b11xxxxxx >> 6
              05e0 0070  ld   $70         ;0b1110000x >> 1
              05e1 0038  ld   $38         ;0b111000xx >> 2
              05e2 0071  ld   $71         ;0b1110001x >> 1
              05e3 001c  ld   $1c         ;0b11100xxx >> 3
              05e4 0072  ld   $72         ;0b1110010x >> 1
              05e5 0039  ld   $39         ;0b111001xx >> 2
              05e6 0073  ld   $73         ;0b1110011x >> 1
              05e7 000e  ld   $0e         ;0b1110xxxx >> 4
              05e8 0074  ld   $74         ;0b1110100x >> 1
              05e9 003a  ld   $3a         ;0b111010xx >> 2
              05ea 0075  ld   $75         ;0b1110101x >> 1
              05eb 001d  ld   $1d         ;0b11101xxx >> 3
              05ec 0076  ld   $76         ;0b1110110x >> 1
              05ed 003b  ld   $3b         ;0b111011xx >> 2
              05ee 0077  ld   $77         ;0b1110111x >> 1
              05ef 0007  ld   $07         ;0b111xxxxx >> 5
              05f0 0078  ld   $78         ;0b1111000x >> 1
              05f1 003c  ld   $3c         ;0b111100xx >> 2
              05f2 0079  ld   $79         ;0b1111001x >> 1
              05f3 001e  ld   $1e         ;0b11110xxx >> 3
              05f4 007a  ld   $7a         ;0b1111010x >> 1
              05f5 003d  ld   $3d         ;0b111101xx >> 2
              05f6 007b  ld   $7b         ;0b1111011x >> 1
              05f7 000f  ld   $0f         ;0b1111xxxx >> 4
              05f8 007c  ld   $7c         ;0b1111100x >> 1
              05f9 003e  ld   $3e         ;0b111110xx >> 2
              05fa 007d  ld   $7d         ;0b1111101x >> 1
              05fb 001f  ld   $1f         ;0b11111xxx >> 3
              05fc 007e  ld   $7e         ;0b1111110x >> 1
              05fd 003f  ld   $3f         ;0b111111xx >> 2
              05fe 007f  ld   $7f         ;0b1111111x >> 1
              05ff fd1d  bra  [$1d]       ;Jumps back into next page
SYS_LSRW1_48: 0600 0200  nop
              0601 1405  ld   $05,y       ;Logical shift right 1 bit (X >> 1)
              0602 0008  ld   $08         ;Shift low byte
              0603 c21d  st   [$1d]
              0604 0118  ld   [$18]
              0605 20fe  anda $fe
              0606 e200  jmp  y,ac
              0607 fcff  bra  $ff         ;bra $05ff
.sysLsrw1a:   0608 c218  st   [$18]
              0609 0119  ld   [$19]       ;Transfer bit 8
              060a 2001  anda $01
              060b 807f  adda $7f
              060c 2080  anda $80
              060d 4118  ora  [$18]
              060e c218  st   [$18]
              060f 0015  ld   $15         ;Shift high byte
              0610 c21d  st   [$1d]
              0611 0119  ld   [$19]
              0612 20fe  anda $fe
              0613 e200  jmp  y,ac
              0614 fcff  bra  $ff         ;bra $05ff
.sysLsrw1b:   0615 c219  st   [$19]
              0616 1403  ld   $03,y
              0617 e0cb  jmp  y,$cb
              0618 00e8  ld   $e8
SYS_LSRW2_52: 0619 1405  ld   $05,y       ;Logical shift right 2 bit (X >> 2)
              061a 0021  ld   $21         ;Shift low byte
              061b c21d  st   [$1d]
              061c 0118  ld   [$18]
              061d 20fc  anda $fc
              061e 4001  ora  $01
              061f e200  jmp  y,ac
              0620 fcff  bra  $ff         ;bra $05ff
.sysLsrw2a:   0621 c218  st   [$18]
              0622 0119  ld   [$19]       ;Transfer bit 8:9
              0623 8200  adda ac
              0624 8200  adda ac
              0625 8200  adda ac
              * 6 times
              0629 4118  ora  [$18]
              062a c218  st   [$18]
              062b 0032  ld   $32         ;Shift high byte
              062c c21d  st   [$1d]
              062d 0119  ld   [$19]
              062e 20fc  anda $fc
              062f 4001  ora  $01
              0630 e200  jmp  y,ac
              0631 fcff  bra  $ff         ;bra $05ff
.sysLsrw2b:   0632 c219  st   [$19]
              0633 1403  ld   $03,y
              0634 e0cb  jmp  y,$cb
              0635 00e6  ld   $e6
SYS_LSRW3_52: 0636 1405  ld   $05,y       ;Logical shift right 3 bit (X >> 3)
              0637 003e  ld   $3e         ;Shift low byte
              0638 c21d  st   [$1d]
              0639 0118  ld   [$18]
              063a 20f8  anda $f8
              063b 4003  ora  $03
              063c e200  jmp  y,ac
              063d fcff  bra  $ff         ;bra $05ff
.sysLsrw3a:   063e c218  st   [$18]
              063f 0119  ld   [$19]       ;Transfer bit 8:10
              0640 8200  adda ac
              0641 8200  adda ac
              0642 8200  adda ac
              * 5 times
              0645 4118  ora  [$18]
              0646 c218  st   [$18]
              0647 004e  ld   $4e         ;Shift high byte
              0648 c21d  st   [$1d]
              0649 0119  ld   [$19]
              064a 20f8  anda $f8
              064b 4003  ora  $03
              064c e200  jmp  y,ac
              064d fcff  bra  $ff         ;bra $05ff
.sysLsrw3b:   064e c219  st   [$19]
              064f 00e6  ld   $e6
              0650 1403  ld   $03,y
              0651 e0cb  jmp  y,$cb
SYS_LSRW4_50: 0652 1405  ld   $05,y       ;Logical shift right 4 bit (X >> 4)
              0653 005a  ld   $5a         ;Shift low byte
              0654 c21d  st   [$1d]
              0655 0118  ld   [$18]
              0656 20f0  anda $f0
              0657 4007  ora  $07
              0658 e200  jmp  y,ac
              0659 fcff  bra  $ff         ;bra $05ff
.sysLsrw4a:   065a c218  st   [$18]
              065b 0119  ld   [$19]       ;Transfer bit 8:11
              065c 8200  adda ac
              065d 8200  adda ac
              065e 8200  adda ac
              065f 8200  adda ac
              0660 4118  ora  [$18]
              0661 c218  st   [$18]
              0662 0069  ld   $69         ;Shift high byte
              0663 c21d  st   [$1d]
              0664 0119  ld   [$19]
              0665 20f0  anda $f0
              0666 4007  ora  $07
              0667 e200  jmp  y,ac
              0668 fcff  bra  $ff         ;bra $05ff
.sysLsrw4b:   0669 c219  st   [$19]
              066a 1403  ld   $03,y
              066b e0cb  jmp  y,$cb
              066c 00e7  ld   $e7
SYS_LSRW5_50: 066d 1405  ld   $05,y       ;Logical shift right 5 bit (X >> 5)
              066e 0075  ld   $75         ;Shift low byte
              066f c21d  st   [$1d]
              0670 0118  ld   [$18]
              0671 20e0  anda $e0
              0672 400f  ora  $0f
              0673 e200  jmp  y,ac
              0674 fcff  bra  $ff         ;bra $05ff
.sysLsrw5a:   0675 c218  st   [$18]
              0676 0119  ld   [$19]       ;Transfer bit 8:13
              0677 8200  adda ac
              0678 8200  adda ac
              0679 8200  adda ac
              067a 4118  ora  [$18]
              067b c218  st   [$18]
              067c 0083  ld   $83         ;Shift high byte
              067d c21d  st   [$1d]
              067e 0119  ld   [$19]
              067f 20e0  anda $e0
              0680 400f  ora  $0f
              0681 e200  jmp  y,ac
              0682 fcff  bra  $ff         ;bra $05ff
.sysLsrw5b:   0683 c219  st   [$19]
              0684 00e7  ld   $e7
              0685 1403  ld   $03,y
              0686 e0cb  jmp  y,$cb
SYS_LSRW6_48: 0687 1405  ld   $05,y       ;Logical shift right 6 bit (X >> 6)
              0688 008f  ld   $8f         ;Shift low byte
              0689 c21d  st   [$1d]
              068a 0118  ld   [$18]
              068b 20c0  anda $c0
              068c 401f  ora  $1f
              068d e200  jmp  y,ac
              068e fcff  bra  $ff         ;bra $05ff
.sysLsrw6a:   068f c218  st   [$18]
              0690 0119  ld   [$19]       ;Transfer bit 8:13
              0691 8200  adda ac
              0692 8200  adda ac
              0693 4118  ora  [$18]
              0694 c218  st   [$18]
              0695 009c  ld   $9c         ;Shift high byte
              0696 c21d  st   [$1d]
              0697 0119  ld   [$19]
              0698 20c0  anda $c0
              0699 401f  ora  $1f
              069a e200  jmp  y,ac
              069b fcff  bra  $ff         ;bra $05ff
.sysLsrw6b:   069c c219  st   [$19]
              069d 1403  ld   $03,y
              069e e0cb  jmp  y,$cb
              069f 00e8  ld   $e8
SYS_LSLW4_46: 06a0 1405  ld   $05,y       ;Logical shift left 4 bit (X << 4)
              06a1 00ae  ld   $ae
              06a2 c21d  st   [$1d]
              06a3 0119  ld   [$19]
              06a4 8200  adda ac
              06a5 8200  adda ac
              06a6 8200  adda ac
              06a7 8200  adda ac
              06a8 c219  st   [$19]
              06a9 0118  ld   [$18]
              06aa 20f0  anda $f0
              06ab 4007  ora  $07
              06ac e200  jmp  y,ac
              06ad fcff  bra  $ff         ;bra $05ff
.sysLsrl4:    06ae 4119  ora  [$19]
              06af c219  st   [$19]
              06b0 0118  ld   [$18]
              06b1 8200  adda ac
              06b2 8200  adda ac
              06b3 8200  adda ac
              06b4 8200  adda ac
              06b5 c218  st   [$18]
              06b6 00e9  ld   $e9
              06b7 1403  ld   $03,y
              06b8 e0cb  jmp  y,$cb
SYS_Read3_40: 06b9 152b  ld   [$2b],y
              06ba e079  jmp  y,$79
              06bb 012a  ld   [$2a]
txReturn:     06bc c226  st   [$26]
              06bd 1403  ld   $03,y
              06be e0cb  jmp  y,$cb
              06bf 00ec  ld   $ec
SYS_Unpack_56:
              06c0 1407  ld   $07,y
              06c1 0126  ld   [$26]
              06c2 5003  ora  $03,x
              06c3 0d00  ld   [y,x]
              06c4 c227  st   [$27]       ;-> Pixel 3
              06c5 0126  ld   [$26]
              06c6 2003  anda $03
              06c7 8200  adda ac
              06c8 8200  adda ac
              06c9 8200  adda ac
              06ca 8200  adda ac
              06cb c226  st   [$26]
              06cc 0125  ld   [$25]
              06cd 5003  ora  $03,x
              06ce 0d00  ld   [y,x]
              06cf 5003  ora  $03,x
              06d0 0d00  ld   [y,x]
              06d1 4126  ora  [$26]
              06d2 c226  st   [$26]       ;-> Pixel 2
              06d3 0125  ld   [$25]
              06d4 200f  anda $0f
              06d5 8200  adda ac
              06d6 8200  adda ac
              06d7 c225  st   [$25]
              06d8 0124  ld   [$24]
              06d9 5003  ora  $03,x
              06da 0d00  ld   [y,x]
              06db 5003  ora  $03,x
              06dc 0d00  ld   [y,x]
              06dd 5003  ora  $03,x
              06de 0d00  ld   [y,x]
              06df 4125  ora  [$25]
              06e0 c225  st   [$25]       ;-> Pixel 1
              06e1 0124  ld   [$24]
              06e2 203f  anda $3f
              06e3 c224  st   [$24]       ;-> Pixel 0
              06e4 1403  ld   $03,y
              06e5 e0cb  jmp  y,$cb
              06e6 00e4  ld   $e4
v6502_lsr30:  06e7 1525  ld   [$25],y     ;Result
              06e8 ce00  st   [y,x]
              06e9 c228  st   [$28]       ;Z flag
              06ea c229  st   [$29]       ;N flag
              06eb 140e  ld   $0e,y
              06ec 00ed  ld   $ed
              06ed e020  jmp  y,$20
v6502_ror38:  06ee 1525  ld   [$25],y     ;Result
              06ef 4119  ora  [$19]       ;Transfer bit 8
              06f0 ce00  st   [y,x]
              06f1 c228  st   [$28]       ;Z flag
              06f2 c229  st   [$29]       ;N flag
              06f3 140e  ld   $0e,y
              06f4 e020  jmp  y,$20
              06f5 00e9  ld   $e9
              06f6 0200  nop              ;10 fillers
              06f7 0200  nop
              06f8 0200  nop
              * 10 times
font32up:     0700 0000  ld   $00         ;Char ' '
              0701 0000  ld   $00
              0702 0000  ld   $00
              * 5 times
              0705 0000  ld   $00         ;Char '!'
              0706 0000  ld   $00
              0707 00fa  ld   $fa
              0708 0000  ld   $00
              0709 0000  ld   $00
              070a 00a0  ld   $a0         ;Char '"'
              070b 00c0  ld   $c0
              070c 0000  ld   $00
              070d 00a0  ld   $a0
              070e 00c0  ld   $c0
              070f 0028  ld   $28         ;Char '#'
              0710 00fe  ld   $fe
              0711 0028  ld   $28
              0712 00fe  ld   $fe
              0713 0028  ld   $28
              0714 0024  ld   $24         ;Char '$'
              0715 0054  ld   $54
              0716 00fe  ld   $fe
              0717 0054  ld   $54
              0718 0048  ld   $48
              0719 00c4  ld   $c4         ;Char '%'
              071a 00c8  ld   $c8
              071b 0010  ld   $10
              071c 0026  ld   $26
              071d 0046  ld   $46
              071e 006c  ld   $6c         ;Char '&'
              071f 0092  ld   $92
              0720 006a  ld   $6a
              0721 0004  ld   $04
              0722 000a  ld   $0a
              0723 0000  ld   $00         ;Char "'"
              0724 00a0  ld   $a0
              0725 00c0  ld   $c0
              0726 0000  ld   $00
              0727 0000  ld   $00
              0728 0000  ld   $00         ;Char '('
              0729 0038  ld   $38
              072a 0044  ld   $44
              072b 0082  ld   $82
              072c 0000  ld   $00
              072d 0000  ld   $00         ;Char ')'
              072e 0082  ld   $82
              072f 0044  ld   $44
              0730 0038  ld   $38
              0731 0000  ld   $00
              0732 0028  ld   $28         ;Char '*'
              0733 0010  ld   $10
              0734 007c  ld   $7c
              0735 0010  ld   $10
              0736 0028  ld   $28
              0737 0010  ld   $10         ;Char '+'
              0738 0010  ld   $10
              0739 007c  ld   $7c
              073a 0010  ld   $10
              073b 0010  ld   $10
              073c 0000  ld   $00         ;Char ','
              073d 0005  ld   $05
              073e 0006  ld   $06
              073f 0000  ld   $00
              0740 0000  ld   $00
              0741 0010  ld   $10         ;Char '-'
              0742 0010  ld   $10
              0743 0010  ld   $10
              * 5 times
              0746 0000  ld   $00         ;Char '.'
              0747 0002  ld   $02
              0748 0002  ld   $02
              0749 0000  ld   $00
              074a 0000  ld   $00
              074b 0000  ld   $00         ;Char '/'
              074c 0006  ld   $06
              074d 0018  ld   $18
              074e 0060  ld   $60
              074f 0000  ld   $00
              0750 007c  ld   $7c         ;Char '0'
              0751 008a  ld   $8a
              0752 0092  ld   $92
              0753 00a2  ld   $a2
              0754 007c  ld   $7c
              0755 0022  ld   $22         ;Char '1'
              0756 0042  ld   $42
              0757 00fe  ld   $fe
              0758 0002  ld   $02
              0759 0002  ld   $02
              075a 0046  ld   $46         ;Char '2'
              075b 008a  ld   $8a
              075c 0092  ld   $92
              075d 0092  ld   $92
              075e 0062  ld   $62
              075f 0044  ld   $44         ;Char '3'
              0760 0082  ld   $82
              0761 0092  ld   $92
              0762 0092  ld   $92
              0763 006c  ld   $6c
              0764 0018  ld   $18         ;Char '4'
              0765 0028  ld   $28
              0766 0048  ld   $48
              0767 00fe  ld   $fe
              0768 0008  ld   $08
              0769 00e4  ld   $e4         ;Char '5'
              076a 00a2  ld   $a2
              076b 00a2  ld   $a2
              076c 00a2  ld   $a2
              076d 009c  ld   $9c
              076e 003c  ld   $3c         ;Char '6'
              076f 0052  ld   $52
              0770 0092  ld   $92
              0771 0092  ld   $92
              0772 000c  ld   $0c
              0773 0080  ld   $80         ;Char '7'
              0774 008e  ld   $8e
              0775 0090  ld   $90
              0776 00a0  ld   $a0
              0777 00c0  ld   $c0
              0778 006c  ld   $6c         ;Char '8'
              0779 0092  ld   $92
              077a 0092  ld   $92
              077b 0092  ld   $92
              077c 006c  ld   $6c
              077d 0060  ld   $60         ;Char '9'
              077e 0092  ld   $92
              077f 0092  ld   $92
              0780 0094  ld   $94
              0781 0078  ld   $78
              0782 0000  ld   $00         ;Char ':'
              0783 0024  ld   $24
              0784 0024  ld   $24
              0785 0000  ld   $00
              0786 0000  ld   $00
              0787 0000  ld   $00         ;Char ';'
              0788 0025  ld   $25
              0789 0026  ld   $26
              078a 0000  ld   $00
              078b 0000  ld   $00
              078c 0010  ld   $10         ;Char '<'
              078d 0028  ld   $28
              078e 0044  ld   $44
              078f 0082  ld   $82
              0790 0000  ld   $00
              0791 0028  ld   $28         ;Char '='
              0792 0028  ld   $28
              0793 0028  ld   $28
              * 5 times
              0796 0000  ld   $00         ;Char '>'
              0797 0082  ld   $82
              0798 0044  ld   $44
              0799 0028  ld   $28
              079a 0010  ld   $10
              079b 0040  ld   $40         ;Char '?'
              079c 0080  ld   $80
              079d 008a  ld   $8a
              079e 0090  ld   $90
              079f 0060  ld   $60
              07a0 007c  ld   $7c         ;Char '@'
              07a1 0082  ld   $82
              07a2 00ba  ld   $ba
              07a3 00aa  ld   $aa
              07a4 0078  ld   $78
              07a5 003e  ld   $3e         ;Char 'A'
              07a6 0048  ld   $48
              07a7 0088  ld   $88
              07a8 0048  ld   $48
              07a9 003e  ld   $3e
              07aa 00fe  ld   $fe         ;Char 'B'
              07ab 0092  ld   $92
              07ac 0092  ld   $92
              07ad 0092  ld   $92
              07ae 006c  ld   $6c
              07af 007c  ld   $7c         ;Char 'C'
              07b0 0082  ld   $82
              07b1 0082  ld   $82
              07b2 0082  ld   $82
              07b3 0044  ld   $44
              07b4 00fe  ld   $fe         ;Char 'D'
              07b5 0082  ld   $82
              07b6 0082  ld   $82
              07b7 0044  ld   $44
              07b8 0038  ld   $38
              07b9 00fe  ld   $fe         ;Char 'E'
              07ba 0092  ld   $92
              07bb 0092  ld   $92
              07bc 0092  ld   $92
              07bd 0082  ld   $82
              07be 00fe  ld   $fe         ;Char 'F'
              07bf 0090  ld   $90
              07c0 0090  ld   $90
              07c1 0090  ld   $90
              07c2 0080  ld   $80
              07c3 007c  ld   $7c         ;Char 'G'
              07c4 0082  ld   $82
              07c5 0082  ld   $82
              07c6 0092  ld   $92
              07c7 005c  ld   $5c
              07c8 00fe  ld   $fe         ;Char 'H'
              07c9 0010  ld   $10
              07ca 0010  ld   $10
              07cb 0010  ld   $10
              07cc 00fe  ld   $fe
              07cd 0000  ld   $00         ;Char 'I'
              07ce 0082  ld   $82
              07cf 00fe  ld   $fe
              07d0 0082  ld   $82
              07d1 0000  ld   $00
              07d2 0004  ld   $04         ;Char 'J'
              07d3 0002  ld   $02
              07d4 0082  ld   $82
              07d5 00fc  ld   $fc
              07d6 0080  ld   $80
              07d7 00fe  ld   $fe         ;Char 'K'
              07d8 0010  ld   $10
              07d9 0028  ld   $28
              07da 0044  ld   $44
              07db 0082  ld   $82
              07dc 00fe  ld   $fe         ;Char 'L'
              07dd 0002  ld   $02
              07de 0002  ld   $02
              07df 0002  ld   $02
              07e0 0002  ld   $02
              07e1 00fe  ld   $fe         ;Char 'M'
              07e2 0040  ld   $40
              07e3 0020  ld   $20
              07e4 0040  ld   $40
              07e5 00fe  ld   $fe
              07e6 00fe  ld   $fe         ;Char 'N'
              07e7 0020  ld   $20
              07e8 0010  ld   $10
              07e9 0008  ld   $08
              07ea 00fe  ld   $fe
              07eb 007c  ld   $7c         ;Char 'O'
              07ec 0082  ld   $82
              07ed 0082  ld   $82
              07ee 0082  ld   $82
              07ef 007c  ld   $7c
              07f0 00fe  ld   $fe         ;Char 'P'
              07f1 0090  ld   $90
              07f2 0090  ld   $90
              07f3 0090  ld   $90
              07f4 0060  ld   $60
              07f5 007c  ld   $7c         ;Char 'Q'
              07f6 0082  ld   $82
              07f7 008a  ld   $8a
              07f8 0084  ld   $84
              07f9 007a  ld   $7a
              07fa 0200  nop              ;filler
              07fb fe00  bra  ac          ;+-----------------------------------+
              07fc fcfd  bra  $07fd       ;|                                   |
              07fd 1404  ld   $04,y       ;| Trampoline for page $0700 lookups |
              07fe e068  jmp  y,$68       ;|                                   |
              07ff c218  st   [$18]       ;+-----------------------------------+
font82up:     0800 00fe  ld   $fe         ;Char 'R'
              0801 0090  ld   $90
              0802 0098  ld   $98
              0803 0094  ld   $94
              0804 0062  ld   $62
              0805 0062  ld   $62         ;Char 'S'
              0806 0092  ld   $92
              0807 0092  ld   $92
              0808 0092  ld   $92
              0809 000c  ld   $0c
              080a 0080  ld   $80         ;Char 'T'
              080b 0080  ld   $80
              080c 00fe  ld   $fe
              080d 0080  ld   $80
              080e 0080  ld   $80
              080f 00fc  ld   $fc         ;Char 'U'
              0810 0002  ld   $02
              0811 0002  ld   $02
              0812 0002  ld   $02
              0813 00fc  ld   $fc
              0814 00f0  ld   $f0         ;Char 'V'
              0815 000c  ld   $0c
              0816 0002  ld   $02
              0817 000c  ld   $0c
              0818 00f0  ld   $f0
              0819 00fe  ld   $fe         ;Char 'W'
              081a 0004  ld   $04
              081b 0008  ld   $08
              081c 0004  ld   $04
              081d 00fe  ld   $fe
              081e 00c6  ld   $c6         ;Char 'X'
              081f 0028  ld   $28
              0820 0010  ld   $10
              0821 0028  ld   $28
              0822 00c6  ld   $c6
              0823 00e0  ld   $e0         ;Char 'Y'
              0824 0010  ld   $10
              0825 000e  ld   $0e
              0826 0010  ld   $10
              0827 00e0  ld   $e0
              0828 0086  ld   $86         ;Char 'Z'
              0829 008a  ld   $8a
              082a 0092  ld   $92
              082b 00a2  ld   $a2
              082c 00c2  ld   $c2
              082d 0000  ld   $00         ;Char '['
              082e 00fe  ld   $fe
              082f 0082  ld   $82
              0830 0082  ld   $82
              0831 0000  ld   $00
              0832 0000  ld   $00         ;Char '\\'
              0833 0060  ld   $60
              0834 0018  ld   $18
              0835 0006  ld   $06
              0836 0000  ld   $00
              0837 0000  ld   $00         ;Char ']'
              0838 0082  ld   $82
              0839 0082  ld   $82
              083a 00fe  ld   $fe
              083b 0000  ld   $00
              083c 0020  ld   $20         ;Char '^'
              083d 0040  ld   $40
              083e 0080  ld   $80
              083f 0040  ld   $40
              0840 0020  ld   $20
              0841 0002  ld   $02         ;Char '_'
              0842 0002  ld   $02
              0843 0002  ld   $02
              * 5 times
              0846 0000  ld   $00         ;Char '`'
              0847 0000  ld   $00
              0848 00c0  ld   $c0
              0849 00a0  ld   $a0
              084a 0000  ld   $00
              084b 0004  ld   $04         ;Char 'a'
              084c 002a  ld   $2a
              084d 002a  ld   $2a
              084e 002a  ld   $2a
              084f 001e  ld   $1e
              0850 00fe  ld   $fe         ;Char 'b'
              0851 0022  ld   $22
              0852 0022  ld   $22
              0853 0022  ld   $22
              0854 001c  ld   $1c
              0855 001c  ld   $1c         ;Char 'c'
              0856 0022  ld   $22
              0857 0022  ld   $22
              0858 0022  ld   $22
              0859 0002  ld   $02
              085a 001c  ld   $1c         ;Char 'd'
              085b 0022  ld   $22
              085c 0022  ld   $22
              085d 0022  ld   $22
              085e 00fe  ld   $fe
              085f 001c  ld   $1c         ;Char 'e'
              0860 002a  ld   $2a
              0861 002a  ld   $2a
              0862 002a  ld   $2a
              0863 0018  ld   $18
              0864 0010  ld   $10         ;Char 'f'
              0865 007e  ld   $7e
              0866 0090  ld   $90
              0867 0080  ld   $80
              0868 0040  ld   $40
              0869 0018  ld   $18         ;Char 'g'
              086a 0025  ld   $25
              086b 0025  ld   $25
              086c 0025  ld   $25
              086d 001e  ld   $1e
              086e 00fe  ld   $fe         ;Char 'h'
              086f 0020  ld   $20
              0870 0020  ld   $20
              0871 0020  ld   $20
              0872 001e  ld   $1e
              0873 0000  ld   $00         ;Char 'i'
              0874 0022  ld   $22
              0875 00be  ld   $be
              0876 0002  ld   $02
              0877 0000  ld   $00
              0878 0002  ld   $02         ;Char 'j'
              0879 0001  ld   $01
              087a 0021  ld   $21
              087b 00be  ld   $be
              087c 0000  ld   $00
              087d 00fe  ld   $fe         ;Char 'k'
              087e 0008  ld   $08
              087f 0018  ld   $18
              0880 0024  ld   $24
              0881 0002  ld   $02
              0882 0000  ld   $00         ;Char 'l'
              0883 0082  ld   $82
              0884 00fe  ld   $fe
              0885 0002  ld   $02
              0886 0000  ld   $00
              0887 003e  ld   $3e         ;Char 'm'
              0888 0020  ld   $20
              0889 001c  ld   $1c
              088a 0020  ld   $20
              088b 001e  ld   $1e
              088c 003e  ld   $3e         ;Char 'n'
              088d 0010  ld   $10
              088e 0020  ld   $20
              088f 0020  ld   $20
              0890 001e  ld   $1e
              0891 001c  ld   $1c         ;Char 'o'
              0892 0022  ld   $22
              0893 0022  ld   $22
              0894 0022  ld   $22
              0895 001c  ld   $1c
              0896 003f  ld   $3f         ;Char 'p'
              0897 0024  ld   $24
              0898 0024  ld   $24
              0899 0024  ld   $24
              089a 0018  ld   $18
              089b 0018  ld   $18         ;Char 'q'
              089c 0024  ld   $24
              089d 0024  ld   $24
              089e 0024  ld   $24
              089f 003f  ld   $3f
              08a0 003e  ld   $3e         ;Char 'r'
              08a1 0010  ld   $10
              08a2 0020  ld   $20
              08a3 0020  ld   $20
              08a4 0010  ld   $10
              08a5 0012  ld   $12         ;Char 's'
              08a6 002a  ld   $2a
              08a7 002a  ld   $2a
              08a8 002a  ld   $2a
              08a9 0004  ld   $04
              08aa 0020  ld   $20         ;Char 't'
              08ab 00fc  ld   $fc
              08ac 0022  ld   $22
              08ad 0002  ld   $02
              08ae 0004  ld   $04
              08af 003c  ld   $3c         ;Char 'u'
              08b0 0002  ld   $02
              08b1 0002  ld   $02
              08b2 0004  ld   $04
              08b3 003e  ld   $3e
              08b4 0038  ld   $38         ;Char 'v'
              08b5 0004  ld   $04
              08b6 0002  ld   $02
              08b7 0004  ld   $04
              08b8 0038  ld   $38
              08b9 003c  ld   $3c         ;Char 'w'
              08ba 0002  ld   $02
              08bb 000c  ld   $0c
              08bc 0002  ld   $02
              08bd 003c  ld   $3c
              08be 0022  ld   $22         ;Char 'x'
              08bf 0014  ld   $14
              08c0 0008  ld   $08
              08c1 0014  ld   $14
              08c2 0022  ld   $22
              08c3 0038  ld   $38         ;Char 'y'
              08c4 0005  ld   $05
              08c5 0005  ld   $05
              08c6 0005  ld   $05
              08c7 003e  ld   $3e
              08c8 0022  ld   $22         ;Char 'z'
              08c9 0026  ld   $26
              08ca 002a  ld   $2a
              08cb 0032  ld   $32
              08cc 0022  ld   $22
              08cd 0010  ld   $10         ;Char '{'
              08ce 006c  ld   $6c
              08cf 0082  ld   $82
              08d0 0082  ld   $82
              08d1 0000  ld   $00
              08d2 0000  ld   $00         ;Char '|'
              08d3 0000  ld   $00
              08d4 00fe  ld   $fe
              08d5 0000  ld   $00
              08d6 0000  ld   $00
              08d7 0000  ld   $00         ;Char '}'
              08d8 0082  ld   $82
              08d9 0082  ld   $82
              08da 006c  ld   $6c
              08db 0010  ld   $10
              08dc 0040  ld   $40         ;Char '~'
              08dd 0080  ld   $80
              08de 0040  ld   $40
              08df 0020  ld   $20
              08e0 0040  ld   $40
              08e1 00fe  ld   $fe         ;Char '\x7f'
              08e2 00fe  ld   $fe
              08e3 00fe  ld   $fe
              * 5 times
              08e6 0010  ld   $10         ;Char '\x80'
              08e7 0038  ld   $38
              08e8 0054  ld   $54
              08e9 0010  ld   $10
              08ea 0010  ld   $10
              08eb 0010  ld   $10         ;Char '\x81'
              08ec 0020  ld   $20
              08ed 007c  ld   $7c
              08ee 0020  ld   $20
              08ef 0010  ld   $10
              08f0 0010  ld   $10         ;Char '\x82'
              08f1 0010  ld   $10
              08f2 0054  ld   $54
              08f3 0038  ld   $38
              08f4 0010  ld   $10
              08f5 0010  ld   $10         ;Char '\x83'
              08f6 0008  ld   $08
              08f7 007c  ld   $7c
              08f8 0008  ld   $08
              08f9 0010  ld   $10
              08fa 0200  nop              ;filler
              08fb fe00  bra  ac          ;+-----------------------------------+
              08fc fcfd  bra  $08fd       ;|                                   |
              08fd 1404  ld   $04,y       ;| Trampoline for page $0800 lookups |
              08fe e068  jmp  y,$68       ;|                                   |
              08ff c218  st   [$18]       ;+-----------------------------------+
notesTable:   0900 0000  ld   $00
              0901 0000  ld   $00
              0902 0045  ld   $45         ;C-0 (16.4 Hz)
              0903 0000  ld   $00
              0904 0049  ld   $49         ;C#0 (17.3 Hz)
              0905 0000  ld   $00
              0906 004d  ld   $4d         ;D-0 (18.4 Hz)
              0907 0000  ld   $00
              0908 0052  ld   $52         ;D#0 (19.4 Hz)
              0909 0000  ld   $00
              090a 0056  ld   $56         ;E-0 (20.6 Hz)
              090b 0000  ld   $00
              090c 005c  ld   $5c         ;F-0 (21.8 Hz)
              090d 0000  ld   $00
              090e 0061  ld   $61         ;F#0 (23.1 Hz)
              090f 0000  ld   $00
              0910 0067  ld   $67         ;G-0 (24.5 Hz)
              0911 0000  ld   $00
              0912 006d  ld   $6d         ;G#0 (26.0 Hz)
              0913 0000  ld   $00
              0914 0073  ld   $73         ;A-0 (27.5 Hz)
              0915 0000  ld   $00
              0916 007a  ld   $7a         ;A#0 (29.1 Hz)
              0917 0000  ld   $00
              0918 0001  ld   $01         ;B-0 (30.9 Hz)
              0919 0001  ld   $01
              091a 0009  ld   $09         ;C-1 (32.7 Hz)
              091b 0001  ld   $01
              091c 0011  ld   $11         ;C#1 (34.6 Hz)
              091d 0001  ld   $01
              091e 001a  ld   $1a         ;D-1 (36.7 Hz)
              091f 0001  ld   $01
              0920 0023  ld   $23         ;D#1 (38.9 Hz)
              0921 0001  ld   $01
              0922 002d  ld   $2d         ;E-1 (41.2 Hz)
              0923 0001  ld   $01
              0924 0037  ld   $37         ;F-1 (43.7 Hz)
              0925 0001  ld   $01
              0926 0042  ld   $42         ;F#1 (46.2 Hz)
              0927 0001  ld   $01
              0928 004e  ld   $4e         ;G-1 (49.0 Hz)
              0929 0001  ld   $01
              092a 005a  ld   $5a         ;G#1 (51.9 Hz)
              092b 0001  ld   $01
              092c 0067  ld   $67         ;A-1 (55.0 Hz)
              092d 0001  ld   $01
              092e 0074  ld   $74         ;A#1 (58.3 Hz)
              092f 0001  ld   $01
              0930 0003  ld   $03         ;B-1 (61.7 Hz)
              0931 0002  ld   $02
              0932 0012  ld   $12         ;C-2 (65.4 Hz)
              0933 0002  ld   $02
              0934 0023  ld   $23         ;C#2 (69.3 Hz)
              0935 0002  ld   $02
              0936 0034  ld   $34         ;D-2 (73.4 Hz)
              0937 0002  ld   $02
              0938 0046  ld   $46         ;D#2 (77.8 Hz)
              0939 0002  ld   $02
              093a 005a  ld   $5a         ;E-2 (82.4 Hz)
              093b 0002  ld   $02
              093c 006e  ld   $6e         ;F-2 (87.3 Hz)
              093d 0002  ld   $02
              093e 0004  ld   $04         ;F#2 (92.5 Hz)
              093f 0003  ld   $03
              0940 001b  ld   $1b         ;G-2 (98.0 Hz)
              0941 0003  ld   $03
              0942 0033  ld   $33         ;G#2 (103.8 Hz)
              0943 0003  ld   $03
              0944 004d  ld   $4d         ;A-2 (110.0 Hz)
              0945 0003  ld   $03
              0946 0069  ld   $69         ;A#2 (116.5 Hz)
              0947 0003  ld   $03
              0948 0006  ld   $06         ;B-2 (123.5 Hz)
              0949 0004  ld   $04
              094a 0025  ld   $25         ;C-3 (130.8 Hz)
              094b 0004  ld   $04
              094c 0045  ld   $45         ;C#3 (138.6 Hz)
              094d 0004  ld   $04
              094e 0068  ld   $68         ;D-3 (146.8 Hz)
              094f 0004  ld   $04
              0950 000c  ld   $0c         ;D#3 (155.6 Hz)
              0951 0005  ld   $05
              0952 0033  ld   $33         ;E-3 (164.8 Hz)
              0953 0005  ld   $05
              0954 005c  ld   $5c         ;F-3 (174.6 Hz)
              0955 0005  ld   $05
              0956 0008  ld   $08         ;F#3 (185.0 Hz)
              0957 0006  ld   $06
              0958 0036  ld   $36         ;G-3 (196.0 Hz)
              0959 0006  ld   $06
              095a 0067  ld   $67         ;G#3 (207.7 Hz)
              095b 0006  ld   $06
              095c 001b  ld   $1b         ;A-3 (220.0 Hz)
              095d 0007  ld   $07
              095e 0052  ld   $52         ;A#3 (233.1 Hz)
              095f 0007  ld   $07
              0960 000c  ld   $0c         ;B-3 (246.9 Hz)
              0961 0008  ld   $08
              0962 0049  ld   $49         ;C-4 (261.6 Hz)
              0963 0008  ld   $08
              0964 000b  ld   $0b         ;C#4 (277.2 Hz)
              0965 0009  ld   $09
              0966 0050  ld   $50         ;D-4 (293.7 Hz)
              0967 0009  ld   $09
              0968 0019  ld   $19         ;D#4 (311.1 Hz)
              0969 000a  ld   $0a
              096a 0067  ld   $67         ;E-4 (329.6 Hz)
              096b 000a  ld   $0a
              096c 0039  ld   $39         ;F-4 (349.2 Hz)
              096d 000b  ld   $0b
              096e 0010  ld   $10         ;F#4 (370.0 Hz)
              096f 000c  ld   $0c
              0970 006c  ld   $6c         ;G-4 (392.0 Hz)
              0971 000c  ld   $0c
              0972 004e  ld   $4e         ;G#4 (415.3 Hz)
              0973 000d  ld   $0d
              0974 0035  ld   $35         ;A-4 (440.0 Hz)
              0975 000e  ld   $0e
              0976 0023  ld   $23         ;A#4 (466.2 Hz)
              0977 000f  ld   $0f
              0978 0017  ld   $17         ;B-4 (493.9 Hz)
              0979 0010  ld   $10
              097a 0013  ld   $13         ;C-5 (523.3 Hz)
              097b 0011  ld   $11
              097c 0015  ld   $15         ;C#5 (554.4 Hz)
              097d 0012  ld   $12
              097e 001f  ld   $1f         ;D-5 (587.3 Hz)
              097f 0013  ld   $13
              0980 0032  ld   $32         ;D#5 (622.3 Hz)
              0981 0014  ld   $14
              0982 004d  ld   $4d         ;E-5 (659.3 Hz)
              0983 0015  ld   $15
              0984 0072  ld   $72         ;F-5 (698.5 Hz)
              0985 0016  ld   $16
              0986 0020  ld   $20         ;F#5 (740.0 Hz)
              0987 0018  ld   $18
              0988 0058  ld   $58         ;G-5 (784.0 Hz)
              0989 0019  ld   $19
              098a 001c  ld   $1c         ;G#5 (830.6 Hz)
              098b 001b  ld   $1b
              098c 006b  ld   $6b         ;A-5 (880.0 Hz)
              098d 001c  ld   $1c
              098e 0046  ld   $46         ;A#5 (932.3 Hz)
              098f 001e  ld   $1e
              0990 002f  ld   $2f         ;B-5 (987.8 Hz)
              0991 0020  ld   $20
              0992 0025  ld   $25         ;C-6 (1046.5 Hz)
              0993 0022  ld   $22
              0994 002a  ld   $2a         ;C#6 (1108.7 Hz)
              0995 0024  ld   $24
              0996 003f  ld   $3f         ;D-6 (1174.7 Hz)
              0997 0026  ld   $26
              0998 0064  ld   $64         ;D#6 (1244.5 Hz)
              0999 0028  ld   $28
              099a 001a  ld   $1a         ;E-6 (1318.5 Hz)
              099b 002b  ld   $2b
              099c 0063  ld   $63         ;F-6 (1396.9 Hz)
              099d 002d  ld   $2d
              099e 003f  ld   $3f         ;F#6 (1480.0 Hz)
              099f 0030  ld   $30
              09a0 0031  ld   $31         ;G-6 (1568.0 Hz)
              09a1 0033  ld   $33
              09a2 0038  ld   $38         ;G#6 (1661.2 Hz)
              09a3 0036  ld   $36
              09a4 0056  ld   $56         ;A-6 (1760.0 Hz)
              09a5 0039  ld   $39
              09a6 000d  ld   $0d         ;A#6 (1864.7 Hz)
              09a7 003d  ld   $3d
              09a8 005e  ld   $5e         ;B-6 (1975.5 Hz)
              09a9 0040  ld   $40
              09aa 004b  ld   $4b         ;C-7 (2093.0 Hz)
              09ab 0044  ld   $44
              09ac 0055  ld   $55         ;C#7 (2217.5 Hz)
              09ad 0048  ld   $48
              09ae 007e  ld   $7e         ;D-7 (2349.3 Hz)
              09af 004c  ld   $4c
              09b0 0048  ld   $48         ;D#7 (2489.0 Hz)
              09b1 0051  ld   $51
              09b2 0034  ld   $34         ;E-7 (2637.0 Hz)
              09b3 0056  ld   $56
              09b4 0046  ld   $46         ;F-7 (2793.8 Hz)
              09b5 005b  ld   $5b
              09b6 007f  ld   $7f         ;F#7 (2960.0 Hz)
              09b7 0060  ld   $60
              09b8 0061  ld   $61         ;G-7 (3136.0 Hz)
              09b9 0066  ld   $66
              09ba 006f  ld   $6f         ;G#7 (3322.4 Hz)
              09bb 006c  ld   $6c
              09bc 002c  ld   $2c         ;A-7 (3520.0 Hz)
              09bd 0073  ld   $73
              09be 001a  ld   $1a         ;A#7 (3729.3 Hz)
              09bf 007a  ld   $7a
              09c0 0000  ld   $00         ;30 fillers
              09c1 0000  ld   $00
              09c2 0000  ld   $00
              * 30 times
vBlankLast#34:
              09de 010f  ld   [$0f]       ;if serialRaw in [0,1,3,7,15,31,63,127,255]
              09df 8001  adda $01
              09e0 210f  anda [$0f]
              09e1 ecf2  bne  .buttons#39
              09e2 010f  ld   [$0f]       ;[TypeC] if serialRaw < serialLast
              09e3 8001  adda $01
              09e4 2110  anda [$10]
              09e5 ece9  bne  .buttons#43
              09e6 00fe  ld   $fe         ;then clear the selected bit
              09e7 0200  nop
              09e8 fcec  bra  .buttons#46
.buttons#43:  09e9 a10f  suba [$0f]
              09ea 2111  anda [$11]
              09eb c211  st   [$11]
.buttons#46:  09ec 010f  ld   [$0f]       ;Set the lower bits
              09ed 4111  ora  [$11]
.buttons#48:  09ee c211  st   [$11]
              09ef 010f  ld   [$0f]       ;Update serialLast for next pass
              09f0 e0ae  jmp  y,$ae
              09f1 c210  st   [$10]
.buttons#39:  09f2 00ff  ld   $ff         ;[TypeB] Bitwise edge-filter to detect button presses
              09f3 6110  xora [$10]
              09f4 410f  ora  [$0f]
              09f5 2111  anda [$11]
              09f6 410f  ora  [$0f]
              09f7 0200  nop
              09f8 0200  nop
              09f9 fcee  bra  .buttons#48
              09fa 0200  nop
              09fb fe00  bra  ac          ;+-----------------------------------+
              09fc fcfd  bra  $09fd       ;|                                   |
              09fd 1404  ld   $04,y       ;| Trampoline for page $0900 lookups |
              09fe e068  jmp  y,$68       ;|                                   |
              09ff c218  st   [$18]       ;+-----------------------------------+
invTable:     0a00 00ff  ld   $ff
              0a01 00ef  ld   $ef
              0a02 00e2  ld   $e2
              0a03 00d6  ld   $d6
              0a04 00cb  ld   $cb
              0a05 00c2  ld   $c2
              0a06 00b9  ld   $b9
              0a07 00b1  ld   $b1
              0a08 00a9  ld   $a9
              0a09 00a2  ld   $a2
              0a0a 009c  ld   $9c
              0a0b 0096  ld   $96
              0a0c 0091  ld   $91
              0a0d 008c  ld   $8c
              0a0e 0087  ld   $87
              0a0f 0083  ld   $83
              0a10 007f  ld   $7f
              0a11 007b  ld   $7b
              0a12 0077  ld   $77
              0a13 0074  ld   $74
              0a14 0070  ld   $70
              0a15 006d  ld   $6d
              0a16 006a  ld   $6a
              0a17 0068  ld   $68
              0a18 0065  ld   $65
              0a19 0062  ld   $62
              0a1a 0060  ld   $60
              0a1b 005e  ld   $5e
              0a1c 005c  ld   $5c
              0a1d 005a  ld   $5a
              0a1e 0058  ld   $58
              0a1f 0056  ld   $56
              0a20 0054  ld   $54
              0a21 0052  ld   $52
              0a22 0050  ld   $50
              0a23 004f  ld   $4f
              0a24 004d  ld   $4d
              0a25 004c  ld   $4c
              0a26 004a  ld   $4a
              0a27 0049  ld   $49
              0a28 0048  ld   $48
              0a29 0046  ld   $46
              0a2a 0045  ld   $45
              0a2b 0044  ld   $44
              0a2c 0043  ld   $43
              0a2d 0042  ld   $42
              0a2e 0041  ld   $41
              0a2f 0040  ld   $40
              0a30 003f  ld   $3f
              0a31 003e  ld   $3e
              0a32 003d  ld   $3d
              0a33 003c  ld   $3c
              0a34 003b  ld   $3b
              0a35 003a  ld   $3a
              0a36 0039  ld   $39
              0a37 0038  ld   $38
              0a38 0037  ld   $37
              0a39 0037  ld   $37
              0a3a 0036  ld   $36
              0a3b 0035  ld   $35
              0a3c 0034  ld   $34
              0a3d 0034  ld   $34
              0a3e 0033  ld   $33
              0a3f 0032  ld   $32
              0a40 0032  ld   $32
              0a41 0031  ld   $31
              0a42 0030  ld   $30
              0a43 0030  ld   $30
              0a44 002f  ld   $2f
              0a45 002f  ld   $2f
              0a46 002e  ld   $2e
              0a47 002e  ld   $2e
              0a48 002d  ld   $2d
              0a49 002d  ld   $2d
              0a4a 002c  ld   $2c
              0a4b 002c  ld   $2c
              0a4c 002b  ld   $2b
              0a4d 002b  ld   $2b
              0a4e 002a  ld   $2a
              0a4f 002a  ld   $2a
              0a50 0029  ld   $29
              0a51 0029  ld   $29
              0a52 0028  ld   $28
              0a53 0028  ld   $28
              0a54 0027  ld   $27
              0a55 0027  ld   $27
              0a56 0027  ld   $27
              0a57 0026  ld   $26
              0a58 0026  ld   $26
              0a59 0026  ld   $26
              0a5a 0025  ld   $25
              0a5b 0025  ld   $25
              0a5c 0024  ld   $24
              0a5d 0024  ld   $24
              0a5e 0024  ld   $24
              0a5f 0023  ld   $23
              0a60 0023  ld   $23
              0a61 0023  ld   $23
              0a62 0022  ld   $22
              0a63 0022  ld   $22
              0a64 0022  ld   $22
              0a65 0022  ld   $22
              0a66 0021  ld   $21
              0a67 0021  ld   $21
              0a68 0021  ld   $21
              0a69 0020  ld   $20
              0a6a 0020  ld   $20
              0a6b 0020  ld   $20
              0a6c 0020  ld   $20
              0a6d 001f  ld   $1f
              0a6e 001f  ld   $1f
              0a6f 001f  ld   $1f
              0a70 001f  ld   $1f
              0a71 001e  ld   $1e
              0a72 001e  ld   $1e
              0a73 001e  ld   $1e
              0a74 001e  ld   $1e
              0a75 001d  ld   $1d
              0a76 001d  ld   $1d
              0a77 001d  ld   $1d
              0a78 001d  ld   $1d
              0a79 001c  ld   $1c
              0a7a 001c  ld   $1c
              0a7b 001c  ld   $1c
              * 5 times
              0a7e 001b  ld   $1b
              0a7f 001b  ld   $1b
              0a80 001b  ld   $1b
              * 5 times
              0a83 001a  ld   $1a
              0a84 001a  ld   $1a
              0a85 001a  ld   $1a
              * 5 times
              0a88 0019  ld   $19
              0a89 0019  ld   $19
              0a8a 0019  ld   $19
              * 6 times
              0a8e 0018  ld   $18
              0a8f 0018  ld   $18
              0a90 0018  ld   $18
              * 6 times
              0a94 0017  ld   $17
              0a95 0017  ld   $17
              0a96 0017  ld   $17
              * 7 times
              0a9b 0016  ld   $16
              0a9c 0016  ld   $16
              0a9d 0016  ld   $16
              * 8 times
              0aa3 0015  ld   $15
              0aa4 0015  ld   $15
              0aa5 0015  ld   $15
              * 8 times
              0aab 0014  ld   $14
              0aac 0014  ld   $14
              0aad 0014  ld   $14
              * 9 times
              0ab4 0013  ld   $13
              0ab5 0013  ld   $13
              0ab6 0013  ld   $13
              * 9 times
              0abd 0012  ld   $12
              0abe 0012  ld   $12
              0abf 0012  ld   $12
              * 11 times
              0ac8 0011  ld   $11
              0ac9 0011  ld   $11
              0aca 0011  ld   $11
              * 12 times
              0ad4 0010  ld   $10
              0ad5 0010  ld   $10
              0ad6 0010  ld   $10
              * 13 times
              0ae1 000f  ld   $0f
              0ae2 000f  ld   $0f
              0ae3 000f  ld   $0f
              * 16 times
              0af1 000e  ld   $0e
              0af2 000e  ld   $0e
              0af3 000e  ld   $0e
              * 10 times
              0afb fe00  bra  ac          ;+-----------------------------------+
              0afc fcfd  bra  $0afd       ;|                                   |
              0afd 1404  ld   $04,y       ;| Trampoline for page $0a00 lookups |
              0afe e068  jmp  y,$68       ;|                                   |
              0aff c218  st   [$18]       ;+-----------------------------------+
SYS_SetMode_v2_80:
              0b00 140b  ld   $0b,y
              0b01 e047  jmp  y,$47
              0b02 011e  ld   [$1e]
SYS_SetMemory_v2_54:
              0b03 fc18  bra  sys_SetMemory
              0b04 0124  ld   [$24]
              0b05 0200  nop
SYS_SendSerial1_v3_80:
              0b06 0109  ld   [$09]
              0b07 fc76  bra  sys_SendSerial1
              0b08 60b3  xora $b3
SYS_ExpanderControl_v4_40:
              0b09 140c  ld   $0c,y
              0b0a e0fb  jmp  y,$fb
              0b0b 0118  ld   [$18]
SYS_Run6502_v4_80:
              0b0c 140d  ld   $0d,y
              0b0d e07c  jmp  y,$7c
              0b0e 000d  ld   $0d         ;Activate v6502
SYS_ResetWaveforms_v4_50:
              0b0f 140b  ld   $0b,y       ;Initial setup of waveforms. [vAC+0]=i
              0b10 e0a3  jmp  y,$a3
              0b11 1407  ld   $07,y
SYS_ShuffleNoise_v4_46:
              0b12 140b  ld   $0b,y       ;Shuffle soundTable[4i+0]. [vAC+0]=4j, [vAC+1]=4i
              0b13 e0c4  jmp  y,$c4
              0b14 1407  ld   $07,y
SYS_SpiExchangeBytes_v4_134:
              0b15 140d  ld   $0d,y       ;Exchange 1..256 bytes over SPI interface
              0b16 e009  jmp  y,$09
              0b17 1124  ld   [$24],x     ;Fetch byte to send
sys_SetMemory:
              0b18 a001  suba $01
              0b19 c224  st   [$24]
              0b1a 1126  ld   [$26],x
              0b1b 1527  ld   [$27],y
              0b1c 0125  ld   [$25]
              0b1d de00  st   [y,x++]     ;Copy byte 1
              0b1e 0124  ld   [$24]
              0b1f f03a  beq  .sysSb1
              0b20 a001  suba $01
              0b21 c224  st   [$24]
              0b22 0125  ld   [$25]
              0b23 de00  st   [y,x++]     ;Copy byte 2
              0b24 0124  ld   [$24]
              0b25 f03d  beq  .sysSb2
              0b26 a001  suba $01
              0b27 c224  st   [$24]
              0b28 0125  ld   [$25]
              0b29 de00  st   [y,x++]     ;Copy byte 3
              0b2a 0124  ld   [$24]
              0b2b f040  beq  .sysSb3
              0b2c a001  suba $01
              0b2d c224  st   [$24]
              0b2e 0125  ld   [$25]
              0b2f de00  st   [y,x++]     ;Copy byte 4
              0b30 0124  ld   [$24]
              0b31 f043  beq  .sysSb4
              0b32 0116  ld   [$16]
              0b33 a002  suba $02
              0b34 c216  st   [$16]
              0b35 0126  ld   [$26]
              0b36 8004  adda $04
              0b37 c226  st   [$26]
              0b38 1403  ld   $03,y
              0b39 e0cb  jmp  y,$cb
.sysSb1:      0b3a 00e5  ld   $e5
              0b3b 1403  ld   $03,y
              0b3c e0cb  jmp  y,$cb
.sysSb2:      0b3d 00f0  ld   $f0
              0b3e 1403  ld   $03,y
              0b3f e0cb  jmp  y,$cb
.sysSb3:      0b40 00ed  ld   $ed
              0b41 1403  ld   $03,y
              0b42 e0cb  jmp  y,$cb
.sysSb4:      0b43 00ea  ld   $ea
              0b44 1403  ld   $03,y
              0b45 e0cb  jmp  y,$cb
              0b46 00e7  ld   $e7
sys_SetMode:  0b47 ec4a  bne  $0b4a
              0b48 fc4a  bra  $0b4a
              0b49 0003  ld   $03         ;First enable video if disabled
              0b4a c21e  st   [$1e]
              0b4b 0119  ld   [$19]
              0b4c f056  beq  .sysSm#25
              0b4d 1403  ld   $03,y
              0b4e 6118  xora [$18]
              0b4f 60b0  xora $b0         ;Poor man's 1975 detection
              0b50 ec53  bne  $0b53
              0b51 fc54  bra  $0b54
              0b52 c21e  st   [$1e]       ;DISABLE video/audio/serial/etc
              0b53 0200  nop              ;Ignore and return
              0b54 e0cb  jmp  y,$cb
              0b55 00ef  ld   $ef
.sysSm#25:    0b56 0118  ld   [$18]       ;Mode 0,1,2,3
              0b57 2003  anda $03
              0b58 805b  adda $5b
              0b59 fe00  bra  ac
              0b5a fc5f  bra  .sysSm#31
.sysSm#30:    0b5b 000a  ld   $0a         ;videoB lines
              0b5c 000a  ld   $0a
              0b5d 00f6  ld   $f6
              0b5e 00f6  ld   $f6
.sysSm#31:    0b5f c20a  st   [$0a]
              0b60 0118  ld   [$18]
              0b61 2003  anda $03
              0b62 8065  adda $65
              0b63 fe00  bra  ac
              0b64 fc69  bra  .sysSm#38
.sysSm#37:    0b65 000a  ld   $0a         ;videoC lines
              0b66 000a  ld   $0a
              0b67 000a  ld   $0a
              0b68 00f6  ld   $f6
.sysSm#38:    0b69 c20b  st   [$0b]
              0b6a 0118  ld   [$18]
              0b6b 2003  anda $03
              0b6c 806f  adda $6f
              0b6d fe00  bra  ac
              0b6e fc73  bra  .sysSm#45
.sysSm#44:    0b6f 000a  ld   $0a         ;videoD lines
              0b70 00f6  ld   $f6
              0b71 00f6  ld   $f6
              0b72 00f6  ld   $f6
.sysSm#45:    0b73 c20c  st   [$0c]
              0b74 e0cb  jmp  y,$cb
              0b75 00e7  ld   $e7
sys_SendSerial1:
              0b76 f07d  beq  .sysSs#20
              0b77 1124  ld   [$24],x
              0b78 0116  ld   [$16]
              0b79 a002  suba $02
              0b7a 1403  ld   $03,y
              0b7b e0ca  jmp  y,$ca
              0b7c c216  st   [$16]
.sysSs#20:    0b7d 1525  ld   [$25],y
              0b7e 0d00  ld   [y,x]
              0b7f 2126  anda [$26]
              0b80 ec83  bne  $0b83
              0b81 fc84  bra  $0b84
              0b82 000e  ld   $0e
              0b83 0012  ld   $12
              0b84 c20d  st   [$0d]
              0b85 0126  ld   [$26]
              0b86 8200  adda ac
              0b87 ec8a  bne  $0b8a
              0b88 fc8a  bra  $0b8a
              0b89 0001  ld   $01
              0b8a c226  st   [$26]
              0b8b 2001  anda $01
              0b8c 8124  adda [$24]
              0b8d d224  st   [$24],x
              0b8e 0127  ld   [$27]
              0b8f a001  suba $01
              0b90 f09f  beq  .sysSs#40
              0b91 1403  ld   $03,y
              0b92 c227  st   [$27]
              0b93 010f  ld   [$0f]
              0b94 60ff  xora $ff
              0b95 f09a  beq  .sysSs#45
              0b96 c218  st   [$18]
              0b97 c219  st   [$19]
              0b98 e0cb  jmp  y,$cb
              0b99 00e7  ld   $e7
.sysSs#45:    0b9a 0116  ld   [$16]
              0b9b a002  suba $02
              0b9c c216  st   [$16]
              0b9d e0cb  jmp  y,$cb
              0b9e 00e6  ld   $e6
.sysSs#40:    0b9f c218  st   [$18]
              0ba0 c219  st   [$19]
              0ba1 e0cb  jmp  y,$cb
              0ba2 00e9  ld   $e9
sys_ResetWaveforms:
              0ba3 0118  ld   [$18]       ;X=4i
              0ba4 8200  adda ac
              0ba5 9200  adda ac,x
              0ba6 0118  ld   [$18]
              0ba7 de00  st   [y,x++]     ;Sawtooth: T[4i+0] = i
              0ba8 2020  anda $20         ;Triangle: T[4i+1] = 2i if i<32 else 127-2i
              0ba9 ecac  bne  $0bac
              0baa 0118  ld   [$18]
              0bab fcae  bra  $0bae
              0bac 8118  adda [$18]
              0bad 607f  xora $7f
              0bae de00  st   [y,x++]
              0baf 0118  ld   [$18]       ;Pulse: T[4i+2] = 0 if i<32 else 63
              0bb0 2020  anda $20
              0bb1 ecb4  bne  $0bb4
              0bb2 fcb5  bra  $0bb5
              0bb3 0000  ld   $00
              0bb4 003f  ld   $3f
              0bb5 de00  st   [y,x++]
              0bb6 0118  ld   [$18]       ;Sawtooth: T[4i+3] = i
              0bb7 ce00  st   [y,x]
              0bb8 8001  adda $01         ;i += 1
              0bb9 c218  st   [$18]
              0bba 6040  xora $40         ;For 64 iterations
              0bbb f0be  beq  $0bbe
              0bbc fcbf  bra  $0bbf
              0bbd 00fe  ld   $fe
              0bbe 0000  ld   $00
              0bbf 8116  adda [$16]
              0bc0 c216  st   [$16]
              0bc1 1403  ld   $03,y
              0bc2 e0cb  jmp  y,$cb
              0bc3 00e7  ld   $e7
sys_ShuffleNoise:
              0bc4 1118  ld   [$18],x     ;tmp = T[4j]
              0bc5 0d00  ld   [y,x]
              0bc6 c21d  st   [$1d]
              0bc7 1119  ld   [$19],x     ;T[4j] = T[4i]
              0bc8 0d00  ld   [y,x]
              0bc9 1118  ld   [$18],x
              0bca ce00  st   [y,x]
              0bcb 8200  adda ac          ;j += T[4i]
              0bcc 8200  adda ac
              0bcd 8118  adda [$18]
              0bce c218  st   [$18]
              0bcf 1119  ld   [$19],x     ;T[4i] = tmp
              0bd0 011d  ld   [$1d]
              0bd1 ce00  st   [y,x]
              0bd2 0119  ld   [$19]       ;i += 1
              0bd3 8004  adda $04
              0bd4 c219  st   [$19]
              0bd5 f0d8  beq  $0bd8       ;For 64 iterations
              0bd6 fcd9  bra  $0bd9
              0bd7 00fe  ld   $fe
              0bd8 0000  ld   $00
              0bd9 8116  adda [$16]
              0bda c216  st   [$16]
              0bdb 00e6  ld   $e6
              0bdc 1403  ld   $03,y
              0bdd e0cb  jmp  y,$cb
calli:        0bde 8003  adda $03
              0bdf c21a  st   [$1a]
              0be0 0117  ld   [$17]
              0be1 d61b  st   [$1b],y
              0be2 0d00  ld   [y,x]
              0be3 de00  st   [y,x++]
              0be4 a002  suba $02
              0be5 c216  st   [$16]
              0be6 0d00  ld   [y,x]
              0be7 1403  ld   $03,y
              0be8 e0ca  jmp  y,$ca
              0be9 c217  st   [$17]
cmphs:        0bea 1403  ld   $03,y
              0beb 0500  ld   [x]
              0bec 6119  xora [$19]
              0bed f4fe  bge  .cmphu#18
              0bee 0119  ld   [$19]
              0bef e8f2  blt  $0bf2
              0bf0 fcf3  bra  .cmphs#21
.cmphs#20:    0bf1 0001  ld   $01
              0bf2 00ff  ld   $ff
.cmphs#21:    0bf3 8500  adda [x]
              0bf4 c219  st   [$19]
              0bf5 e0ca  jmp  y,$ca
cmphu:        0bf6 1403  ld   $03,y
              0bf7 0500  ld   [x]
              0bf8 6119  xora [$19]
              0bf9 f4fe  bge  .cmphu#18
              0bfa 0119  ld   [$19]
              0bfb e8f1  blt  .cmphs#20
              0bfc fcf3  bra  .cmphs#21
              0bfd 00ff  ld   $ff
.cmphu#18:    0bfe e0cb  jmp  y,$cb
              0bff 00f5  ld   $f5
SYS_Sprite6_v3_64:
              0c00 1124  ld   [$24],x     ;Pixel data source address
              0c01 1525  ld   [$25],y
              0c02 0d00  ld   [y,x]       ;Next pixel or stop
              0c03 f411  bge  .sysDpx0
              0c04 de00  st   [y,x++]
              0c05 8119  adda [$19]       ;Adjust dst for convenience
              0c06 c219  st   [$19]
              0c07 0118  ld   [$18]
              0c08 8006  adda $06
              0c09 c218  st   [$18]
              0c0a 0124  ld   [$24]       ;Adjust src for convenience
              0c0b 8001  adda $01
              0c0c c224  st   [$24]
              0c0d 0200  nop
              0c0e 1403  ld   $03,y       ;Normal exit (no self-repeat)
              0c0f e0cb  jmp  y,$cb
              0c10 00ef  ld   $ef
.sysDpx0:     0c11 c226  st   [$26]       ;Gobble 6 pixels into buffer
              0c12 0d00  ld   [y,x]
              0c13 de00  st   [y,x++]
              0c14 c227  st   [$27]
              0c15 0d00  ld   [y,x]
              0c16 de00  st   [y,x++]
              0c17 c228  st   [$28]
              0c18 0d00  ld   [y,x]
              0c19 de00  st   [y,x++]
              0c1a c229  st   [$29]
              0c1b 0d00  ld   [y,x]
              0c1c de00  st   [y,x++]
              0c1d c22a  st   [$2a]
              0c1e 0d00  ld   [y,x]
              0c1f de00  st   [y,x++]
              0c20 c22b  st   [$2b]
              0c21 1118  ld   [$18],x     ;Screen memory destination address
              0c22 1519  ld   [$19],y
              0c23 0126  ld   [$26]       ;Write 6 pixels
              0c24 de00  st   [y,x++]
              0c25 0127  ld   [$27]
              0c26 de00  st   [y,x++]
              0c27 0128  ld   [$28]
              0c28 de00  st   [y,x++]
              0c29 0129  ld   [$29]
              0c2a de00  st   [y,x++]
              0c2b 012a  ld   [$2a]
              0c2c de00  st   [y,x++]
              0c2d 012b  ld   [$2b]
              0c2e de00  st   [y,x++]
              0c2f 0124  ld   [$24]       ;src += 6
              0c30 8006  adda $06
              0c31 c224  st   [$24]
              0c32 0119  ld   [$19]       ;dst += 256
              0c33 8001  adda $01
              0c34 c219  st   [$19]
              0c35 0116  ld   [$16]       ;Self-repeating SYS call
              0c36 a002  suba $02
              0c37 c216  st   [$16]
              0c38 1403  ld   $03,y
              0c39 e0cb  jmp  y,$cb
              0c3a 00e0  ld   $e0
              0c3b 0200  nop              ;5 fillers
              0c3c 0200  nop
              0c3d 0200  nop
              * 5 times
SYS_Sprite6x_v3_64:
              0c40 1124  ld   [$24],x     ;Pixel data source address
              0c41 1525  ld   [$25],y
              0c42 0d00  ld   [y,x]       ;Next pixel or stop
              0c43 f451  bge  .sysDpx1
              0c44 de00  st   [y,x++]
              0c45 8119  adda [$19]       ;Adjust dst for convenience
              0c46 c219  st   [$19]
              0c47 0118  ld   [$18]
              0c48 a006  suba $06
              0c49 c218  st   [$18]
              0c4a 0124  ld   [$24]       ;Adjust src for convenience
              0c4b 8001  adda $01
              0c4c c224  st   [$24]
              0c4d 0200  nop
              0c4e 1403  ld   $03,y       ;Normal exit (no self-repeat)
              0c4f e0cb  jmp  y,$cb
              0c50 00ef  ld   $ef
.sysDpx1:     0c51 c22b  st   [$2b]       ;Gobble 6 pixels into buffer (backwards)
              0c52 0d00  ld   [y,x]
              0c53 de00  st   [y,x++]
              0c54 c22a  st   [$2a]
              0c55 0d00  ld   [y,x]
              0c56 de00  st   [y,x++]
              0c57 c229  st   [$29]
              0c58 0d00  ld   [y,x]
              0c59 de00  st   [y,x++]
              0c5a c228  st   [$28]
              0c5b 0d00  ld   [y,x]
              0c5c de00  st   [y,x++]
              0c5d c227  st   [$27]
              0c5e 0d00  ld   [y,x]
              0c5f de00  st   [y,x++]
              0c60 1118  ld   [$18],x     ;Screen memory destination address
              0c61 1519  ld   [$19],y
              0c62 de00  st   [y,x++]     ;Write 6 pixels
              0c63 0127  ld   [$27]
              0c64 de00  st   [y,x++]
              0c65 0128  ld   [$28]
              0c66 de00  st   [y,x++]
              0c67 0129  ld   [$29]
              0c68 de00  st   [y,x++]
              0c69 012a  ld   [$2a]
              0c6a de00  st   [y,x++]
              0c6b 012b  ld   [$2b]
              0c6c de00  st   [y,x++]
              0c6d 0124  ld   [$24]       ;src += 6
              0c6e 8006  adda $06
              0c6f c224  st   [$24]
              0c70 0119  ld   [$19]       ;dst += 256
              0c71 8001  adda $01
              0c72 c219  st   [$19]
              0c73 0116  ld   [$16]       ;Self-repeating SYS call
              0c74 a002  suba $02
              0c75 c216  st   [$16]
              0c76 1403  ld   $03,y
              0c77 e0cb  jmp  y,$cb
              0c78 00e1  ld   $e1
              0c79 0200  nop              ;7 fillers
              0c7a 0200  nop
              0c7b 0200  nop
              * 7 times
SYS_Sprite6y_v3_64:
              0c80 1124  ld   [$24],x     ;Pixel data source address
              0c81 1525  ld   [$25],y
              0c82 0d00  ld   [y,x]       ;Next pixel or stop
              0c83 f493  bge  .sysDpx2
              0c84 de00  st   [y,x++]
              0c85 60ff  xora $ff         ;Adjust dst for convenience
              0c86 8001  adda $01
              0c87 8119  adda [$19]
              0c88 c219  st   [$19]
              0c89 0118  ld   [$18]
              0c8a 8006  adda $06
              0c8b c218  st   [$18]
              0c8c 0124  ld   [$24]       ;Adjust src for convenience
              0c8d 8001  adda $01
              0c8e c224  st   [$24]
              0c8f 0200  nop
              0c90 1403  ld   $03,y       ;Normal exit (no self-repeat)
              0c91 e0cb  jmp  y,$cb
              0c92 00ee  ld   $ee
.sysDpx2:     0c93 c226  st   [$26]       ;Gobble 6 pixels into buffer
              0c94 0d00  ld   [y,x]
              0c95 de00  st   [y,x++]
              0c96 c227  st   [$27]
              0c97 0d00  ld   [y,x]
              0c98 de00  st   [y,x++]
              0c99 c228  st   [$28]
              0c9a 0d00  ld   [y,x]
              0c9b de00  st   [y,x++]
              0c9c c229  st   [$29]
              0c9d 0d00  ld   [y,x]
              0c9e de00  st   [y,x++]
              0c9f c22a  st   [$2a]
              0ca0 0d00  ld   [y,x]
              0ca1 de00  st   [y,x++]
              0ca2 c22b  st   [$2b]
              0ca3 1118  ld   [$18],x     ;Screen memory destination address
              0ca4 1519  ld   [$19],y
              0ca5 0126  ld   [$26]       ;Write 6 pixels
              0ca6 de00  st   [y,x++]
              0ca7 0127  ld   [$27]
              0ca8 de00  st   [y,x++]
              0ca9 0128  ld   [$28]
              0caa de00  st   [y,x++]
              0cab 0129  ld   [$29]
              0cac de00  st   [y,x++]
              0cad 012a  ld   [$2a]
              0cae de00  st   [y,x++]
              0caf 012b  ld   [$2b]
              0cb0 de00  st   [y,x++]
              0cb1 0124  ld   [$24]       ;src += 6
              0cb2 8006  adda $06
              0cb3 c224  st   [$24]
              0cb4 0119  ld   [$19]       ;dst -= 256
              0cb5 a001  suba $01
              0cb6 c219  st   [$19]
              0cb7 0116  ld   [$16]       ;Self-repeating SYS call
              0cb8 a002  suba $02
              0cb9 c216  st   [$16]
              0cba 1403  ld   $03,y
              0cbb e0cb  jmp  y,$cb
              0cbc 00e0  ld   $e0
              0cbd 0200  nop              ;3 fillers
              0cbe 0200  nop
              0cbf 0200  nop
SYS_Sprite6xy_v3_64:
              0cc0 1124  ld   [$24],x     ;Pixel data source address
              0cc1 1525  ld   [$25],y
              0cc2 0d00  ld   [y,x]       ;Next pixel or stop
              0cc3 f4d3  bge  .sysDpx3
              0cc4 de00  st   [y,x++]
              0cc5 60ff  xora $ff         ;Adjust dst for convenience
              0cc6 8001  adda $01
              0cc7 8119  adda [$19]
              0cc8 c219  st   [$19]
              0cc9 0118  ld   [$18]
              0cca a006  suba $06
              0ccb c218  st   [$18]
              0ccc 0124  ld   [$24]       ;Adjust src for convenience
              0ccd 8001  adda $01
              0cce c224  st   [$24]
              0ccf 0200  nop
              0cd0 1403  ld   $03,y       ;Normal exit (no self-repeat)
              0cd1 e0cb  jmp  y,$cb
              0cd2 00ee  ld   $ee
.sysDpx3:     0cd3 c22b  st   [$2b]       ;Gobble 6 pixels into buffer (backwards)
              0cd4 0d00  ld   [y,x]
              0cd5 de00  st   [y,x++]
              0cd6 c22a  st   [$2a]
              0cd7 0d00  ld   [y,x]
              0cd8 de00  st   [y,x++]
              0cd9 c229  st   [$29]
              0cda 0d00  ld   [y,x]
              0cdb de00  st   [y,x++]
              0cdc c228  st   [$28]
              0cdd 0d00  ld   [y,x]
              0cde de00  st   [y,x++]
              0cdf c227  st   [$27]
              0ce0 0d00  ld   [y,x]
              0ce1 de00  st   [y,x++]
              0ce2 1118  ld   [$18],x     ;Screen memory destination address
              0ce3 1519  ld   [$19],y
              0ce4 de00  st   [y,x++]     ;Write 6 pixels
              0ce5 0127  ld   [$27]
              0ce6 de00  st   [y,x++]
              0ce7 0128  ld   [$28]
              0ce8 de00  st   [y,x++]
              0ce9 0129  ld   [$29]
              0cea de00  st   [y,x++]
              0ceb 012a  ld   [$2a]
              0cec de00  st   [y,x++]
              0ced 012b  ld   [$2b]
              0cee de00  st   [y,x++]
              0cef 0124  ld   [$24]       ;src += 6
              0cf0 8006  adda $06
              0cf1 c224  st   [$24]
              0cf2 0119  ld   [$19]       ;dst -= 256
              0cf3 a001  suba $01
              0cf4 c219  st   [$19]
              0cf5 0116  ld   [$16]       ;Self-repeating SYS call
              0cf6 a002  suba $02
              0cf7 c216  st   [$16]
              0cf8 1403  ld   $03,y
              0cf9 e0cb  jmp  y,$cb
              0cfa 00e1  ld   $e1
sys_ExpanderControl:
              0cfb 0118  ld   [$18]
              0cfc 20fc  anda $fc         ;Safety (SCLK=0)
              0cfd d22b  st   [$2b],x     ;Set control register
              0cfe 1519  ld   [$19],y
              0cff cd00  ctrl y,x
              0d00 0127  ld   [$27]       ;Prepare SYS_SpiExchangeBytes
              0d01 ec04  bne  $0d04
              0d02 fc04  bra  $0d04
              0d03 0125  ld   [$25]
              0d04 c227  st   [$27]
              0d05 0200  nop
              0d06 1403  ld   $03,y
              0d07 e0cb  jmp  y,$cb
              0d08 00ef  ld   $ef
sys_SpiExchangeBytes:
              0d09 1525  ld   [$25],y
              0d0a 0d00  ld   [y,x]
              0d0b d61d  st   [$1d],y     ;Bit 7
              0d0c 112b  ld   [$2b],x
              0d0d dd00  ctrl y,x++       ;Set MOSI
              0d0e dd00  ctrl y,x++       ;Raise SCLK
              0d0f 0100  ld   [$00]       ;Get MISO
              0d10 200f  anda $0f
              0d11 f014  beq  $0d14
              0d12 fc14  bra  $0d14
              0d13 0001  ld   $01
              0d14 cd00  ctrl y,x         ;Lower SCLK
              0d15 811d  adda [$1d]       ;Shift
              0d16 811d  adda [$1d]
              0d17 d61d  st   [$1d],y     ;Bit 6
              0d18 112b  ld   [$2b],x
              0d19 dd00  ctrl y,x++       ;Set MOSI
              0d1a dd00  ctrl y,x++       ;Raise SCLK
              0d1b 0100  ld   [$00]       ;Get MISO
              0d1c 200f  anda $0f
              0d1d f020  beq  $0d20
              0d1e fc20  bra  $0d20
              0d1f 0001  ld   $01
              0d20 cd00  ctrl y,x         ;Lower SCLK
              0d21 811d  adda [$1d]       ;Shift
              0d22 811d  adda [$1d]
              0d23 d61d  st   [$1d],y     ;Bit 5
              0d24 112b  ld   [$2b],x
              0d25 dd00  ctrl y,x++       ;Set MOSI
              0d26 dd00  ctrl y,x++       ;Raise SCLK
              0d27 0100  ld   [$00]       ;Get MISO
              0d28 200f  anda $0f
              0d29 f02c  beq  $0d2c
              0d2a fc2c  bra  $0d2c
              0d2b 0001  ld   $01
              0d2c cd00  ctrl y,x         ;Lower SCLK
              0d2d 811d  adda [$1d]       ;Shift
              0d2e 811d  adda [$1d]
              0d2f d61d  st   [$1d],y     ;Bit 4
              0d30 112b  ld   [$2b],x
              0d31 dd00  ctrl y,x++       ;Set MOSI
              0d32 dd00  ctrl y,x++       ;Raise SCLK
              0d33 0100  ld   [$00]       ;Get MISO
              0d34 200f  anda $0f
              0d35 f038  beq  $0d38
              0d36 fc38  bra  $0d38
              0d37 0001  ld   $01
              0d38 cd00  ctrl y,x         ;Lower SCLK
              0d39 811d  adda [$1d]       ;Shift
              0d3a 811d  adda [$1d]
              0d3b d61d  st   [$1d],y     ;Bit 3
              0d3c 112b  ld   [$2b],x
              0d3d dd00  ctrl y,x++       ;Set MOSI
              0d3e dd00  ctrl y,x++       ;Raise SCLK
              0d3f 0100  ld   [$00]       ;Get MISO
              0d40 200f  anda $0f
              0d41 f044  beq  $0d44
              0d42 fc44  bra  $0d44
              0d43 0001  ld   $01
              0d44 cd00  ctrl y,x         ;Lower SCLK
              0d45 811d  adda [$1d]       ;Shift
              0d46 811d  adda [$1d]
              0d47 d61d  st   [$1d],y     ;Bit 2
              0d48 112b  ld   [$2b],x
              0d49 dd00  ctrl y,x++       ;Set MOSI
              0d4a dd00  ctrl y,x++       ;Raise SCLK
              0d4b 0100  ld   [$00]       ;Get MISO
              0d4c 200f  anda $0f
              0d4d f050  beq  $0d50
              0d4e fc50  bra  $0d50
              0d4f 0001  ld   $01
              0d50 cd00  ctrl y,x         ;Lower SCLK
              0d51 811d  adda [$1d]       ;Shift
              0d52 811d  adda [$1d]
              0d53 d61d  st   [$1d],y     ;Bit 1
              0d54 112b  ld   [$2b],x
              0d55 dd00  ctrl y,x++       ;Set MOSI
              0d56 dd00  ctrl y,x++       ;Raise SCLK
              0d57 0100  ld   [$00]       ;Get MISO
              0d58 200f  anda $0f
              0d59 f05c  beq  $0d5c
              0d5a fc5c  bra  $0d5c
              0d5b 0001  ld   $01
              0d5c cd00  ctrl y,x         ;Lower SCLK
              0d5d 811d  adda [$1d]       ;Shift
              0d5e 811d  adda [$1d]
              0d5f d61d  st   [$1d],y     ;Bit 0
              0d60 112b  ld   [$2b],x
              0d61 dd00  ctrl y,x++       ;Set MOSI
              0d62 dd00  ctrl y,x++       ;Raise SCLK
              0d63 0100  ld   [$00]       ;Get MISO
              0d64 200f  anda $0f
              0d65 f068  beq  $0d68
              0d66 fc68  bra  $0d68
              0d67 0001  ld   $01
              0d68 cd00  ctrl y,x         ;Lower SCLK
              0d69 811d  adda [$1d]       ;Shift
              0d6a 811d  adda [$1d]
              0d6b 1124  ld   [$24],x     ;Store received byte
              0d6c 1527  ld   [$27],y
              0d6d ce00  st   [y,x]
              0d6e 0124  ld   [$24]       ;Advance pointer
              0d6f 8001  adda $01
              0d70 c224  st   [$24]
              0d71 6126  xora [$26]       ;Reached end?
              0d72 f079  beq  .sysSpi#125
              0d73 0116  ld   [$16]       ;Self-repeating SYS call
              0d74 a002  suba $02
              0d75 c216  st   [$16]
              0d76 1403  ld   $03,y
              0d77 e0cb  jmp  y,$cb
              0d78 00be  ld   $be
.sysSpi#125:  0d79 1403  ld   $03,y       ;Continue program
              0d7a e0cb  jmp  y,$cb
              0d7b 00bf  ld   $bf
sys_v6502:    0d7c d605  st   [$05],y     ;Activate v6502
              0d7d 00f5  ld   $f5
              0d7e e0ff  jmp  y,$ff       ;Transfer control in the same time slice
              0d7f 8115  adda [$15]
v6502_ror:    0d80 1525  ld   [$25],y
              0d81 00fc  ld   $fc
              0d82 8115  adda [$15]
              0d83 e897  blt  .recheck17
              0d84 0127  ld   [$27]       ;Transfer C to "bit 8"
              0d85 2001  anda $01
              0d86 807f  adda $7f
              0d87 2080  anda $80
              0d88 c219  st   [$19]
              0d89 0127  ld   [$27]       ;Transfer bit 0 to C
              0d8a 20fe  anda $fe
              0d8b c227  st   [$27]
              0d8c 0d00  ld   [y,x]
              0d8d 2001  anda $01
              0d8e 4127  ora  [$27]
              0d8f c227  st   [$27]
              0d90 00ee  ld   $ee         ;Shift table lookup
              0d91 c21d  st   [$1d]
              0d92 0d00  ld   [y,x]
              0d93 20fe  anda $fe
              0d94 1405  ld   $05,y
              0d95 e200  jmp  y,ac
              0d96 fcff  bra  $ff         ;bra $05ff
.recheck17:   0d97 140e  ld   $0e,y
              0d98 e0f2  jmp  y,$f2
              0d99 00f6  ld   $f6
v6502_lsr:    0d9a 1525  ld   [$25],y
              0d9b 0127  ld   [$27]       ;Transfer bit 0 to C
              0d9c 20fe  anda $fe
              0d9d c227  st   [$27]
              0d9e 0d00  ld   [y,x]
              0d9f 2001  anda $01
              0da0 4127  ora  [$27]
              0da1 c227  st   [$27]
              0da2 00e7  ld   $e7         ;Shift table lookup
              0da3 c21d  st   [$1d]
              0da4 0d00  ld   [y,x]
              0da5 20fe  anda $fe
              0da6 1405  ld   $05,y
              0da7 e200  jmp  y,ac
              0da8 fcff  bra  $ff         ;bra $05ff
v6502_rol:    0da9 1525  ld   [$25],y
              0daa 0d00  ld   [y,x]
              0dab 2080  anda $80
              0dac c21d  st   [$1d]
              0dad 0127  ld   [$27]
              0dae 2001  anda $01
.rol18:       0daf 8d00  adda [y,x]
              0db0 8d00  adda [y,x]
              0db1 ce00  st   [y,x]
              0db2 c228  st   [$28]       ;Z flag
              0db3 c229  st   [$29]       ;N flag
              0db4 0127  ld   [$27]       ;C flag
              0db5 20fe  anda $fe
              0db6 111d  ld   [$1d],x
              0db7 4500  ora  [x]
              0db8 c227  st   [$27]
              0db9 140e  ld   $0e,y
              0dba 00f0  ld   $f0
              0dbb e020  jmp  y,$20
v6502_asl:    0dbc 1525  ld   [$25],y
              0dbd 0d00  ld   [y,x]
              0dbe 2080  anda $80
              0dbf c21d  st   [$1d]
              0dc0 fcaf  bra  .rol18
              0dc1 0000  ld   $00
v6502_jmp1:   0dc2 0200  nop
              0dc3 0124  ld   [$24]
              0dc4 c21a  st   [$1a]
              0dc5 0125  ld   [$25]
              0dc6 c21b  st   [$1b]
              0dc7 140e  ld   $0e,y
              0dc8 e020  jmp  y,$20
              0dc9 00f6  ld   $f6
v6502_jmp2:   0dca 0200  nop
              0dcb 1525  ld   [$25],y
              0dcc 0d00  ld   [y,x]
              0dcd de00  st   [y,x++]     ;Wrap around: bug compatible with NMOS
              0dce c21a  st   [$1a]
              0dcf 0d00  ld   [y,x]
              0dd0 c21b  st   [$1b]
              0dd1 140e  ld   $0e,y
              0dd2 e020  jmp  y,$20
              0dd3 00f5  ld   $f5
v6502_pla:    0dd4 011c  ld   [$1c]
              0dd5 1200  ld   ac,x
              0dd6 8001  adda $01
              0dd7 c21c  st   [$1c]
              0dd8 0500  ld   [x]
              0dd9 c218  st   [$18]
              0dda c228  st   [$28]       ;Z flag
              0ddb c229  st   [$29]       ;N flag
              0ddc 140e  ld   $0e,y
              0ddd 00f4  ld   $f4
              0dde e020  jmp  y,$20
v6502_pha:    0ddf 140e  ld   $0e,y
              0de0 011c  ld   [$1c]
              0de1 a001  suba $01
              0de2 d21c  st   [$1c],x
              0de3 0118  ld   [$18]
              0de4 c600  st   [x]
              0de5 e020  jmp  y,$20
              0de6 00f6  ld   $f6
v6502_brk:    0de7 0002  ld   $02         ;Switch to vCPU
              0de8 c205  st   [$05]
              0de9 0000  ld   $00
              0dea c219  st   [$19]
              0deb 1403  ld   $03,y
              0dec 00fb  ld   $fb
              0ded e0cb  jmp  y,$cb
              0dee 0200  nop
              0def 0200  nop
              0df0 0200  nop
              * 17 times
v6502_ENTER:  0dff fc22  bra  v6502_next2 ;v6502 primary entry point
              0e00 a006  suba $06
              0e01 fce0  bra  v6502_modeIZX
              0e02 fc42  bra  v6502_modeIMM
              0e03 fc58  bra  v6502_modeIMP
              0e04 fc5d  bra  v6502_modeZP
              0e05 fc5d  bra  v6502_modeZP
              0e06 fc5d  bra  v6502_modeZP
              0e07 fc58  bra  v6502_modeIMP
              0e08 fc58  bra  v6502_modeIMP
              0e09 fc42  bra  v6502_modeIMM
              0e0a fc52  bra  v6502_modeACC
              0e0b fc58  bra  v6502_modeIMP
              0e0c fc78  bra  v6502_modeABS
              0e0d fc78  bra  v6502_modeABS
              0e0e fc78  bra  v6502_modeABS
              0e0f fc58  bra  v6502_modeIMP
              0e10 fccf  bra  v6502_modeREL
              0e11 fcab  bra  v6502_modeIZY
              0e12 fc42  bra  v6502_modeIMM
              0e13 fc58  bra  v6502_modeIMP
              0e14 fc5b  bra  v6502_modeZPX
              0e15 fc5b  bra  v6502_modeZPX
              0e16 fc5b  bra  v6502_modeZPX
              0e17 fc58  bra  v6502_modeIMP
              0e18 fc58  bra  v6502_modeIMP
              0e19 fc7b  bra  v6502_modeABY
              0e1a fc58  bra  v6502_modeIMP
              0e1b fc58  bra  v6502_modeIMP
              0e1c fc7a  bra  v6502_modeABX
              0e1d fc7a  bra  v6502_modeABX
              0e1e fc7a  bra  v6502_modeABX
              0e1f fc58  bra  v6502_modeIMP
v6502_next:   0e20 8115  adda [$15]
              0e21 e83a  blt  v6502_exitBefore ;No more ticks
v6502_next2:  0e22 c215  st   [$15]
              0e23 111a  ld   [$1a],x
              0e24 151b  ld   [$1b],y
              0e25 0d00  ld   [y,x]       ;Fetch IR
              0e26 c226  st   [$26]
              0e27 011a  ld   [$1a]       ;PC++
              0e28 8001  adda $01
              0e29 d21a  st   [$1a],x
              0e2a f02d  beq  $0e2d
              0e2b fc2e  bra  $0e2e
              0e2c 0000  ld   $00
              0e2d 0001  ld   $01
              0e2e 811b  adda [$1b]
              0e2f d61b  st   [$1b],y
              0e30 0126  ld   [$26]       ;Get addressing mode
              0e31 201f  anda $1f
              0e32 fe00  bra  ac
              0e33 fc34  bra  .next20
.next20:      0e34 0d00  ld   [y,x]       ;Fetch L
v6502_mode0:  0e35 0126  ld   [$26]       ;xxx0000
              0e36 e845  blt  .imm24
              0e37 011b  ld   [$1b]
              0e38 fcf2  bra  v6502_check
              0e39 00f3  ld   $f3
v6502_exitBefore:
              0e3a 8013  adda $13         ;Exit BEFORE fetch
              0e3b e43b  bgt  $0e3b       ;Resync
              0e3c a001  suba $01
              0e3d 000d  ld   $0d         ;Set entry point to before 'fetch'
              0e3e c205  st   [$05]
              0e3f 1401  ld   $01,y
              0e40 e11e  jmp  y,[$1e]     ;To video driver
              0e41 0000  ld   $00
v6502_modeIMM:
              0e42 0200  nop
              0e43 0200  nop
              0e44 011b  ld   [$1b]       ;Copy PC
.imm24:       0e45 c225  st   [$25]
              0e46 011a  ld   [$1a]
              0e47 d224  st   [$24],x
              0e48 8001  adda $01         ;PC++
              0e49 c21a  st   [$1a]
              0e4a f04d  beq  $0e4d
              0e4b fc4e  bra  $0e4e
              0e4c 0000  ld   $00
              0e4d 0001  ld   $01
              0e4e 811b  adda [$1b]
              0e4f c21b  st   [$1b]
              0e50 fcf2  bra  v6502_check
              0e51 00ee  ld   $ee
v6502_modeACC:
              0e52 0018  ld   $18         ;Address of AC
              0e53 d224  st   [$24],x
              0e54 0000  ld   $00
              0e55 c225  st   [$25]
              0e56 00f2  ld   $f2
              0e57 fcf2  bra  v6502_check
v6502_modeILL:
v6502_modeIMP:
              0e58 0200  nop
              0e59 fcf2  bra  v6502_check
              0e5a 00f4  ld   $f4
v6502_modeZPX:
              0e5b fc5f  bra  .zp23
              0e5c 812a  adda [$2a]
v6502_modeZP: 0e5d fc5f  bra  .zp23
              0e5e 0200  nop
.zp23:        0e5f d224  st   [$24],x
              0e60 0000  ld   $00         ;H=0
              0e61 c225  st   [$25]
              0e62 0001  ld   $01         ;PC++
              0e63 811a  adda [$1a]
              0e64 c21a  st   [$1a]
              0e65 f068  beq  $0e68
              0e66 fc69  bra  $0e69
              0e67 0000  ld   $00
              0e68 0001  ld   $01
              0e69 811b  adda [$1b]
              0e6a c21b  st   [$1b]
              0e6b fcf2  bra  v6502_check
              0e6c 00ee  ld   $ee
.retry28:     0e6d f070  beq  $0e70       ;PC--
              0e6e fc71  bra  $0e71
              0e6f 0000  ld   $00
              0e70 00ff  ld   $ff
              0e71 811b  adda [$1b]
              0e72 c21b  st   [$1b]
              0e73 011a  ld   [$1a]
              0e74 a001  suba $01
              0e75 c21a  st   [$1a]
              0e76 fc20  bra  v6502_next  ;Retry until sufficient time
              0e77 00ed  ld   $ed
v6502_modeABS:
              0e78 fc7d  bra  .abs23
              0e79 0000  ld   $00
v6502_modeABX:
              0e7a fc7d  bra  .abs23
v6502_modeABY:
              0e7b 012a  ld   [$2a]
              0e7c 012b  ld   [$2b]
.abs23:       0e7d c224  st   [$24]
              0e7e 00f3  ld   $f3
              0e7f 8115  adda [$15]
              0e80 e86d  blt  .retry28
              0e81 011a  ld   [$1a]
              0e82 0126  ld   [$26]       ;Special case $BE: LDX $DDDD,Y (we got X in ADL)
              0e83 60be  xora $be
              0e84 f087  beq  $0e87
              0e85 fc88  bra  $0e88
              0e86 0124  ld   [$24]
              0e87 012b  ld   [$2b]
              0e88 8d00  adda [y,x]       ;Fetch and add L
              0e89 c224  st   [$24]
              0e8a e88e  blt  .abs37      ;Carry?
              0e8b ad00  suba [y,x]
              0e8c fc90  bra  .abs39
              0e8d 4d00  ora  [y,x]
.abs37:       0e8e 2d00  anda [y,x]
              0e8f 0200  nop
.abs39:       0e90 3080  anda $80,x
              0e91 0500  ld   [x]
              0e92 c225  st   [$25]
              0e93 011a  ld   [$1a]       ;PC++
              0e94 8001  adda $01
              0e95 d21a  st   [$1a],x
              0e96 f099  beq  $0e99
              0e97 fc9a  bra  $0e9a
              0e98 0000  ld   $00
              0e99 0001  ld   $01
              0e9a 811b  adda [$1b]
              0e9b d61b  st   [$1b],y
              0e9c 0d00  ld   [y,x]       ;Fetch H
              0e9d 8125  adda [$25]
              0e9e c225  st   [$25]
              0e9f 011a  ld   [$1a]       ;PC++
              0ea0 8001  adda $01
              0ea1 c21a  st   [$1a]
              0ea2 f0a5  beq  $0ea5
              0ea3 fca6  bra  $0ea6
              0ea4 0000  ld   $00
              0ea5 0001  ld   $01
              0ea6 811b  adda [$1b]
              0ea7 c21b  st   [$1b]
              0ea8 1124  ld   [$24],x
              0ea9 fcf2  bra  v6502_check
              0eaa 00e0  ld   $e0
v6502_modeIZY:
              0eab 1200  ld   ac,x
              0eac 1400  ld   $00,y
              0ead 00f8  ld   $f8
              0eae 8115  adda [$15]
              0eaf 0200  nop
              0eb0 e86d  blt  .retry28
              0eb1 011a  ld   [$1a]
              0eb2 8001  adda $01         ;PC++
              0eb3 c21a  st   [$1a]
              0eb4 f0b7  beq  $0eb7
              0eb5 fcb8  bra  $0eb8
              0eb6 0000  ld   $00
              0eb7 0001  ld   $01
              0eb8 811b  adda [$1b]
              0eb9 c21b  st   [$1b]
              0eba 0d00  ld   [y,x]       ;Read word from zero-page
              0ebb de00  st   [y,x++]
              0ebc c224  st   [$24]
              0ebd 0d00  ld   [y,x]
              0ebe c225  st   [$25]
              0ebf 012b  ld   [$2b]       ;Add Y
              0ec0 8124  adda [$24]
              0ec1 c224  st   [$24]
              0ec2 e8c6  blt  .izy45      ;Carry?
              0ec3 a12b  suba [$2b]
              0ec4 fcc8  bra  .izy47
              0ec5 412b  ora  [$2b]
.izy45:       0ec6 212b  anda [$2b]
              0ec7 0200  nop
.izy47:       0ec8 3080  anda $80,x
              0ec9 0500  ld   [x]
              0eca 8125  adda [$25]
              0ecb c225  st   [$25]
              0ecc 1124  ld   [$24],x
              0ecd fcf2  bra  v6502_check
              0ece 00e5  ld   $e5
v6502_modeREL:
              0ecf d224  st   [$24],x     ;Offset
              0ed0 e8d3  blt  $0ed3       ;Sign extend
              0ed1 fcd4  bra  $0ed4
              0ed2 0000  ld   $00
              0ed3 00ff  ld   $ff
              0ed4 c225  st   [$25]
              0ed5 011a  ld   [$1a]       ;PC++
              0ed6 8001  adda $01
              0ed7 c21a  st   [$1a]
              0ed8 f0db  beq  $0edb
              0ed9 fcdc  bra  $0edc
              0eda 0000  ld   $00
              0edb 0001  ld   $01
              0edc 811b  adda [$1b]
              0edd c21b  st   [$1b]
              0ede fcf2  bra  v6502_check
              0edf 00ee  ld   $ee
v6502_modeIZX:
              0ee0 812a  adda [$2a]       ;Add X
              0ee1 c21d  st   [$1d]
              0ee2 9001  adda $01,x       ;Read word from zero-page
              0ee3 0500  ld   [x]
              0ee4 c225  st   [$25]
              0ee5 111d  ld   [$1d],x
              0ee6 0500  ld   [x]
              0ee7 d224  st   [$24],x
              0ee8 011a  ld   [$1a]       ;PC++
              0ee9 8001  adda $01
              0eea c21a  st   [$1a]
              0eeb f0ee  beq  $0eee
              0eec fcef  bra  $0eef
              0eed 0000  ld   $00
              0eee 0001  ld   $01
              0eef 811b  adda [$1b]
              0ef0 c21b  st   [$1b]
              0ef1 00ed  ld   $ed
v6502_check:  0ef2 8115  adda [$15]
              0ef3 e8f8  blt  v6502_exitAfter ;No more ticks
              0ef4 c215  st   [$15]
              0ef5 140f  ld   $0f,y
              0ef6 e126  jmp  y,[$26]
              0ef7 fcff  bra  $ff
v6502_exitAfter:
              0ef8 8013  adda $13         ;Exit AFTER fetch
              0ef9 e4f9  bgt  $0ef9       ;Resync
              0efa a001  suba $01
              0efb 0010  ld   $10         ;Set entry point to before 'execute'
              0efc c205  st   [$05]
              0efd 1401  ld   $01,y
              0efe e11e  jmp  y,[$1e]     ;To video driver
              0eff 0000  ld   $00
v6502_execute:
              0f00 00fd  ld   $fd
              0f01 0089  ld   $89
              0f02 00fd  ld   $fd
              0f03 00fd  ld   $fd
              0f04 00fd  ld   $fd
              0f05 0089  ld   $89
              0f06 00f1  ld   $f1
              0f07 00fd  ld   $fd
              0f08 00f3  ld   $f3
              0f09 0089  ld   $89
              0f0a 00f1  ld   $f1
              0f0b 00fd  ld   $fd
              0f0c 00fd  ld   $fd
              0f0d 0089  ld   $89
              0f0e 00f1  ld   $f1
              0f0f 00fd  ld   $fd
              0f10 003f  ld   $3f
              0f11 0089  ld   $89
              0f12 00fd  ld   $fd
              0f13 00fd  ld   $fd
              0f14 00fd  ld   $fd
              0f15 0089  ld   $89
              0f16 00f1  ld   $f1
              0f17 00fd  ld   $fd
              0f18 0036  ld   $36
              0f19 0089  ld   $89
              0f1a 00fd  ld   $fd
              0f1b 00fd  ld   $fd
              0f1c 00fd  ld   $fd
              0f1d 0089  ld   $89
              0f1e 00f1  ld   $f1
              0f1f 00fd  ld   $fd
              0f20 009a  ld   $9a
              0f21 0085  ld   $85
              0f22 00fd  ld   $fd
              0f23 00fd  ld   $fd
              0f24 00f5  ld   $f5
              0f25 0085  ld   $85
              0f26 00f7  ld   $f7
              0f27 00fd  ld   $fd
              0f28 00f9  ld   $f9
              0f29 0085  ld   $85
              0f2a 00f7  ld   $f7
              0f2b 00fd  ld   $fd
              0f2c 00f5  ld   $f5
              0f2d 0085  ld   $85
              0f2e 00f7  ld   $f7
              0f2f 00fd  ld   $fd
              0f30 0042  ld   $42
              0f31 0085  ld   $85
              0f32 00fd  ld   $fd
              0f33 00fd  ld   $fd
              0f34 00fd  ld   $fd
              0f35 0085  ld   $85
              0f36 00f7  ld   $f7
              0f37 00fd  ld   $fd
              0f38 0038  ld   $38
              0f39 0085  ld   $85
              0f3a 00fd  ld   $fd
              0f3b 00fd  ld   $fd
              0f3c 00fd  ld   $fd
              0f3d 0085  ld   $85
              0f3e 00f7  ld   $f7
              0f3f 00fd  ld   $fd
              0f40 00d3  ld   $d3
              0f41 008c  ld   $8c
              0f42 00fd  ld   $fd
              0f43 00fd  ld   $fd
              0f44 00fd  ld   $fd
              0f45 008c  ld   $8c
              0f46 00d7  ld   $d7
              0f47 00fd  ld   $fd
              0f48 00d9  ld   $d9
              0f49 008c  ld   $8c
              0f4a 00d7  ld   $d7
              0f4b 00fd  ld   $fd
              0f4c 0096  ld   $96
              0f4d 008c  ld   $8c
              0f4e 00d7  ld   $d7
              0f4f 00fd  ld   $fd
              0f50 0045  ld   $45
              0f51 008c  ld   $8c
              0f52 00fd  ld   $fd
              0f53 00fd  ld   $fd
              0f54 00fd  ld   $fd
              0f55 008c  ld   $8c
              0f56 00d7  ld   $d7
              0f57 00fd  ld   $fd
              0f58 00db  ld   $db
              0f59 008c  ld   $8c
              0f5a 00fd  ld   $fd
              0f5b 00fd  ld   $fd
              0f5c 00fd  ld   $fd
              0f5d 008c  ld   $8c
              0f5e 00d7  ld   $d7
              0f5f 00fd  ld   $fd
              0f60 00dd  ld   $dd
              0f61 0001  ld   $01
              0f62 00fd  ld   $fd
              0f63 00fd  ld   $fd
              0f64 00fd  ld   $fd
              0f65 0001  ld   $01
              0f66 00d5  ld   $d5
              0f67 00fd  ld   $fd
              0f68 00df  ld   $df
              0f69 0001  ld   $01
              0f6a 00d5  ld   $d5
              0f6b 00fd  ld   $fd
              0f6c 0098  ld   $98
              0f6d 0001  ld   $01
              0f6e 00d5  ld   $d5
              0f6f 00fd  ld   $fd
              0f70 0049  ld   $49
              0f71 0001  ld   $01
              0f72 00fd  ld   $fd
              0f73 00fd  ld   $fd
              0f74 00fd  ld   $fd
              0f75 0001  ld   $01
              0f76 00d5  ld   $d5
              0f77 00fd  ld   $fd
              0f78 00e1  ld   $e1
              0f79 0001  ld   $01
              0f7a 00fd  ld   $fd
              0f7b 00fd  ld   $fd
              0f7c 00fd  ld   $fd
              0f7d 0001  ld   $01
              0f7e 00d5  ld   $d5
              0f7f 00fd  ld   $fd
              0f80 00fd  ld   $fd
              0f81 00c1  ld   $c1
              0f82 00fd  ld   $fd
              0f83 00fd  ld   $fd
              0f84 00c7  ld   $c7
              0f85 00c1  ld   $c1
              0f86 00c3  ld   $c3
              0f87 00fd  ld   $fd
              0f88 007f  ld   $7f
              0f89 00fd  ld   $fd
              0f8a 00cd  ld   $cd
              0f8b 00fd  ld   $fd
              0f8c 00c7  ld   $c7
              0f8d 00c1  ld   $c1
              0f8e 00c3  ld   $c3
              0f8f 00fd  ld   $fd
              0f90 004d  ld   $4d
              0f91 00c1  ld   $c1
              0f92 00fd  ld   $fd
              0f93 00fd  ld   $fd
              0f94 00c7  ld   $c7
              0f95 00c1  ld   $c1
              0f96 00c5  ld   $c5
              0f97 00fd  ld   $fd
              0f98 00cf  ld   $cf
              0f99 00c1  ld   $c1
              0f9a 00e3  ld   $e3
              0f9b 00fd  ld   $fd
              0f9c 00fd  ld   $fd
              0f9d 00c1  ld   $c1
              0f9e 00fd  ld   $fd
              0f9f 00fd  ld   $fd
              0fa0 00bf  ld   $bf
              0fa1 00b9  ld   $b9
              0fa2 00bb  ld   $bb
              0fa3 00fd  ld   $fd
              0fa4 00bf  ld   $bf
              0fa5 00b9  ld   $b9
              0fa6 00bb  ld   $bb
              0fa7 00fd  ld   $fd
              0fa8 00cb  ld   $cb
              0fa9 00b9  ld   $b9
              0faa 00c9  ld   $c9
              0fab 00fd  ld   $fd
              0fac 00bf  ld   $bf
              0fad 00b9  ld   $b9
              0fae 00bb  ld   $bb
              0faf 00fd  ld   $fd
              0fb0 0051  ld   $51
              0fb1 00b9  ld   $b9
              0fb2 00fd  ld   $fd
              0fb3 00fd  ld   $fd
              0fb4 00bf  ld   $bf
              0fb5 00b9  ld   $b9
              0fb6 00bd  ld   $bd
              0fb7 00fd  ld   $fd
              0fb8 00d1  ld   $d1
              0fb9 00b9  ld   $b9
              0fba 00e5  ld   $e5
              0fbb 00fd  ld   $fd
              0fbc 00bf  ld   $bf
              0fbd 00b9  ld   $b9
              0fbe 00bb  ld   $bb
              0fbf 00fd  ld   $fd
              0fc0 00e7  ld   $e7
              0fc1 00e9  ld   $e9
              0fc2 00fd  ld   $fd
              0fc3 00fd  ld   $fd
              0fc4 00e7  ld   $e7
              0fc5 00e9  ld   $e9
              0fc6 00eb  ld   $eb
              0fc7 00fd  ld   $fd
              0fc8 007b  ld   $7b
              0fc9 00e9  ld   $e9
              0fca 0077  ld   $77
              0fcb 00fd  ld   $fd
              0fcc 00e7  ld   $e7
              0fcd 00e9  ld   $e9
              0fce 00eb  ld   $eb
              0fcf 00fd  ld   $fd
              0fd0 0055  ld   $55
              0fd1 00e9  ld   $e9
              0fd2 00fd  ld   $fd
              0fd3 00fd  ld   $fd
              0fd4 00fd  ld   $fd
              0fd5 00e9  ld   $e9
              0fd6 00eb  ld   $eb
              0fd7 00fd  ld   $fd
              0fd8 00ed  ld   $ed
              0fd9 00e9  ld   $e9
              0fda 00fd  ld   $fd
              0fdb 00fd  ld   $fd
              0fdc 00fd  ld   $fd
              0fdd 00e9  ld   $e9
              0fde 00eb  ld   $eb
              0fdf 00fd  ld   $fd
              0fe0 00ef  ld   $ef
              0fe1 0029  ld   $29
              0fe2 00fd  ld   $fd
              0fe3 00fd  ld   $fd
              0fe4 00ef  ld   $ef
              0fe5 0029  ld   $29
              0fe6 00b7  ld   $b7
              0fe7 00fd  ld   $fd
              0fe8 006c  ld   $6c
              0fe9 0029  ld   $29
              0fea 0083  ld   $83
              0feb 00fd  ld   $fd
              0fec 00ef  ld   $ef
              0fed 0029  ld   $29
              0fee 00b7  ld   $b7
              0fef 00fd  ld   $fd
              0ff0 0058  ld   $58
              0ff1 0029  ld   $29
              0ff2 00fd  ld   $fd
              0ff3 00fd  ld   $fd
              0ff4 00fd  ld   $fd
              0ff5 0029  ld   $29
              0ff6 00b7  ld   $b7
              0ff7 00fd  ld   $fd
              0ff8 00fb  ld   $fb
              0ff9 0029  ld   $29
              0ffa 00fd  ld   $fd
              0ffb 00fd  ld   $fd
              0ffc 00fd  ld   $fd
              0ffd 0029  ld   $29
              0ffe 00b7  ld   $b7
              0fff fe00  bra  ac          ;Dispatch into next page
              1000 140e  ld   $0e,y
v6502_ADC:    1001 1525  ld   [$25],y     ;Must be at page offset 1, so A=1
              1002 2127  anda [$27]       ;Carry in
              1003 8118  adda [$18]       ;Sum
              1004 f020  beq  .adc14
              1005 8d00  adda [y,x]
              1006 c228  st   [$28]       ;Z flag
              1007 c229  st   [$29]       ;N flag
              1008 6118  xora [$18]       ;V flag
              1009 c218  st   [$18]
              100a 0d00  ld   [y,x]
              100b 6128  xora [$28]
              100c 2118  anda [$18]
              100d 2080  anda $80
              100e c21d  st   [$1d]
              100f 0128  ld   [$28]       ;Update A
              1010 c218  st   [$18]
              1011 e815  blt  .adc27      ;C flag
              1012 ad00  suba [y,x]
              1013 fc17  bra  .adc29
              1014 4d00  ora  [y,x]
.adc27:       1015 2d00  anda [y,x]
              1016 0200  nop
.adc29:       1017 3080  anda $80,x
              1018 0127  ld   [$27]       ;Update P
              1019 207e  anda $7e
              101a 4500  ora  [x]
              101b 411d  ora  [$1d]
              101c c227  st   [$27]
              101d 140e  ld   $0e,y
              101e e020  jmp  y,$20
              101f 00ed  ld   $ed
.adc14:       1020 c218  st   [$18]       ;Special case
              1021 c228  st   [$28]       ;Z flag
              1022 c229  st   [$29]       ;N flag
              1023 0127  ld   [$27]
              1024 207f  anda $7f         ;V=0, keep C
              1025 c227  st   [$27]
              1026 140e  ld   $0e,y
              1027 00f4  ld   $f4
              1028 e020  jmp  y,$20
v6502_SBC:    1029 1525  ld   [$25],y
              102a 0d00  ld   [y,x]
              102b 60ff  xora $ff
              102c c219  st   [$19]
              102d 0019  ld   $19
              102e d224  st   [$24],x
              102f 0000  ld   $00
              1030 c225  st   [$25]
              1031 0069  ld   $69         ;ADC #$xx
              1032 c226  st   [$26]
              1033 140e  ld   $0e,y
              1034 e0f2  jmp  y,$f2
              1035 00f5  ld   $f5
v6502_CLC:    1036 0127  ld   [$27]
              1037 fc3b  bra  .sec12
v6502_SEC:    1038 20fe  anda $fe
              1039 0127  ld   [$27]
              103a 4001  ora  $01
.sec12:       103b c227  st   [$27]
              103c 0200  nop
.next14:      103d e020  jmp  y,$20
              103e 00f8  ld   $f8
v6502_BPL:    103f 0129  ld   [$29]
              1040 e875  blt  .next12
              1041 f45b  bge  .branch13
v6502_BMI:    1042 0129  ld   [$29]
              1043 f475  bge  .next12
              1044 e85b  blt  .branch13
v6502_BVC:    1045 0127  ld   [$27]
              1046 2080  anda $80
              1047 f05b  beq  .branch13
              1048 ec3d  bne  .next14
v6502_BVS:    1049 0127  ld   [$27]
              104a 2080  anda $80
              104b ec5b  bne  .branch13
              104c f03d  beq  .next14
v6502_BCC:    104d 0127  ld   [$27]
              104e 2001  anda $01
              104f f05b  beq  .branch13
              1050 ec3d  bne  .next14
v6502_BCS:    1051 0127  ld   [$27]
              1052 2001  anda $01
              1053 ec5b  bne  .branch13
              1054 f03d  beq  .next14
v6502_BNE:    1055 0128  ld   [$28]
              1056 f075  beq  .next12
              1057 ec5b  bne  .branch13
v6502_BEQ:    1058 0128  ld   [$28]
              1059 ec75  bne  .next12
              105a f05b  beq  .branch13
.branch13:    105b 0124  ld   [$24]       ;PC + offset
              105c 811a  adda [$1a]
              105d c21a  st   [$1a]
              105e e862  blt  .bra0       ;Carry
              105f a124  suba [$24]
              1060 fc64  bra  .bra1
              1061 4124  ora  [$24]
.bra0:        1062 2124  anda [$24]
              1063 0200  nop
.bra1:        1064 3080  anda $80,x
              1065 0500  ld   [x]
              1066 8125  adda [$25]
              1067 811b  adda [$1b]
              1068 c21b  st   [$1b]
              1069 0200  nop
              106a e020  jmp  y,$20
              106b 00f2  ld   $f2
v6502_INX:    106c 0200  nop
              106d 012a  ld   [$2a]
              106e 8001  adda $01
              106f c22a  st   [$2a]
.inx13:       1070 c228  st   [$28]       ;Z flag
              1071 c229  st   [$29]       ;N flag
              1072 00f7  ld   $f7
              1073 e020  jmp  y,$20
              1074 0200  nop
.next12:      1075 e020  jmp  y,$20
              1076 00f9  ld   $f9
v6502_DEX:    1077 012a  ld   [$2a]
              1078 a001  suba $01
              1079 fc70  bra  .inx13
              107a c22a  st   [$2a]
v6502_INY:    107b 012b  ld   [$2b]
              107c 8001  adda $01
              107d fc70  bra  .inx13
              107e c22b  st   [$2b]
v6502_DEY:    107f 012b  ld   [$2b]
              1080 a001  suba $01
              1081 fc70  bra  .inx13
              1082 c22b  st   [$2b]
v6502_NOP:    1083 00fa  ld   $fa
              1084 e020  jmp  y,$20
v6502_AND:    1085 1525  ld   [$25],y
              1086 0118  ld   [$18]
              1087 fc90  bra  .eor13
              1088 2d00  anda [y,x]
v6502_ORA:    1089 1525  ld   [$25],y
              108a 0118  ld   [$18]
              108b fc90  bra  .eor13
v6502_EOR:    108c 4d00  ora  [y,x]
              108d 1525  ld   [$25],y
              108e 0118  ld   [$18]
              108f 6d00  xora [y,x]
.eor13:       1090 c218  st   [$18]
              1091 c228  st   [$28]       ;Z flag
              1092 c229  st   [$29]       ;N flag
              1093 140e  ld   $0e,y
              1094 00f6  ld   $f6
              1095 e020  jmp  y,$20
v6502_JMP1:   1096 140d  ld   $0d,y       ;JMP $DDDD
              1097 e0c2  jmp  y,$c2
v6502_JMP2:   1098 140d  ld   $0d,y       ;JMP ($DDDD)
              1099 e0ca  jmp  y,$ca
v6502_JSR:    109a 011c  ld   [$1c]
              109b a002  suba $02
              109c d21c  st   [$1c],x
              109d 1400  ld   $00,y
              109e 011b  ld   [$1b]
              109f c225  st   [$25]
              10a0 011a  ld   [$1a]
              10a1 c224  st   [$24]
              10a2 8001  adda $01         ;Push ++PC
              10a3 c21a  st   [$1a]
              10a4 de00  st   [y,x++]
              10a5 f0a8  beq  $10a8
              10a6 fca9  bra  $10a9
              10a7 0000  ld   $00
              10a8 0001  ld   $01
              10a9 811b  adda [$1b]
              10aa c21b  st   [$1b]
              10ab ce00  st   [y,x]
              10ac 1124  ld   [$24],x     ;Fetch L
              10ad 1525  ld   [$25],y
              10ae 0d00  ld   [y,x]
              10af 111a  ld   [$1a],x     ;Fetch H
              10b0 c21a  st   [$1a]
              10b1 151b  ld   [$1b],y
              10b2 0d00  ld   [y,x]
              10b3 c21b  st   [$1b]
              10b4 140e  ld   $0e,y
              10b5 00ed  ld   $ed
              10b6 e020  jmp  y,$20
v6502_INC:    10b7 1411  ld   $11,y
              10b8 e00e  jmp  y,$0e
v6502_LDA:    10b9 1411  ld   $11,y
              10ba e018  jmp  y,$18
v6502_LDX:    10bb 1411  ld   $11,y
              10bc e022  jmp  y,$22
v6502_LDX2:   10bd 1411  ld   $11,y
              10be e02a  jmp  y,$2a
v6502_LDY:    10bf 1411  ld   $11,y
              10c0 e026  jmp  y,$26
v6502_STA:    10c1 1411  ld   $11,y
              10c2 e034  jmp  y,$34
v6502_STX:    10c3 1411  ld   $11,y
              10c4 e03a  jmp  y,$3a
v6502_STX2:   10c5 1411  ld   $11,y
              10c6 e040  jmp  y,$40
v6502_STY:    10c7 1411  ld   $11,y
              10c8 e048  jmp  y,$48
v6502_TAX:    10c9 1411  ld   $11,y
              10ca e04d  jmp  y,$4d
v6502_TAY:    10cb 1411  ld   $11,y
              10cc e062  jmp  y,$62
v6502_TXA:    10cd 1411  ld   $11,y
              10ce e065  jmp  y,$65
v6502_TYA:    10cf 1411  ld   $11,y
              10d0 e068  jmp  y,$68
v6502_CLV:    10d1 1411  ld   $11,y
              10d2 e076  jmp  y,$76
v6502_RTI:    10d3 1411  ld   $11,y
              10d4 e0e4  jmp  y,$e4
v6502_ROR:    10d5 140d  ld   $0d,y
              10d6 e080  jmp  y,$80
v6502_LSR:    10d7 140d  ld   $0d,y
              10d8 e09a  jmp  y,$9a
v6502_PHA:    10d9 140d  ld   $0d,y
              10da e0df  jmp  y,$df
v6502_CLI:    10db 1411  ld   $11,y
              10dc e06b  jmp  y,$6b
v6502_RTS:    10dd 1411  ld   $11,y
              10de e08f  jmp  y,$8f
v6502_PLA:    10df 140d  ld   $0d,y
              10e0 e0d4  jmp  y,$d4
v6502_SEI:    10e1 1411  ld   $11,y
              10e2 e06e  jmp  y,$6e
v6502_TXS:    10e3 1411  ld   $11,y
              10e4 e05e  jmp  y,$5e
v6502_TSX:    10e5 1411  ld   $11,y
              10e6 e054  jmp  y,$54
v6502_CPY:    10e7 1411  ld   $11,y
              10e8 e0bd  jmp  y,$bd
v6502_CMP:    10e9 1411  ld   $11,y
              10ea e0be  jmp  y,$be
v6502_DEC:    10eb 1411  ld   $11,y
              10ec e005  jmp  y,$05
v6502_CLD:    10ed 1411  ld   $11,y
              10ee e071  jmp  y,$71
v6502_CPX:    10ef 1411  ld   $11,y
              10f0 e0bb  jmp  y,$bb
v6502_ASL:    10f1 140d  ld   $0d,y
              10f2 e0bc  jmp  y,$bc
v6502_PHP:    10f3 1411  ld   $11,y
              10f4 e0a2  jmp  y,$a2
v6502_BIT:    10f5 1411  ld   $11,y
              10f6 e07d  jmp  y,$7d
v6502_ROL:    10f7 140d  ld   $0d,y
              10f8 e0a9  jmp  y,$a9
v6502_PLP:    10f9 1411  ld   $11,y
              10fa e0d4  jmp  y,$d4
v6502_SED:    10fb 1411  ld   $11,y
              10fc e074  jmp  y,$74
v6502_ILL:
v6502_BRK:    10fd 140d  ld   $0d,y
              10fe e0e7  jmp  y,$e7
v6502_RESUME: 10ff a006  suba $06         ;v6502 secondary entry point
              1100 c215  st   [$15]
              1101 1124  ld   [$24],x
              1102 140f  ld   $0f,y
              1103 e126  jmp  y,[$26]
              1104 fcff  bra  $ff
v6502_dec:    1105 1525  ld   [$25],y
              1106 0d00  ld   [y,x]
              1107 a001  suba $01
              1108 ce00  st   [y,x]
              1109 c228  st   [$28]       ;Z flag
              110a c229  st   [$29]       ;N flag
              110b 140e  ld   $0e,y
              110c 00f5  ld   $f5
              110d e020  jmp  y,$20
v6502_inc:    110e 1525  ld   [$25],y
              110f 0d00  ld   [y,x]
              1110 8001  adda $01
              1111 ce00  st   [y,x]
              1112 c228  st   [$28]       ;Z flag
              1113 c229  st   [$29]       ;N flag
              1114 140e  ld   $0e,y
              1115 00f5  ld   $f5
              1116 e020  jmp  y,$20
              1117 0200  nop
v6502_lda:    1118 0200  nop
              1119 1525  ld   [$25],y
              111a 0d00  ld   [y,x]
              111b c218  st   [$18]
.lda16:       111c c228  st   [$28]       ;Z flag
              111d c229  st   [$29]       ;N flag
              111e 0200  nop
              111f 140e  ld   $0e,y
              1120 e020  jmp  y,$20
              1121 00f5  ld   $f5
v6502_ldx:    1122 1525  ld   [$25],y
              1123 0d00  ld   [y,x]
              1124 fc1c  bra  .lda16
              1125 c22a  st   [$2a]
v6502_ldy:    1126 1525  ld   [$25],y
              1127 0d00  ld   [y,x]
              1128 fc1c  bra  .lda16
              1129 c22b  st   [$2b]
v6502_ldx2:   112a 0124  ld   [$24]       ;Special case $B6: LDX $DD,Y
              112b a12a  suba [$2a]       ;Undo X offset
              112c 912b  adda [$2b],x     ;Apply Y instead
              112d 0500  ld   [x]
              112e c22a  st   [$2a]
              112f c228  st   [$28]       ;Z flag
              1130 c229  st   [$29]       ;N flag
              1131 140e  ld   $0e,y
              1132 e020  jmp  y,$20
              1133 00f5  ld   $f5
v6502_sta:    1134 1525  ld   [$25],y
              1135 0118  ld   [$18]
              1136 ce00  st   [y,x]
              1137 140e  ld   $0e,y
              1138 e020  jmp  y,$20
              1139 00f7  ld   $f7
v6502_stx:    113a 1525  ld   [$25],y
              113b 012a  ld   [$2a]
              113c ce00  st   [y,x]
              113d 140e  ld   $0e,y
              113e e020  jmp  y,$20
              113f 00f7  ld   $f7
v6502_stx2:   1140 0124  ld   [$24]       ;Special case $96: STX $DD,Y
              1141 a12a  suba [$2a]       ;Undo X offset
              1142 912b  adda [$2b],x     ;Apply Y instead
              1143 012a  ld   [$2a]
              1144 c600  st   [x]
              1145 140e  ld   $0e,y
              1146 e020  jmp  y,$20
              1147 00f6  ld   $f6
v6502_sty:    1148 1525  ld   [$25],y
              1149 012b  ld   [$2b]
              114a ce00  st   [y,x]
              114b 140e  ld   $0e,y
              114c e020  jmp  y,$20
v6502_tax:    114d 00f7  ld   $f7
              114e 0118  ld   [$18]
              114f c22a  st   [$2a]
.tax15:       1150 c228  st   [$28]       ;Z flag
              1151 c229  st   [$29]       ;N flag
              1152 140e  ld   $0e,y
              1153 e020  jmp  y,$20
v6502_tsx:    1154 00f6  ld   $f6
              1155 011c  ld   [$1c]
              1156 a001  suba $01         ;Shift down on export
              1157 c22a  st   [$2a]
.tsx16:       1158 c228  st   [$28]       ;Z flag
              1159 c229  st   [$29]       ;N flag
              115a 0200  nop
              115b 140e  ld   $0e,y
              115c e020  jmp  y,$20
              115d 00f5  ld   $f5
v6502_txs:    115e 012a  ld   [$2a]
              115f 8001  adda $01         ;Shift up on import
              1160 fc58  bra  .tsx16
              1161 c21c  st   [$1c]
v6502_tay:    1162 0118  ld   [$18]
              1163 fc50  bra  .tax15
              1164 c22b  st   [$2b]
v6502_txa:    1165 012a  ld   [$2a]
              1166 fc50  bra  .tax15
              1167 c218  st   [$18]
v6502_tya:    1168 012b  ld   [$2b]
              1169 fc50  bra  .tax15
              116a c218  st   [$18]
v6502_cli:    116b 0127  ld   [$27]
              116c fc79  bra  .clv15
              116d 20fb  anda $fb
v6502_sei:    116e 0127  ld   [$27]
              116f fc79  bra  .clv15
              1170 4004  ora  $04
v6502_cld:    1171 0127  ld   [$27]
              1172 fc79  bra  .clv15
              1173 20f7  anda $f7
v6502_sed:    1174 0127  ld   [$27]
              1175 fc79  bra  .clv15
v6502_clv:    1176 4008  ora  $08
              1177 0127  ld   [$27]
              1178 207f  anda $7f
.clv15:       1179 c227  st   [$27]
              117a 140e  ld   $0e,y
              117b 00f6  ld   $f6
              117c e020  jmp  y,$20
v6502_bit:    117d 0200  nop
              117e 1124  ld   [$24],x
              117f 1525  ld   [$25],y
              1180 0d00  ld   [y,x]
              1181 c229  st   [$29]       ;N flag
              1182 2118  anda [$18]       ;This is a reason we keep N and Z in separate bytes
              1183 c228  st   [$28]       ;Z flag
              1184 0127  ld   [$27]
              1185 207f  anda $7f
              1186 c227  st   [$27]
              1187 0d00  ld   [y,x]
              1188 8200  adda ac
              1189 2080  anda $80
              118a 4127  ora  [$27]
              118b c227  st   [$27]
              118c 140e  ld   $0e,y
              118d e020  jmp  y,$20
              118e 00f1  ld   $f1
v6502_rts:    118f 011c  ld   [$1c]
              1190 1200  ld   ac,x
              1191 8002  adda $02
              1192 c21c  st   [$1c]
              1193 1400  ld   $00,y
              1194 0d00  ld   [y,x]
              1195 de00  st   [y,x++]
              1196 8001  adda $01
              1197 c21a  st   [$1a]
              1198 f09b  beq  $119b
              1199 fc9c  bra  $119c
              119a 0000  ld   $00
              119b 0001  ld   $01
              119c 8d00  adda [y,x]
              119d c21b  st   [$1b]
              119e 0200  nop
              119f 140e  ld   $0e,y
              11a0 e020  jmp  y,$20
              11a1 00f1  ld   $f1
v6502_php:    11a2 011c  ld   [$1c]
              11a3 a001  suba $01
              11a4 d21c  st   [$1c],x
              11a5 0127  ld   [$27]
              11a6 20bd  anda $bd         ;Keep Vemu,B,D,I,C
              11a7 f4aa  bge  $11aa       ;V to bit 6 and clear N
              11a8 fcaa  bra  $11aa
              11a9 60c0  xora $c0
              11aa c600  st   [x]
              11ab 0128  ld   [$28]       ;Z flag
              11ac f0af  beq  $11af
              11ad fcb0  bra  $11b0
              11ae 0000  ld   $00
              11af 0002  ld   $02
              11b0 4500  ora  [x]
              11b1 c600  st   [x]
              11b2 0129  ld   [$29]       ;N flag
              11b3 2080  anda $80
              11b4 4500  ora  [x]
              11b5 4020  ora  $20         ;Unused bit
              11b6 c600  st   [x]
              11b7 0200  nop
              11b8 140e  ld   $0e,y
              11b9 e020  jmp  y,$20
              11ba 00ee  ld   $ee
v6502_cpx:    11bb fcc0  bra  .cmp14
              11bc 012a  ld   [$2a]
v6502_cpy:    11bd fcc0  bra  .cmp14
v6502_cmp:    11be 012b  ld   [$2b]
              11bf 0118  ld   [$18]
.cmp14:       11c0 1525  ld   [$25],y
              11c1 e8c7  blt  .cmp17      ;Carry?
              11c2 ad00  suba [y,x]
              11c3 c228  st   [$28]       ;Z flag
              11c4 c229  st   [$29]       ;N flag
              11c5 fccb  bra  .cmp21
              11c6 4d00  ora  [y,x]
.cmp17:       11c7 c228  st   [$28]       ;Z flag
              11c8 c229  st   [$29]       ;N flag
              11c9 2d00  anda [y,x]
              11ca 0200  nop
.cmp21:       11cb 6080  xora $80
              11cc 3080  anda $80,x
              11cd 0127  ld   [$27]       ;C flag
              11ce 20fe  anda $fe
              11cf 4500  ora  [x]
              11d0 c227  st   [$27]
              11d1 140e  ld   $0e,y
              11d2 e020  jmp  y,$20
              11d3 00f1  ld   $f1
v6502_plp:    11d4 011c  ld   [$1c]
              11d5 1200  ld   ac,x
              11d6 8001  adda $01
              11d7 c21c  st   [$1c]
              11d8 0500  ld   [x]
              11d9 c229  st   [$29]       ;N flag
              11da 2002  anda $02
              11db 6002  xora $02
              11dc c228  st   [$28]       ;Z flag
              11dd 0500  ld   [x]
              11de 207f  anda $7f         ;V to bit 7
              11df 8040  adda $40
              11e0 c227  st   [$27]       ;All other flags
              11e1 140e  ld   $0e,y
              11e2 e020  jmp  y,$20
              11e3 00f2  ld   $f2
v6502_rti:    11e4 011c  ld   [$1c]
              11e5 1200  ld   ac,x
              11e6 8003  adda $03
              11e7 c21c  st   [$1c]
              11e8 0500  ld   [x]
              11e9 c229  st   [$29]       ;N flag
              11ea 2002  anda $02
              11eb 6002  xora $02
              11ec c228  st   [$28]       ;Z flag
              11ed 1400  ld   $00,y
              11ee 0d00  ld   [y,x]
              11ef de00  st   [y,x++]
              11f0 207f  anda $7f         ;V to bit 7
              11f1 8040  adda $40
              11f2 c227  st   [$27]       ;All other flags
              11f3 0d00  ld   [y,x]
              11f4 de00  st   [y,x++]
              11f5 c21a  st   [$1a]
              11f6 0d00  ld   [y,x]
              11f7 c21b  st   [$1b]
              11f8 0200  nop
              11f9 140e  ld   $0e,y
              11fa e020  jmp  y,$20
              11fb 00ee  ld   $ee
sys_Exec:     11fc d617  st   [$17],y
              11fd 011c  ld   [$1c]
              11fe a037  suba $37
              11ff d21d  st   [$1d],x
              1200 80fe  adda $fe
              1201 c216  st   [$16]
              1202 dc75  st   $75,[y,x++] ;PUSH
              1203 dccf  st   $cf,[y,x++] ;CALL
              1204 8023  adda $23
              1205 de00  st   [y,x++]
              1206 dc5e  st   $5e,[y,x++] ;ST
              1207 dc27  st   $27,[y,x++]
              1208 dccf  st   $cf,[y,x++] ;CALL
              1209 de00  st   [y,x++]
              120a dc5e  st   $5e,[y,x++] ;ST
              120b dc26  st   $26,[y,x++]
              120c dccf  st   $cf,[y,x++] ;CALL
              120d de00  st   [y,x++]
              120e dc5e  st   $5e,[y,x++] ;ST
              120f dc28  st   $28,[y,x++]
              1210 dccf  st   $cf,[y,x++] ;CALL
              1211 de00  st   [y,x++]
              1212 dcf0  st   $f0,[y,x++] ;POKE
              1213 dc26  st   $26,[y,x++]
              1214 dc93  st   $93,[y,x++] ;INC
              1215 dc26  st   $26,[y,x++]
              1216 dc1a  st   $1a,[y,x++] ;LD
              1217 dc28  st   $28,[y,x++]
              1218 dce6  st   $e6,[y,x++] ;SUBI
              1219 dc01  st   $01,[y,x++]
              121a dc35  st   $35,[y,x++] ;BCC
              121b dc72  st   $72,[y,x++] ;NE
              121c 80e8  adda $e8
              121d de00  st   [y,x++]
              121e dccf  st   $cf,[y,x++] ;CALL
              121f 8018  adda $18
              1220 de00  st   [y,x++]
              1221 dc35  st   $35,[y,x++] ;BCC
              1222 dc72  st   $72,[y,x++] ;NE
              1223 80e0  adda $e0
              1224 de00  st   [y,x++]
              1225 dc63  st   $63,[y,x++] ;POP
              1226 dcff  st   $ff,[y,x++] ;RET
              1227 8022  adda $22
              1228 de00  st   [y,x++]
              1229 dc00  st   $00,[y,x++]
              122a dc1a  st   $1a,[y,x++] ;LD
              122b dc24  st   $24,[y,x++]
              122c dc8c  st   $8c,[y,x++] ;XORI
              122d dcfb  st   $fb,[y,x++]
              122e dc35  st   $35,[y,x++] ;BCC
              122f dc72  st   $72,[y,x++] ;NE
              1230 8009  adda $09
              1231 de00  st   [y,x++]
              1232 dc5e  st   $5e,[y,x++] ;ST
              1233 dc24  st   $24,[y,x++]
              1234 dc93  st   $93,[y,x++] ;INC
              1235 dc25  st   $25,[y,x++]
              1236 dc21  st   $21,[y,x++] ;LDW
              1237 dc24  st   $24,[y,x++]
              1238 dc7f  st   $7f,[y,x++] ;LUP
              1239 dc00  st   $00,[y,x++]
              123a dc93  st   $93,[y,x++] ;INC
              123b dc24  st   $24,[y,x++]
              123c dcff  st   $ff,[y,x++] ;RET
              123d 1403  ld   $03,y
              123e e0cb  jmp  y,$cb
              123f 00d4  ld   $d4
              1240 0200  nop              ;192 fillers
              1241 0200  nop
              1242 0200  nop
              * 193 times
              1301 0200  nop              ;255 fillers
              1302 0200  nop
              1303 0200  nop
              * 256 times
              1401 0200  nop              ;255 fillers
              1402 0200  nop
              1403 0200  nop
              * 254 times
              14ff 0200  nop              ;+-----------------------------------+
                                          ;| MainMenu\MainMenu.gcl             |
                                          ;+-----------------------------------+
Main:         1500 0002  ld   $02         ;| RAM segment address (high byte first)
              1501 0000  ld   $00         ;|
              1502 00cc  ld   $cc         ;| Length (1..256)
              1503 00cd  ld   $cd         ;0200 DEF
              1504 004e  ld   $4e
              1505 0021  ld   $21         ;0202 LDW
              1506 0030  ld   $30         ;0202 'Char'
              1507 00e6  ld   $e6         ;0204 SUBI
              1508 0052  ld   $52
              1509 0035  ld   $35         ;0206 BCC
              150a 0053  ld   $53         ;0207 GE
              150b 0010  ld   $10
              150c 00e3  ld   $e3         ;0209 ADDI
              150d 0032  ld   $32
              150e 002b  ld   $2b         ;020b STW
              150f 0032  ld   $32         ;020b 'i'
              1510 0011  ld   $11         ;020d LDWI
              1511 0000  ld   $00
              1512 0007  ld   $07
              1513 0090  ld   $90         ;0210 BRA
              1514 0015  ld   $15
              1515 002b  ld   $2b         ;0212 STW
              1516 0032  ld   $32         ;0212 'i'
              1517 0011  ld   $11         ;0214 LDWI
              1518 0000  ld   $00
              1519 0008  ld   $08
              151a 002b  ld   $2b         ;0217 STW
              151b 0034  ld   $34         ;0217 'fontData'
              151c 0021  ld   $21         ;0219 LDW
              151d 0032  ld   $32         ;0219 'i'
              151e 00e9  ld   $e9         ;021b LSLW
              151f 00e9  ld   $e9         ;021c LSLW
              1520 0099  ld   $99         ;021d ADDW
              1521 0032  ld   $32         ;021d 'i'
              1522 0099  ld   $99         ;021f ADDW
              1523 0034  ld   $34         ;021f 'fontData'
              1524 002b  ld   $2b         ;0221 STW
              1525 0034  ld   $34         ;0221 'fontData'
              1526 0059  ld   $59         ;0223 LDI
              1527 0020  ld   $20
              1528 005e  ld   $5e         ;0225 ST
              1529 0024  ld   $24
              152a 0021  ld   $21         ;0227 LDW
              152b 0036  ld   $36         ;0227 'Color'
              152c 005e  ld   $5e         ;0229 ST
              152d 0025  ld   $25
              152e 0021  ld   $21         ;022b LDW
              152f 0038  ld   $38         ;022b 'Pos'
              1530 002b  ld   $2b         ;022d STW
              1531 0028  ld   $28
              1532 00e3  ld   $e3         ;022f ADDI
              1533 0006  ld   $06
              1534 002b  ld   $2b         ;0231 STW
              1535 0038  ld   $38         ;0231 'Pos'
              1536 0011  ld   $11         ;0233 LDWI
              1537 00e1  ld   $e1
              1538 0004  ld   $04
              1539 002b  ld   $2b         ;0236 STW
              153a 0022  ld   $22
              153b 0059  ld   $59         ;0238 LDI
              153c 00fb  ld   $fb
              153d 002b  ld   $2b         ;023a STW
              153e 0032  ld   $32         ;023a 'i'
              153f 0021  ld   $21         ;023c LDW
              1540 0034  ld   $34         ;023c 'fontData'
              1541 007f  ld   $7f         ;023e LUP
              1542 0000  ld   $00
              1543 0093  ld   $93         ;0240 INC
              1544 0034  ld   $34         ;0240 'fontData'
              1545 005e  ld   $5e         ;0242 ST
              1546 0026  ld   $26
              1547 00b4  ld   $b4         ;0244 SYS
              1548 00cb  ld   $cb
              1549 0093  ld   $93         ;0246 INC
              154a 0028  ld   $28
              154b 0093  ld   $93         ;0248 INC
              154c 0032  ld   $32         ;0248 'i'
              154d 0021  ld   $21         ;024a LDW
              154e 0032  ld   $32         ;024a 'i'
              154f 0035  ld   $35         ;024c BCC
              1550 0072  ld   $72         ;024d NE
              1551 003a  ld   $3a
              1552 00ff  ld   $ff         ;024f RET
              1553 002b  ld   $2b         ;0250 STW
              1554 003a  ld   $3a         ;0250 'PrintChar'
              1555 00cd  ld   $cd         ;0252 DEF
              1556 007b  ld   $7b
              1557 0075  ld   $75         ;0254 PUSH
              1558 002b  ld   $2b         ;0255 STW
              1559 003c  ld   $3c         ;0255 'Text'
              155a 0021  ld   $21         ;0257 LDW
              155b 003c  ld   $3c         ;0257 'Text'
              155c 00ad  ld   $ad         ;0259 PEEK
              155d 0035  ld   $35         ;025a BCC
              155e 003f  ld   $3f         ;025b EQ
              155f 0079  ld   $79
              1560 002b  ld   $2b         ;025d STW
              1561 0030  ld   $30         ;025d 'Char'
              1562 0093  ld   $93         ;025f INC
              1563 003c  ld   $3c         ;025f 'Text'
              1564 008c  ld   $8c         ;0261 XORI
              1565 0009  ld   $09
              1566 0035  ld   $35         ;0263 BCC
              1567 0072  ld   $72         ;0264 NE
              1568 006c  ld   $6c
              1569 0021  ld   $21         ;0266 LDW
              156a 0038  ld   $38         ;0266 'Pos'
              156b 00e3  ld   $e3         ;0268 ADDI
              156c 0012  ld   $12
              156d 002b  ld   $2b         ;026a STW
              156e 0038  ld   $38         ;026a 'Pos'
              156f 0090  ld   $90         ;026c BRA
              1570 0055  ld   $55
              1571 008c  ld   $8c         ;026e XORI
              1572 0003  ld   $03
              1573 0035  ld   $35         ;0270 BCC
              1574 0072  ld   $72         ;0271 NE
              1575 0075  ld   $75
              1576 00cf  ld   $cf         ;0273 CALL
              1577 003e  ld   $3e         ;0273 'Newline'
              1578 0090  ld   $90         ;0275 BRA
              1579 0055  ld   $55
              157a 00cf  ld   $cf         ;0277 CALL
              157b 003a  ld   $3a         ;0277 'PrintChar'
              157c 0090  ld   $90         ;0279 BRA
              157d 0055  ld   $55
              157e 0063  ld   $63         ;027b POP
              157f 00ff  ld   $ff         ;027c RET
              1580 002b  ld   $2b         ;027d STW
              1581 0040  ld   $40         ;027d 'PrintText'
              1582 00cd  ld   $cd         ;027f DEF
              1583 0095  ld   $95
              1584 0075  ld   $75         ;0281 PUSH
              1585 0059  ld   $59         ;0282 LDI
              1586 002d  ld   $2d
              1587 002b  ld   $2b         ;0284 STW
              1588 0030  ld   $30         ;0284 'Char'
              1589 0059  ld   $59         ;0286 LDI
              158a 001a  ld   $1a
              158b 002b  ld   $2b         ;0288 STW
              158c 0042  ld   $42         ;0288 'j'
              158d 00cf  ld   $cf         ;028a CALL
              158e 003a  ld   $3a         ;028a 'PrintChar'
              158f 0021  ld   $21         ;028c LDW
              1590 0042  ld   $42         ;028c 'j'
              1591 00e6  ld   $e6         ;028e SUBI
              1592 0001  ld   $01
              1593 0035  ld   $35         ;0290 BCC
              1594 004d  ld   $4d         ;0291 GT
              1595 0086  ld   $86
              1596 00cf  ld   $cf         ;0293 CALL
              1597 003e  ld   $3e         ;0293 'Newline'
              1598 0063  ld   $63         ;0295 POP
              1599 00ff  ld   $ff         ;0296 RET
              159a 002b  ld   $2b         ;0297 STW
              159b 0044  ld   $44         ;0297 'PrintDivider'
              159c 00cd  ld   $cd         ;0299 DEF
              159d 00c5  ld   $c5
              159e 0075  ld   $75         ;029b PUSH
              159f 0021  ld   $21         ;029c LDW
              15a0 0046  ld   $46         ;029c 'MenuItem'
              15a1 00e6  ld   $e6         ;029e SUBI
              15a2 0006  ld   $06
              15a3 0035  ld   $35         ;02a0 BCC
              15a4 0053  ld   $53         ;02a1 GE
              15a5 00a6  ld   $a6
              15a6 0011  ld   $11         ;02a3 LDWI
              15a7 000b  ld   $0b
              15a8 0020  ld   $20
              15a9 0090  ld   $90         ;02a6 BRA
              15aa 00a9  ld   $a9
              15ab 0011  ld   $11         ;02a8 LDWI
              15ac 0059  ld   $59
              15ad 00f0  ld   $f0
              15ae 002b  ld   $2b         ;02ab STW
              15af 0038  ld   $38         ;02ab 'Pos'
              15b0 0021  ld   $21         ;02ad LDW
              15b1 0046  ld   $46         ;02ad 'MenuItem'
              15b2 002b  ld   $2b         ;02af STW
              15b3 0042  ld   $42         ;02af 'j'
              15b4 0011  ld   $11         ;02b1 LDWI
              15b5 0000  ld   $00
              15b6 0008  ld   $08
              15b7 0099  ld   $99         ;02b4 ADDW
              15b8 0038  ld   $38         ;02b4 'Pos'
              15b9 002b  ld   $2b         ;02b6 STW
              15ba 0038  ld   $38         ;02b6 'Pos'
              15bb 0021  ld   $21         ;02b8 LDW
              15bc 0042  ld   $42         ;02b8 'j'
              15bd 00e6  ld   $e6         ;02ba SUBI
              15be 0001  ld   $01
              15bf 0035  ld   $35         ;02bc BCC
              15c0 0053  ld   $53         ;02bd GE
              15c1 00ad  ld   $ad
              15c2 0059  ld   $59         ;02bf LDI
              15c3 0082  ld   $82
              15c4 002b  ld   $2b         ;02c1 STW
              15c5 0030  ld   $30         ;02c1 'Char'
              15c6 00cf  ld   $cf         ;02c3 CALL
              15c7 003a  ld   $3a         ;02c3 'PrintChar'
              15c8 0063  ld   $63         ;02c5 POP
              15c9 00ff  ld   $ff         ;02c6 RET
              15ca 002b  ld   $2b         ;02c7 STW
              15cb 0048  ld   $48         ;02c7 'PrintArrow'
              15cc 0093  ld   $93         ;02c9 INC
              15cd 001b  ld   $1b         ;02c9 '_vLR'+1
              15ce 00ff  ld   $ff         ;02cb RET
              15cf 0003  ld   $03         ;| RAM segment address (high byte first)
              15d0 0000  ld   $00         ;|
              15d1 00f3  ld   $f3         ;| Length (1..256)
              15d2 00cd  ld   $cd         ;0300 DEF
              15d3 00ee  ld   $ee
              15d4 0075  ld   $75         ;0302 PUSH
              15d5 001a  ld   $1a         ;0303 LD
              15d6 000e  ld   $0e
              15d7 002b  ld   $2b         ;0305 STW
              15d8 0036  ld   $36         ;0305 'Color'
              15d9 00cf  ld   $cf         ;0307 CALL
              15da 0048  ld   $48         ;0307 'PrintArrow'
              15db 001a  ld   $1a         ;0309 LD
              15dc 0011  ld   $11
              15dd 008c  ld   $8c         ;030b XORI
              15de 00fe  ld   $fe
              15df 0035  ld   $35         ;030d BCC
              15e0 0072  ld   $72         ;030e NE
              15e1 001f  ld   $1f
              15e2 00cf  ld   $cf         ;0310 CALL
              15e3 004a  ld   $4a         ;0310 'WipeOutArrow'
              15e4 0021  ld   $21         ;0312 LDW
              15e5 0046  ld   $46         ;0312 'MenuItem'
              15e6 00e6  ld   $e6         ;0314 SUBI
              15e7 0005  ld   $05
              15e8 0035  ld   $35         ;0316 BCC
              15e9 004d  ld   $4d         ;0317 GT
              15ea 001b  ld   $1b
              15eb 00e3  ld   $e3         ;0319 ADDI
              15ec 000b  ld   $0b
              15ed 002b  ld   $2b         ;031b STW
              15ee 0046  ld   $46         ;031b 'MenuItem'
              15ef 0059  ld   $59         ;031d LDI
              15f0 00ef  ld   $ef
              15f1 005e  ld   $5e         ;031f ST
              15f2 0011  ld   $11
              15f3 001a  ld   $1a         ;0321 LD
              15f4 0011  ld   $11
              15f5 008c  ld   $8c         ;0323 XORI
              15f6 00fd  ld   $fd
              15f7 0035  ld   $35         ;0325 BCC
              15f8 0072  ld   $72         ;0326 NE
              15f9 0035  ld   $35
              15fa 00cf  ld   $cf         ;0328 CALL
              15fb fe00  bra  ac          ;+-----------------------------------+
              15fc fcfd  bra  $15fd       ;|                                   |
              15fd 1404  ld   $04,y       ;| Trampoline for page $1500 lookups |
              15fe e068  jmp  y,$68       ;|                                   |
              15ff c218  st   [$18]       ;+-----------------------------------+
              1600 004a  ld   $4a         ;0328 'WipeOutArrow'
              1601 0021  ld   $21         ;032a LDW
              1602 0046  ld   $46         ;032a 'MenuItem'
              1603 00e6  ld   $e6         ;032c SUBI
              1604 0006  ld   $06
              1605 0035  ld   $35         ;032e BCC
              1606 0050  ld   $50         ;032f LT
              1607 0031  ld   $31
              1608 002b  ld   $2b         ;0331 STW
              1609 0046  ld   $46         ;0331 'MenuItem'
              160a 0059  ld   $59         ;0333 LDI
              160b 00ef  ld   $ef
              160c 005e  ld   $5e         ;0335 ST
              160d 0011  ld   $11
              160e 001a  ld   $1a         ;0337 LD
              160f 0011  ld   $11
              1610 008c  ld   $8c         ;0339 XORI
              1611 00fb  ld   $fb
              1612 0035  ld   $35         ;033b BCC
              1613 0072  ld   $72         ;033c NE
              1614 0050  ld   $50
              1615 00cf  ld   $cf         ;033e CALL
              1616 004a  ld   $4a         ;033e 'WipeOutArrow'
              1617 0021  ld   $21         ;0340 LDW
              1618 0046  ld   $46         ;0340 'MenuItem'
              1619 00e6  ld   $e6         ;0342 SUBI
              161a 0005  ld   $05
              161b 0035  ld   $35         ;0344 BCC
              161c 003f  ld   $3f         ;0345 EQ
              161d 004c  ld   $4c
              161e 00e6  ld   $e6         ;0347 SUBI
              161f 0006  ld   $06
              1620 0035  ld   $35         ;0349 BCC
              1621 003f  ld   $3f         ;034a EQ
              1622 004c  ld   $4c
              1623 0093  ld   $93         ;034c INC
              1624 0046  ld   $46         ;034c 'MenuItem'
              1625 0059  ld   $59         ;034e LDI
              1626 00ef  ld   $ef
              1627 005e  ld   $5e         ;0350 ST
              1628 0011  ld   $11
              1629 001a  ld   $1a         ;0352 LD
              162a 0011  ld   $11
              162b 008c  ld   $8c         ;0354 XORI
              162c 00f7  ld   $f7
              162d 0035  ld   $35         ;0356 BCC
              162e 0072  ld   $72         ;0357 NE
              162f 006d  ld   $6d
              1630 00cf  ld   $cf         ;0359 CALL
              1631 004a  ld   $4a         ;0359 'WipeOutArrow'
              1632 0021  ld   $21         ;035b LDW
              1633 0046  ld   $46         ;035b 'MenuItem'
              1634 0035  ld   $35         ;035d BCC
              1635 003f  ld   $3f         ;035e EQ
              1636 0069  ld   $69
              1637 00e6  ld   $e6         ;0360 SUBI
              1638 0006  ld   $06
              1639 0035  ld   $35         ;0362 BCC
              163a 003f  ld   $3f         ;0363 EQ
              163b 0069  ld   $69
              163c 0021  ld   $21         ;0365 LDW
              163d 0046  ld   $46         ;0365 'MenuItem'
              163e 00e6  ld   $e6         ;0367 SUBI
              163f 0001  ld   $01
              1640 002b  ld   $2b         ;0369 STW
              1641 0046  ld   $46         ;0369 'MenuItem'
              1642 0059  ld   $59         ;036b LDI
              1643 00ef  ld   $ef
              1644 005e  ld   $5e         ;036d ST
              1645 0011  ld   $11
              1646 001a  ld   $1a         ;036f LD
              1647 0011  ld   $11
              1648 0082  ld   $82         ;0371 ANDI
              1649 0080  ld   $80
              164a 0035  ld   $35         ;0373 BCC
              164b 0072  ld   $72         ;0374 NE
              164c 0001  ld   $01
              164d 0059  ld   $59         ;0376 LDI
              164e 002a  ld   $2a
              164f 002b  ld   $2b         ;0378 STW
              1650 0036  ld   $36         ;0378 'Color'
              1651 00cf  ld   $cf         ;037a CALL
              1652 0048  ld   $48         ;037a 'PrintArrow'
              1653 0021  ld   $21         ;037c LDW
              1654 0046  ld   $46         ;037c 'MenuItem'
              1655 0035  ld   $35         ;037e BCC
              1656 0072  ld   $72         ;037f NE
              1657 0084  ld   $84
              1658 0011  ld   $11         ;0381 LDWI
              1659 0055  ld   $55
              165a 0018  ld   $18
              165b 0090  ld   $90         ;0384 BRA
              165c 00ea  ld   $ea
              165d 00e6  ld   $e6         ;0386 SUBI
              165e 0001  ld   $01
              165f 0035  ld   $35         ;0388 BCC
              1660 0072  ld   $72         ;0389 NE
              1661 008e  ld   $8e
              1662 0011  ld   $11         ;038b LDWI
              1663 0055  ld   $55
              1664 0018  ld   $18
              1665 0090  ld   $90         ;038e BRA
              1666 00ea  ld   $ea
              1667 00e6  ld   $e6         ;0390 SUBI
              1668 0001  ld   $01
              1669 0035  ld   $35         ;0392 BCC
              166a 0072  ld   $72         ;0393 NE
              166b 0098  ld   $98
              166c 0011  ld   $11         ;0395 LDWI
              166d 0055  ld   $55
              166e 0018  ld   $18
              166f 0090  ld   $90         ;0398 BRA
              1670 00ea  ld   $ea
              1671 00e6  ld   $e6         ;039a SUBI
              1672 0001  ld   $01
              1673 0035  ld   $35         ;039c BCC
              1674 0072  ld   $72         ;039d NE
              1675 00a2  ld   $a2
              1676 0011  ld   $11         ;039f LDWI
              1677 0055  ld   $55
              1678 0018  ld   $18
              1679 0090  ld   $90         ;03a2 BRA
              167a 00ea  ld   $ea
              167b 00e6  ld   $e6         ;03a4 SUBI
              167c 0001  ld   $01
              167d 0035  ld   $35         ;03a6 BCC
              167e 0072  ld   $72         ;03a7 NE
              167f 00ac  ld   $ac
              1680 0011  ld   $11         ;03a9 LDWI
              1681 0055  ld   $55
              1682 0018  ld   $18
              1683 0090  ld   $90         ;03ac BRA
              1684 00ea  ld   $ea
              1685 00e6  ld   $e6         ;03ae SUBI
              1686 0001  ld   $01
              1687 0035  ld   $35         ;03b0 BCC
              1688 0072  ld   $72         ;03b1 NE
              1689 00b6  ld   $b6
              168a 0011  ld   $11         ;03b3 LDWI
              168b 0055  ld   $55
              168c 0018  ld   $18
              168d 0090  ld   $90         ;03b6 BRA
              168e 00ea  ld   $ea
              168f 00e6  ld   $e6         ;03b8 SUBI
              1690 0001  ld   $01
              1691 0035  ld   $35         ;03ba BCC
              1692 0072  ld   $72         ;03bb NE
              1693 00c0  ld   $c0
              1694 0011  ld   $11         ;03bd LDWI
              1695 0055  ld   $55
              1696 0018  ld   $18
              1697 0090  ld   $90         ;03c0 BRA
              1698 00ea  ld   $ea
              1699 00e6  ld   $e6         ;03c2 SUBI
              169a 0001  ld   $01
              169b 0035  ld   $35         ;03c4 BCC
              169c 0072  ld   $72         ;03c5 NE
              169d 00ca  ld   $ca
              169e 0011  ld   $11         ;03c7 LDWI
              169f 0055  ld   $55
              16a0 0018  ld   $18
              16a1 0090  ld   $90         ;03ca BRA
              16a2 00ea  ld   $ea
              16a3 00e6  ld   $e6         ;03cc SUBI
              16a4 0002  ld   $02
              16a5 0035  ld   $35         ;03ce BCC
              16a6 004d  ld   $4d         ;03cf GT
              16a7 00d4  ld   $d4
              16a8 0011  ld   $11         ;03d1 LDWI
              16a9 0055  ld   $55
              16aa 0018  ld   $18
              16ab 0090  ld   $90         ;03d4 BRA
              16ac 00ea  ld   $ea
              16ad 00e6  ld   $e6         ;03d6 SUBI
              16ae 0001  ld   $01
              16af 0035  ld   $35         ;03d8 BCC
              16b0 0072  ld   $72         ;03d9 NE
              16b1 00de  ld   $de
              16b2 0011  ld   $11         ;03db LDWI
              16b3 0055  ld   $55
              16b4 0018  ld   $18
              16b5 0090  ld   $90         ;03de BRA
              16b6 00ea  ld   $ea
              16b7 00e6  ld   $e6         ;03e0 SUBI
              16b8 0001  ld   $01
              16b9 0035  ld   $35         ;03e2 BCC
              16ba 0072  ld   $72         ;03e3 NE
              16bb 00e8  ld   $e8
              16bc 0011  ld   $11         ;03e5 LDWI
              16bd 0055  ld   $55
              16be 0018  ld   $18
              16bf 0090  ld   $90         ;03e8 BRA
              16c0 00ea  ld   $ea
              16c1 0090  ld   $90         ;03ea BRA
              16c2 0001  ld   $01
              16c3 002b  ld   $2b         ;03ec STW
              16c4 004c  ld   $4c         ;03ec 'Program'
              16c5 0063  ld   $63         ;03ee POP
              16c6 00ff  ld   $ff         ;03ef RET
              16c7 0093  ld   $93         ;03f0 INC
              16c8 001b  ld   $1b         ;03f0 '_vLR'+1
              16c9 00ff  ld   $ff         ;03f2 RET
              16ca 0004  ld   $04         ;| RAM segment address (high byte first)
              16cb 0000  ld   $00         ;|
              16cc 00d5  ld   $d5         ;| Length (1..256)
              16cd 002b  ld   $2b         ;0400 STW
              16ce 004e  ld   $4e         ;0400 'SelectMenu'
              16cf 00cd  ld   $cd         ;0402 DEF
              16d0 000d  ld   $0d
              16d1 001a  ld   $1a         ;0404 LD
              16d2 0039  ld   $39         ;0404 'Pos'+1
              16d3 00e3  ld   $e3         ;0406 ADDI
              16d4 0008  ld   $08
              16d5 005e  ld   $5e         ;0408 ST
              16d6 0039  ld   $39         ;0408 'Pos'+1
              16d7 0059  ld   $59         ;040a LDI
              16d8 0002  ld   $02
              16d9 005e  ld   $5e         ;040c ST
              16da 0038  ld   $38         ;040c 'Pos'
              16db 00ff  ld   $ff         ;040e RET
              16dc 002b  ld   $2b         ;040f STW
              16dd 003e  ld   $3e         ;040f 'Newline'
              16de 00cd  ld   $cd         ;0411 DEF
              16df 0080  ld   $80
              16e0 0009  ld   $09         ;0413 9
              16e1 0053  ld   $53         ;0414 'S'
              16e2 006e  ld   $6e         ;0415 'n'
              16e3 0061  ld   $61         ;0416 'a'
              16e4 006b  ld   $6b         ;0417 'k'
              16e5 0065  ld   $65         ;0418 'e'
              16e6 0009  ld   $09         ;0419 9
              16e7 0020  ld   $20         ;041a ' '
              16e8 0020  ld   $20         ;041b ' '
              16e9 0009  ld   $09         ;041c 9
              16ea 0054  ld   $54         ;041d 'T'
              16eb 0065  ld   $65         ;041e 'e'
              16ec 0074  ld   $74         ;041f 't'
              16ed 0072  ld   $72         ;0420 'r'
              16ee 006f  ld   $6f         ;0421 'o'
              16ef 006e  ld   $6e         ;0422 'n'
              16f0 0069  ld   $69         ;0423 'i'
              16f1 0073  ld   $73         ;0424 's'
              16f2 000a  ld   $0a         ;0425 10
              16f3 0009  ld   $09         ;0426 9
              16f4 0052  ld   $52         ;0427 'R'
              16f5 0061  ld   $61         ;0428 'a'
              16f6 0063  ld   $63         ;0429 'c'
              16f7 0065  ld   $65         ;042a 'e'
              16f8 0072  ld   $72         ;042b 'r'
              16f9 0009  ld   $09         ;042c 9
              16fa 0020  ld   $20         ;042d ' '
              16fb fe00  bra  ac          ;+-----------------------------------+
              16fc fcfd  bra  $16fd       ;|                                   |
              16fd 1404  ld   $04,y       ;| Trampoline for page $1600 lookups |
              16fe e068  jmp  y,$68       ;|                                   |
              16ff c218  st   [$18]       ;+-----------------------------------+
              1700 0020  ld   $20         ;042e ' '
              1701 0009  ld   $09         ;042f 9
              1702 0042  ld   $42         ;0430 'B'
              1703 0072  ld   $72         ;0431 'r'
              1704 0069  ld   $69         ;0432 'i'
              1705 0063  ld   $63         ;0433 'c'
              1706 006b  ld   $6b         ;0434 'k'
              1707 0073  ld   $73         ;0435 's'
              1708 000a  ld   $0a         ;0436 10
              1709 0009  ld   $09         ;0437 9
              170a 004d  ld   $4d         ;0438 'M'
              170b 0061  ld   $61         ;0439 'a'
              170c 006e  ld   $6e         ;043a 'n'
              170d 0064  ld   $64         ;043b 'd'
              170e 0065  ld   $65         ;043c 'e'
              170f 006c  ld   $6c         ;043d 'l'
              1710 0062  ld   $62         ;043e 'b'
              1711 0072  ld   $72         ;043f 'r'
              1712 006f  ld   $6f         ;0440 'o'
              1713 0074  ld   $74         ;0441 't'
              1714 0009  ld   $09         ;0442 9
              1715 0054  ld   $54         ;0443 'T'
              1716 0069  ld   $69         ;0444 'i'
              1717 0063  ld   $63         ;0445 'c'
              1718 0054  ld   $54         ;0446 'T'
              1719 0061  ld   $61         ;0447 'a'
              171a 0063  ld   $63         ;0448 'c'
              171b 0054  ld   $54         ;0449 'T'
              171c 006f  ld   $6f         ;044a 'o'
              171d 0065  ld   $65         ;044b 'e'
              171e 000a  ld   $0a         ;044c 10
              171f 0009  ld   $09         ;044d 9
              1720 0050  ld   $50         ;044e 'P'
              1721 0069  ld   $69         ;044f 'i'
              1722 0063  ld   $63         ;0450 'c'
              1723 0074  ld   $74         ;0451 't'
              1724 0075  ld   $75         ;0452 'u'
              1725 0072  ld   $72         ;0453 'r'
              1726 0065  ld   $65         ;0454 'e'
              1727 0073  ld   $73         ;0455 's'
              1728 0020  ld   $20         ;0456 ' '
              1729 0020  ld   $20         ;0457 ' '
              172a 0009  ld   $09         ;0458 9
              172b 0042  ld   $42         ;0459 'B'
              172c 0041  ld   $41         ;045a 'A'
              172d 0053  ld   $53         ;045b 'S'
              172e 0049  ld   $49         ;045c 'I'
              172f 0043  ld   $43         ;045d 'C'
              1730 000a  ld   $0a         ;045e 10
              1731 0009  ld   $09         ;045f 9
              1732 0043  ld   $43         ;0460 'C'
              1733 0072  ld   $72         ;0461 'r'
              1734 0065  ld   $65         ;0462 'e'
              1735 0064  ld   $64         ;0463 'd'
              1736 0069  ld   $69         ;0464 'i'
              1737 0074  ld   $74         ;0465 't'
              1738 0073  ld   $73         ;0466 's'
              1739 0009  ld   $09         ;0467 9
              173a 0009  ld   $09         ;0468 9
              173b 0057  ld   $57         ;0469 'W'
              173c 006f  ld   $6f         ;046a 'o'
              173d 007a  ld   $7a         ;046b 'z'
              173e 004d  ld   $4d         ;046c 'M'
              173f 006f  ld   $6f         ;046d 'o'
              1740 006e  ld   $6e         ;046e 'n'
              1741 000a  ld   $0a         ;046f 10
              1742 0009  ld   $09         ;0470 9
              1743 004c  ld   $4c         ;0471 'L'
              1744 006f  ld   $6f         ;0472 'o'
              1745 0061  ld   $61         ;0473 'a'
              1746 0064  ld   $64         ;0474 'd'
              1747 0065  ld   $65         ;0475 'e'
              1748 0072  ld   $72         ;0476 'r'
              1749 0009  ld   $09         ;0477 9
              174a 0020  ld   $20         ;0478 ' '
              174b 0009  ld   $09         ;0479 9
              174c 0041  ld   $41         ;047a 'A'
              174d 0070  ld   $70         ;047b 'p'
              174e 0070  ld   $70         ;047c 'p'
              174f 006c  ld   $6c         ;047d 'l'
              1750 0065  ld   $65         ;047e 'e'
              1751 0031  ld   $31         ;047f '1'
              1752 000a  ld   $0a         ;0480 10
              1753 0000  ld   $00         ;0481 0
              1754 002b  ld   $2b         ;0482 STW
              1755 0050  ld   $50         ;0482 'MainMenu'
              1756 00cd  ld   $cd         ;0484 DEF
              1757 00ce  ld   $ce
              1758 0055  ld   $55         ;0486 'U'
              1759 0073  ld   $73         ;0487 's'
              175a 0065  ld   $65         ;0488 'e'
              175b 0020  ld   $20         ;0489 ' '
              175c 005b  ld   $5b         ;048a 91
              175d 0041  ld   $41         ;048b 'A'
              175e 0072  ld   $72         ;048c 'r'
              175f 0072  ld   $72         ;048d 'r'
              1760 006f  ld   $6f         ;048e 'o'
              1761 0077  ld   $77         ;048f 'w'
              1762 0073  ld   $73         ;0490 's'
              1763 005d  ld   $5d         ;0491 93
              1764 0020  ld   $20         ;0492 ' '
              1765 0074  ld   $74         ;0493 't'
              1766 006f  ld   $6f         ;0494 'o'
              1767 0020  ld   $20         ;0495 ' '
              1768 0073  ld   $73         ;0496 's'
              1769 0065  ld   $65         ;0497 'e'
              176a 006c  ld   $6c         ;0498 'l'
              176b 0065  ld   $65         ;0499 'e'
              176c 0063  ld   $63         ;049a 'c'
              176d 0074  ld   $74         ;049b 't'
              176e 000a  ld   $0a         ;049c 10
              176f 0050  ld   $50         ;049d 'P'
              1770 0072  ld   $72         ;049e 'r'
              1771 0065  ld   $65         ;049f 'e'
              1772 0073  ld   $73         ;04a0 's'
              1773 0073  ld   $73         ;04a1 's'
              1774 0020  ld   $20         ;04a2 ' '
              1775 005b  ld   $5b         ;04a3 91
              1776 0041  ld   $41         ;04a4 'A'
              1777 005d  ld   $5d         ;04a5 93
              1778 0020  ld   $20         ;04a6 ' '
              1779 0074  ld   $74         ;04a7 't'
              177a 006f  ld   $6f         ;04a8 'o'
              177b 0020  ld   $20         ;04a9 ' '
              177c 0073  ld   $73         ;04aa 's'
              177d 0074  ld   $74         ;04ab 't'
              177e 0061  ld   $61         ;04ac 'a'
              177f 0072  ld   $72         ;04ad 'r'
              1780 0074  ld   $74         ;04ae 't'
              1781 0020  ld   $20         ;04af ' '
              1782 0070  ld   $70         ;04b0 'p'
              1783 0072  ld   $72         ;04b1 'r'
              1784 006f  ld   $6f         ;04b2 'o'
              1785 0067  ld   $67         ;04b3 'g'
              1786 0072  ld   $72         ;04b4 'r'
              1787 0061  ld   $61         ;04b5 'a'
              1788 006d  ld   $6d         ;04b6 'm'
              1789 000a  ld   $0a         ;04b7 10
              178a 000a  ld   $0a         ;04b8 10
              178b 0048  ld   $48         ;04b9 'H'
              178c 006f  ld   $6f         ;04ba 'o'
              178d 006c  ld   $6c         ;04bb 'l'
              178e 0064  ld   $64         ;04bc 'd'
              178f 0020  ld   $20         ;04bd ' '
              1790 005b  ld   $5b         ;04be 91
              1791 0053  ld   $53         ;04bf 'S'
              1792 0074  ld   $74         ;04c0 't'
              1793 0061  ld   $61         ;04c1 'a'
              1794 0072  ld   $72         ;04c2 'r'
              1795 0074  ld   $74         ;04c3 't'
              1796 005d  ld   $5d         ;04c4 93
              1797 0020  ld   $20         ;04c5 ' '
              1798 0066  ld   $66         ;04c6 'f'
              1799 006f  ld   $6f         ;04c7 'o'
              179a 0072  ld   $72         ;04c8 'r'
              179b 0020  ld   $20         ;04c9 ' '
              179c 0072  ld   $72         ;04ca 'r'
              179d 0065  ld   $65         ;04cb 'e'
              179e 0073  ld   $73         ;04cc 's'
              179f 0065  ld   $65         ;04cd 'e'
              17a0 0074  ld   $74         ;04ce 't'
              17a1 0000  ld   $00         ;04cf 0
              17a2 002b  ld   $2b         ;04d0 STW
              17a3 0052  ld   $52         ;04d0 'HelpText'
              17a4 0093  ld   $93         ;04d2 INC
              17a5 001b  ld   $1b         ;04d2 '_vLR'+1
              17a6 00ff  ld   $ff         ;04d4 RET
              17a7 0005  ld   $05         ;| RAM segment address (high byte first)
              17a8 0000  ld   $00         ;|
              17a9 00a5  ld   $a5         ;| Length (1..256)
              17aa 00cd  ld   $cd         ;0500 DEF
              17ab 0011  ld   $11
              17ac 0075  ld   $75         ;0502 PUSH
              17ad 0021  ld   $21         ;0503 LDW
              17ae 0038  ld   $38         ;0503 'Pos'
              17af 00e6  ld   $e6         ;0505 SUBI
              17b0 000c  ld   $0c
              17b1 002b  ld   $2b         ;0507 STW
              17b2 0038  ld   $38         ;0507 'Pos'
              17b3 0059  ld   $59         ;0509 LDI
              17b4 0020  ld   $20
              17b5 002b  ld   $2b         ;050b STW
              17b6 0030  ld   $30         ;050b 'Char'
              17b7 00cf  ld   $cf         ;050d CALL
              17b8 003a  ld   $3a         ;050d 'PrintChar'
              17b9 00cf  ld   $cf         ;050f CALL
              17ba 003a  ld   $3a         ;050f 'PrintChar'
              17bb 0063  ld   $63         ;0511 POP
              17bc 00ff  ld   $ff         ;0512 RET
              17bd 002b  ld   $2b         ;0513 STW
              17be 004a  ld   $4a         ;0513 'WipeOutArrow'
              17bf 00cd  ld   $cd         ;0515 DEF
              17c0 0030  ld   $30
              17c1 0075  ld   $75         ;0517 PUSH
              17c2 0059  ld   $59         ;0518 LDI
              17c3 002a  ld   $2a
              17c4 002b  ld   $2b         ;051a STW
              17c5 0036  ld   $36         ;051a 'Color'
              17c6 00cf  ld   $cf         ;051c CALL
              17c7 0044  ld   $44         ;051c 'PrintDivider'
              17c8 0059  ld   $59         ;051e LDI
              17c9 000f  ld   $0f
              17ca 002b  ld   $2b         ;0520 STW
              17cb 0036  ld   $36         ;0520 'Color'
              17cc 0021  ld   $21         ;0522 LDW
              17cd 0050  ld   $50         ;0522 'MainMenu'
              17ce 00cf  ld   $cf         ;0524 CALL
              17cf 0040  ld   $40         ;0524 'PrintText'
              17d0 0059  ld   $59         ;0526 LDI
              17d1 002a  ld   $2a
              17d2 002b  ld   $2b         ;0528 STW
              17d3 0036  ld   $36         ;0528 'Color'
              17d4 00cf  ld   $cf         ;052a CALL
              17d5 0044  ld   $44         ;052a 'PrintDivider'
              17d6 0021  ld   $21         ;052c LDW
              17d7 0052  ld   $52         ;052c 'HelpText'
              17d8 00cf  ld   $cf         ;052e CALL
              17d9 0040  ld   $40         ;052e 'PrintText'
              17da 0063  ld   $63         ;0530 POP
              17db 00ff  ld   $ff         ;0531 RET
              17dc 002b  ld   $2b         ;0532 STW
              17dd 0054  ld   $54         ;0532 'PrintMenu'
              17de 001a  ld   $1a         ;0534 LD
              17df 0021  ld   $21
              17e0 0088  ld   $88         ;0536 ORI
              17e1 0003  ld   $03
              17e2 005e  ld   $5e         ;0538 ST
              17e3 0021  ld   $21
              17e4 0059  ld   $59         ;053a LDI
              17e5 005a  ld   $5a
              17e6 005e  ld   $5e         ;053c ST
              17e7 002c  ld   $2c
              17e8 0011  ld   $11         ;053e LDWI
              17e9 0002  ld   $02
              17ea 0020  ld   $20
              17eb 002b  ld   $2b         ;0541 STW
              17ec 0038  ld   $38         ;0541 'Pos'
              17ed 00cf  ld   $cf         ;0543 CALL
              17ee 0054  ld   $54         ;0543 'PrintMenu'
              17ef 0059  ld   $59         ;0545 LDI
              17f0 0000  ld   $00
              17f1 002b  ld   $2b         ;0547 STW
              17f2 0046  ld   $46         ;0547 'MenuItem'
              17f3 00cf  ld   $cf         ;0549 CALL
              17f4 004e  ld   $4e         ;0549 'SelectMenu'
              17f5 0011  ld   $11         ;054b LDWI
              17f6 0000  ld   $00
              17f7 0008  ld   $08
              17f8 002b  ld   $2b         ;054e STW
              17f9 0028  ld   $28
              17fa 0011  ld   $11         ;0550 LDWI
              17fb fe00  bra  ac          ;+-----------------------------------+
              17fc fcfd  bra  $17fd       ;|                                   |
              17fd 1404  ld   $04,y       ;| Trampoline for page $1700 lookups |
              17fe e068  jmp  y,$68       ;|                                   |
              17ff c218  st   [$18]       ;+-----------------------------------+
              1800 0001  ld   $01
              1801 0088  ld   $88
              1802 002b  ld   $2b         ;0553 STW
              1803 0032  ld   $32         ;0553 'i'
              1804 0011  ld   $11         ;0555 LDWI
              1805 0080  ld   $80
              1806 00ff  ld   $ff
              1807 002b  ld   $2b         ;0558 STW
              1808 0042  ld   $42         ;0558 'j'
              1809 0021  ld   $21         ;055a LDW
              180a 0038  ld   $38         ;055a 'Pos'
              180b 00e3  ld   $e3         ;055c ADDI
              180c 0030  ld   $30
              180d 00f8  ld   $f8         ;055e ANDW
              180e 0042  ld   $42         ;055e 'j'
              180f 002b  ld   $2b         ;0560 STW
              1810 0056  ld   $56         ;0560 'q'
              1811 0011  ld   $11         ;0562 LDWI
              1812 00e1  ld   $e1
              1813 0004  ld   $04
              1814 002b  ld   $2b         ;0565 STW
              1815 0022  ld   $22
              1816 0059  ld   $59         ;0567 LDI
              1817 0020  ld   $20
              1818 005e  ld   $5e         ;0569 ST
              1819 0024  ld   $24
              181a 005e  ld   $5e         ;056b ST
              181b 0025  ld   $25
              181c 0021  ld   $21         ;056d LDW
              181d 0028  ld   $28
              181e 00e3  ld   $e3         ;056f ADDI
              181f 0030  ld   $30
              1820 00f8  ld   $f8         ;0571 ANDW
              1821 0042  ld   $42         ;0571 'j'
              1822 00fc  ld   $fc         ;0573 XORW
              1823 0056  ld   $56         ;0573 'q'
              1824 0035  ld   $35         ;0575 BCC
              1825 003f  ld   $3f         ;0576 EQ
              1826 007f  ld   $7f
              1827 001a  ld   $1a         ;0578 LD
              1828 0059  ld   $59         ;0578 'p'+1
              1829 008c  ld   $8c         ;057a XORI
              182a 0078  ld   $78
              182b 0035  ld   $35         ;057c BCC
              182c 003f  ld   $3f         ;057d EQ
              182d 007f  ld   $7f
              182e 00b4  ld   $b4         ;057f SYS
              182f 00cb  ld   $cb
              1830 0011  ld   $11         ;0581 LDWI
              1831 0000  ld   $00
              1832 0008  ld   $08
              1833 0099  ld   $99         ;0584 921
              1834 0028  ld   $28         ;0585 40
              1835 002b  ld   $2b         ;0586 STW
              1836 0028  ld   $28
              1837 0035  ld   $35         ;0588 BCC
              1838 004d  ld   $4d         ;0589 GT
              1839 006d  ld   $6d
              183a 0099  ld   $99         ;058b ADDW
              183b 0032  ld   $32         ;058b 'i'
              183c 002b  ld   $2b         ;058d STW
              183d 0028  ld   $28
              183e 0082  ld   $82         ;058f ANDI
              183f 00ff  ld   $ff
              1840 008c  ld   $8c         ;0591 XORI
              1841 00a0  ld   $a0
              1842 0035  ld   $35         ;0593 BCC
              1843 0072  ld   $72         ;0594 NE
              1844 006b  ld   $6b
              1845 0059  ld   $59         ;0596 LDI
              1846 00ad  ld   $ad
              1847 002b  ld   $2b         ;0598 STW
              1848 0022  ld   $22
              1849 0021  ld   $21         ;059a LDW
              184a 004c  ld   $4c         ;059a 'Program'
              184b 002b  ld   $2b         ;059c STW
              184c 0024  ld   $24
              184d 0011  ld   $11         ;059e LDWI
              184e 0000  ld   $00
              184f 0002  ld   $02
              1850 002b  ld   $2b         ;05a1 STW
              1851 001a  ld   $1a         ;05a1 '_vLR'
              1852 00b4  ld   $b4         ;05a3 SYS
              1853 00e2  ld   $e2
              1854 0000  ld   $00         ;End of MainMenu\MainMenu.gcl, size 853
                                          ;+-----------------------------------+
                                          ;| Reset.gcl                         |
                                          ;+-----------------------------------+
Reset:        1855 0002  ld   $02         ;| RAM segment address (high byte first)
              1856 0000  ld   $00         ;|
              1857 00d0  ld   $d0         ;| Length (1..256)
              1858 0011  ld   $11         ;0200 LDWI
              1859 0009  ld   $09
              185a 000b  ld   $0b
              185b 002b  ld   $2b         ;0203 STW
              185c 0022  ld   $22         ;0203 '_sysFn'
              185d 0059  ld   $59         ;0205 LDI
              185e 007c  ld   $7c
              185f 00b4  ld   $b4         ;0207 SYS
              1860 00fa  ld   $fa
              1861 00cd  ld   $cd         ;0209 DEF
              1862 0045  ld   $45
              1863 0011  ld   $11         ;020b LDWI
              1864 0000  ld   $00
              1865 0001  ld   $01
              1866 002b  ld   $2b         ;020e STW
              1867 0030  ld   $30         ;020e 'p'
              1868 0011  ld   $11         ;0210 LDWI
              1869 0000  ld   $00
              186a 0008  ld   $08
              186b 002b  ld   $2b         ;0213 STW
              186c 0032  ld   $32         ;0213 'q'
              186d 001a  ld   $1a         ;0215 LD
              186e 0033  ld   $33         ;0215 'q'+1
              186f 00f0  ld   $f0         ;0217 POKE
              1870 0030  ld   $30         ;0217 'p'
              1871 0093  ld   $93         ;0219 INC
              1872 0030  ld   $30         ;0219 'p'
              1873 0059  ld   $59         ;021b LDI
              1874 0000  ld   $00
              1875 00f0  ld   $f0         ;021d POKE
              1876 0030  ld   $30         ;021d 'p'
              1877 0093  ld   $93         ;021f INC
              1878 0030  ld   $30         ;021f 'p'
              1879 0093  ld   $93         ;0221 INC
              187a 0033  ld   $33         ;0221 'q'+1
              187b 0021  ld   $21         ;0223 LDW
              187c 0032  ld   $32         ;0223 'q'
              187d 0035  ld   $35         ;0225 BCC
              187e 004d  ld   $4d         ;0226 GT
              187f 0013  ld   $13
              1880 0011  ld   $11         ;0228 LDWI
              1881 0003  ld   $03
              1882 000b  ld   $0b
              1883 002b  ld   $2b         ;022b STW
              1884 0022  ld   $22
              1885 0059  ld   $59         ;022d LDI
              1886 0020  ld   $20
              1887 005e  ld   $5e         ;022f ST
              1888 0025  ld   $25
              1889 0011  ld   $11         ;0231 LDWI
              188a 0000  ld   $00
              188b 0008  ld   $08
              188c 002b  ld   $2b         ;0234 STW
              188d 0030  ld   $30         ;0234 'p'
              188e 002b  ld   $2b         ;0236 STW
              188f 0026  ld   $26
              1890 0059  ld   $59         ;0238 LDI
              1891 00a0  ld   $a0
              1892 005e  ld   $5e         ;023a ST
              1893 0024  ld   $24
              1894 00b4  ld   $b4         ;023c SYS
              1895 00f3  ld   $f3
              1896 0011  ld   $11         ;023e LDWI
              1897 0000  ld   $00
              1898 0001  ld   $01
              1899 0099  ld   $99         ;0241 ADDW
              189a 0030  ld   $30         ;0241 'p'
              189b 0035  ld   $35         ;0243 BCC
              189c 004d  ld   $4d         ;0244 GT
              189d 0032  ld   $32
              189e 00ff  ld   $ff         ;0246 RET
              189f 002b  ld   $2b         ;0247 STW
              18a0 0034  ld   $34         ;0247 'SetupVideo'
              18a1 00cd  ld   $cd         ;0249 DEF
              18a2 00c9  ld   $c9
              18a3 0075  ld   $75         ;024b PUSH
              18a4 00cd  ld   $cd         ;024c DEF
              18a5 007b  ld   $7b
              18a6 002a  ld   $2a         ;024e '*'
              18a7 002a  ld   $2a         ;024f '*'
              18a8 002a  ld   $2a         ;0250 '*'
              18a9 0020  ld   $20         ;0251 ' '
              18aa 0047  ld   $47         ;0252 'G'
              18ab 0069  ld   $69         ;0253 'i'
              18ac 0067  ld   $67         ;0254 'g'
              18ad 0061  ld   $61         ;0255 'a'
              18ae 0074  ld   $74         ;0256 't'
              18af 0072  ld   $72         ;0257 'r'
              18b0 006f  ld   $6f         ;0258 'o'
              18b1 006e  ld   $6e         ;0259 'n'
              18b2 0020  ld   $20         ;025a ' '
              18b3 003f  ld   $3f         ;025b '?'
              18b4 003f  ld   $3f         ;025c '?'
              18b5 004b  ld   $4b         ;025d 'K'
              18b6 0020  ld   $20         ;025e ' '
              18b7 002a  ld   $2a         ;025f '*'
              18b8 002a  ld   $2a         ;0260 '*'
              18b9 002a  ld   $2a         ;0261 '*'
              18ba 000a  ld   $0a         ;0262 10
              18bb 0020  ld   $20         ;0263 ' '
              18bc 0054  ld   $54         ;0264 'T'
              18bd 0054  ld   $54         ;0265 'T'
              18be 004c  ld   $4c         ;0266 'L'
              18bf 0020  ld   $20         ;0267 ' '
              18c0 006d  ld   $6d         ;0268 'm'
              18c1 0069  ld   $69         ;0269 'i'
              18c2 0063  ld   $63         ;026a 'c'
              18c3 0072  ld   $72         ;026b 'r'
              18c4 006f  ld   $6f         ;026c 'o'
              18c5 0063  ld   $63         ;026d 'c'
              18c6 006f  ld   $6f         ;026e 'o'
              18c7 006d  ld   $6d         ;026f 'm'
              18c8 0070  ld   $70         ;0270 'p'
              18c9 0075  ld   $75         ;0271 'u'
              18ca 0074  ld   $74         ;0272 't'
              18cb 0065  ld   $65         ;0273 'e'
              18cc 0072  ld   $72         ;0274 'r'
              18cd 0020  ld   $20         ;0275 ' '
              18ce 0044  ld   $44         ;0276 'D'
              18cf 0045  ld   $45         ;0277 'E'
              18d0 0056  ld   $56         ;0278 'V'
              18d1 0052  ld   $52         ;0279 'R'
              18d2 004f  ld   $4f         ;027a 'O'
              18d3 004d  ld   $4d         ;027b 'M'
              18d4 0000  ld   $00         ;027c 0
              18d5 002b  ld   $2b         ;027d STW
              18d6 0036  ld   $36         ;027d 'Text'
              18d7 00e3  ld   $e3         ;027f ADDI
              18d8 000d  ld   $0d
              18d9 002b  ld   $2b         ;0281 STW
              18da 0030  ld   $30         ;0281 'p'
              18db 0011  ld   $11         ;0283 LDWI
              18dc 002f  ld   $2f
              18dd 002f  ld   $2f
              18de 002b  ld   $2b         ;0286 STW
              18df 0038  ld   $38         ;0286 'Char'
              18e0 001a  ld   $1a         ;0288 LD
              18e1 0001  ld   $01
              18e2 00e6  ld   $e6         ;028a SUBI
              18e3 0001  ld   $01
              18e4 0082  ld   $82         ;028c ANDI
              18e5 00ff  ld   $ff
              18e6 00e3  ld   $e3         ;028e ADDI
              18e7 0001  ld   $01
              18e8 0093  ld   $93         ;0290 INC
              18e9 0039  ld   $39         ;0290 'Char'+1
              18ea 00e6  ld   $e6         ;0292 SUBI
              18eb 0028  ld   $28
              18ec 0035  ld   $35         ;0294 BCC
              18ed 0053  ld   $53         ;0295 GE
              18ee 008e  ld   $8e
              18ef 00e3  ld   $e3         ;0297 ADDI
              18f0 0028  ld   $28
              18f1 0093  ld   $93         ;0299 INC
              18f2 0038  ld   $38         ;0299 'Char'
              18f3 00e6  ld   $e6         ;029b SUBI
              18f4 0004  ld   $04
              18f5 0035  ld   $35         ;029d BCC
              18f6 0053  ld   $53         ;029e GE
              18f7 0097  ld   $97
              18f8 001a  ld   $1a         ;02a0 LD
              18f9 0039  ld   $39         ;02a0 'Char'+1
              18fa 00f0  ld   $f0         ;02a2 POKE
              18fb fe00  bra  ac          ;+-----------------------------------+
              18fc fcfd  bra  $18fd       ;|                                   |
              18fd 1404  ld   $04,y       ;| Trampoline for page $1800 lookups |
              18fe e068  jmp  y,$68       ;|                                   |
              18ff c218  st   [$18]       ;+-----------------------------------+
              1900 0030  ld   $30         ;02a2 'p'
              1901 0093  ld   $93         ;02a4 INC
              1902 0030  ld   $30         ;02a4 'p'
              1903 0021  ld   $21         ;02a6 LDW
              1904 0038  ld   $38         ;02a6 'Char'
              1905 00f0  ld   $f0         ;02a8 POKE
              1906 0030  ld   $30         ;02a8 'p'
              1907 0021  ld   $21         ;02aa LDW
              1908 0036  ld   $36         ;02aa 'Text'
              1909 00ad  ld   $ad         ;02ac PEEK
              190a 0035  ld   $35         ;02ad BCC
              190b 003f  ld   $3f         ;02ae EQ
              190c 00c7  ld   $c7
              190d 002b  ld   $2b         ;02b0 STW
              190e 0038  ld   $38         ;02b0 'Char'
              190f 0093  ld   $93         ;02b2 INC
              1910 0036  ld   $36         ;02b2 'Text'
              1911 008c  ld   $8c         ;02b4 XORI
              1912 000a  ld   $0a
              1913 0035  ld   $35         ;02b6 BCC
              1914 0072  ld   $72         ;02b7 NE
              1915 00c3  ld   $c3
              1916 0059  ld   $59         ;02b9 LDI
              1917 0002  ld   $02
              1918 005e  ld   $5e         ;02bb ST
              1919 003a  ld   $3a         ;02bb 'Pos'
              191a 001a  ld   $1a         ;02bd LD
              191b 003b  ld   $3b         ;02bd 'Pos'+1
              191c 00e3  ld   $e3         ;02bf ADDI
              191d 0008  ld   $08
              191e 005e  ld   $5e         ;02c1 ST
              191f 003b  ld   $3b         ;02c1 'Pos'+1
              1920 0090  ld   $90         ;02c3 BRA
              1921 00c5  ld   $c5
              1922 00cf  ld   $cf         ;02c5 CALL
              1923 003c  ld   $3c         ;02c5 'PrintChar'
              1924 0090  ld   $90         ;02c7 BRA
              1925 00a8  ld   $a8
              1926 0063  ld   $63         ;02c9 POP
              1927 00ff  ld   $ff         ;02ca RET
              1928 002b  ld   $2b         ;02cb STW
              1929 003e  ld   $3e         ;02cb 'PrintStartupMessage'
              192a 0093  ld   $93         ;02cd INC
              192b 001b  ld   $1b
              192c 00ff  ld   $ff         ;02cf RET
              192d 0003  ld   $03         ;| RAM segment address (high byte first)
              192e 0000  ld   $00         ;|
              192f 00e7  ld   $e7         ;| Length (1..256)
              1930 00cd  ld   $cd         ;0300 DEF
              1931 004b  ld   $4b
              1932 0021  ld   $21         ;0302 LDW
              1933 0038  ld   $38         ;0302 'Char'
              1934 00e6  ld   $e6         ;0304 SUBI
              1935 0052  ld   $52
              1936 0035  ld   $35         ;0306 BCC
              1937 0053  ld   $53         ;0307 GE
              1938 0010  ld   $10
              1939 00e3  ld   $e3         ;0309 ADDI
              193a 0032  ld   $32
              193b 002b  ld   $2b         ;030b STW
              193c 0040  ld   $40         ;030b 'i'
              193d 0011  ld   $11         ;030d LDWI
              193e 0000  ld   $00
              193f 0007  ld   $07
              1940 0090  ld   $90         ;0310 BRA
              1941 0015  ld   $15
              1942 002b  ld   $2b         ;0312 STW
              1943 0040  ld   $40         ;0312 'i'
              1944 0011  ld   $11         ;0314 LDWI
              1945 0000  ld   $00
              1946 0008  ld   $08
              1947 002b  ld   $2b         ;0317 STW
              1948 0042  ld   $42         ;0317 'j'
              1949 0021  ld   $21         ;0319 LDW
              194a 0040  ld   $40         ;0319 'i'
              194b 00e9  ld   $e9         ;031b LSLW
              194c 00e9  ld   $e9         ;031c LSLW
              194d 0099  ld   $99         ;031d ADDW
              194e 0040  ld   $40         ;031d 'i'
              194f 0099  ld   $99         ;031f ADDW
              1950 0042  ld   $42         ;031f 'j'
              1951 002b  ld   $2b         ;0321 STW
              1952 0042  ld   $42         ;0321 'j'
              1953 0011  ld   $11         ;0323 LDWI
              1954 00e1  ld   $e1
              1955 0004  ld   $04
              1956 002b  ld   $2b         ;0326 STW
              1957 0022  ld   $22
              1958 0011  ld   $11         ;0328 LDWI
              1959 0020  ld   $20
              195a 003f  ld   $3f
              195b 002b  ld   $2b         ;032b STW
              195c 0024  ld   $24
              195d 0021  ld   $21         ;032d LDW
              195e 003a  ld   $3a         ;032d 'Pos'
              195f 002b  ld   $2b         ;032f STW
              1960 0028  ld   $28
              1961 00e3  ld   $e3         ;0331 ADDI
              1962 0006  ld   $06
              1963 002b  ld   $2b         ;0333 STW
              1964 003a  ld   $3a         ;0333 'Pos'
              1965 0059  ld   $59         ;0335 LDI
              1966 0005  ld   $05
              1967 002b  ld   $2b         ;0337 STW
              1968 0040  ld   $40         ;0337 'i'
              1969 0021  ld   $21         ;0339 LDW
              196a 0042  ld   $42         ;0339 'j'
              196b 007f  ld   $7f         ;033b LUP
              196c 0000  ld   $00
              196d 005e  ld   $5e         ;033d ST
              196e 0026  ld   $26
              196f 00b4  ld   $b4         ;033f SYS
              1970 00cb  ld   $cb
              1971 0093  ld   $93         ;0341 INC
              1972 0042  ld   $42         ;0341 'j'
              1973 0093  ld   $93         ;0343 INC
              1974 0028  ld   $28
              1975 0021  ld   $21         ;0345 LDW
              1976 0040  ld   $40         ;0345 'i'
              1977 00e6  ld   $e6         ;0347 SUBI
              1978 0001  ld   $01
              1979 0035  ld   $35         ;0349 BCC
              197a 004d  ld   $4d         ;034a GT
              197b 0035  ld   $35
              197c 00ff  ld   $ff         ;034c RET
              197d 002b  ld   $2b         ;034d STW
              197e 003c  ld   $3c         ;034d 'PrintChar'
              197f 00cd  ld   $cd         ;034f DEF
              1980 0086  ld   $86
              1981 002b  ld   $2b         ;0351 STW
              1982 0040  ld   $40         ;0351 'i'
              1983 0088  ld   $88         ;0353 ORI
              1984 00ff  ld   $ff
              1985 008c  ld   $8c         ;0355 XORI
              1986 00ff  ld   $ff
              1987 0088  ld   $88         ;0357 ORI
              1988 00fa  ld   $fa
              1989 002b  ld   $2b         ;0359 STW
              198a 0030  ld   $30         ;0359 'p'
              198b 001a  ld   $1a         ;035b LD
              198c 0040  ld   $40         ;035b 'i'
              198d 002b  ld   $2b         ;035d STW
              198e 0040  ld   $40         ;035d 'i'
              198f 0059  ld   $59         ;035f LDI
              1990 0000  ld   $00
              1991 00f0  ld   $f0         ;0361 POKE
              1992 0030  ld   $30         ;0361 'p'
              1993 0093  ld   $93         ;0363 INC
              1994 0030  ld   $30         ;0363 'p'
              1995 0059  ld   $59         ;0365 LDI
              1996 0003  ld   $03
              1997 00f0  ld   $f0         ;0367 POKE
              1998 0030  ld   $30         ;0367 'p'
              1999 0093  ld   $93         ;0369 INC
              199a 0030  ld   $30         ;0369 'p'
              199b 0011  ld   $11         ;036b LDWI
              199c 0000  ld   $00
              199d 0009  ld   $09
              199e 0099  ld   $99         ;036e ADDW
              199f 0040  ld   $40         ;036e 'i'
              19a0 007f  ld   $7f         ;0370 LUP
              19a1 0000  ld   $00
              19a2 00f0  ld   $f0         ;0372 POKE
              19a3 0030  ld   $30         ;0372 'p'
              19a4 0093  ld   $93         ;0374 INC
              19a5 0030  ld   $30         ;0374 'p'
              19a6 0011  ld   $11         ;0376 LDWI
              19a7 0000  ld   $00
              19a8 0009  ld   $09
              19a9 0099  ld   $99         ;0379 ADDW
              19aa 0040  ld   $40         ;0379 'i'
              19ab 007f  ld   $7f         ;037b LUP
              19ac 0001  ld   $01
              19ad 00f0  ld   $f0         ;037d POKE
              19ae 0030  ld   $30         ;037d 'p'
              19af 0093  ld   $93         ;037f INC
              19b0 0030  ld   $30         ;037f 'p'
              19b1 00f0  ld   $f0         ;0381 POKE
              19b2 0030  ld   $30         ;0381 'p'
              19b3 0093  ld   $93         ;0383 INC
              19b4 0030  ld   $30         ;0383 'p'
              19b5 00f0  ld   $f0         ;0385 POKE
              19b6 0030  ld   $30         ;0385 'p'
              19b7 00ff  ld   $ff         ;0387 RET
              19b8 002b  ld   $2b         ;0388 STW
              19b9 0044  ld   $44         ;0388 'SetupChannel'
              19ba 0011  ld   $11         ;038a LDWI
              19bb 000f  ld   $0f
              19bc 000b  ld   $0b
              19bd 002b  ld   $2b         ;038d STW
              19be 0022  ld   $22
              19bf 0059  ld   $59         ;038f LDI
              19c0 0000  ld   $00
              19c1 00b4  ld   $b4         ;0391 SYS
              19c2 00f5  ld   $f5
              19c3 0011  ld   $11         ;0393 LDWI
              19c4 0012  ld   $12
              19c5 000b  ld   $0b
              19c6 002b  ld   $2b         ;0396 STW
              19c7 0022  ld   $22
              19c8 0059  ld   $59         ;0398 LDI
              19c9 0000  ld   $00
              19ca 00b4  ld   $b4         ;039a SYS
              19cb 00f7  ld   $f7
              19cc 00b4  ld   $b4         ;039c SYS
              19cd 00f7  ld   $f7
              19ce 00b4  ld   $b4         ;039e SYS
              19cf 00f7  ld   $f7
              19d0 00b4  ld   $b4         ;03a0 SYS
              19d1 00f7  ld   $f7
              19d2 0011  ld   $11         ;03a2 LDWI
              19d3 0058  ld   $58
              19d4 0001  ld   $01
              19d5 00cf  ld   $cf         ;03a5 CALL
              19d6 0044  ld   $44         ;03a5 'SetupChannel'
              19d7 0011  ld   $11         ;03a7 LDWI
              19d8 0070  ld   $70
              19d9 0002  ld   $02
              19da 00cf  ld   $cf         ;03aa CALL
              19db 0044  ld   $44         ;03aa 'SetupChannel'
              19dc 0011  ld   $11         ;03ac LDWI
              19dd 0078  ld   $78
              19de 0003  ld   $03
              19df 00cf  ld   $cf         ;03af CALL
              19e0 0044  ld   $44         ;03af 'SetupChannel'
              19e1 0011  ld   $11         ;03b1 LDWI
              19e2 007e  ld   $7e
              19e3 0004  ld   $04
              19e4 00cf  ld   $cf         ;03b4 CALL
              19e5 0044  ld   $44         ;03b4 'SetupChannel'
              19e6 00cf  ld   $cf         ;03b6 CALL
              19e7 0034  ld   $34         ;03b6 'SetupVideo'
              19e8 0011  ld   $11         ;03b8 LDWI
              19e9 0014  ld   $14
              19ea 0008  ld   $08
              19eb 002b  ld   $2b         ;03bb STW
              19ec 003a  ld   $3a         ;03bb 'Pos'
              19ed 00cf  ld   $cf         ;03bd CALL
              19ee 003e  ld   $3e         ;03bd 'PrintStartupMessage'
              19ef 001a  ld   $1a         ;03bf LD
              19f0 002e  ld   $2e
              19f1 0082  ld   $82         ;03c1 ANDI
              19f2 0080  ld   $80
              19f3 0035  ld   $35         ;03c3 BCC
              19f4 0072  ld   $72         ;03c4 NE
              19f5 00c8  ld   $c8
              19f6 005e  ld   $5e         ;03c6 ST
              19f7 002e  ld   $2e
              19f8 005e  ld   $5e         ;03c8 ST
              19f9 002d  ld   $2d
              19fa 0059  ld   $59         ;03ca LDI
              19fb fe00  bra  ac          ;+-----------------------------------+
              19fc fcfd  bra  $19fd       ;|                                   |
              19fd 1404  ld   $04,y       ;| Trampoline for page $1900 lookups |
              19fe e068  jmp  y,$68       ;|                                   |
              19ff c218  st   [$18]       ;+-----------------------------------+
              1a00 0009  ld   $09
              1a01 005e  ld   $5e         ;03cc ST
              1a02 002f  ld   $2f
              1a03 0011  ld   $11         ;03ce LDWI
              1a04 0000  ld   $00
              1a05 000b  ld   $0b
              1a06 002b  ld   $2b         ;03d1 STW
              1a07 0022  ld   $22
              1a08 0059  ld   $59         ;03d3 LDI
              1a09 0001  ld   $01
              1a0a 00b4  ld   $b4         ;03d5 SYS
              1a0b 00e6  ld   $e6
              1a0c 0011  ld   $11         ;03d7 LDWI
              1a0d 0000  ld   $00
              1a0e 0015  ld   $15
              1a0f 002b  ld   $2b         ;03da STW
              1a10 0024  ld   $24
              1a11 0011  ld   $11         ;03dc LDWI
              1a12 0000  ld   $00
              1a13 0002  ld   $02
              1a14 002b  ld   $2b         ;03df STW
              1a15 001a  ld   $1a
              1a16 0059  ld   $59         ;03e1 LDI
              1a17 00ad  ld   $ad
              1a18 002b  ld   $2b         ;03e3 STW
              1a19 0022  ld   $22
              1a1a 00b4  ld   $b4         ;03e5 SYS
              1a1b 00e2  ld   $e2
              1a1c 0000  ld   $00         ;End of Reset.gcl, size 456
              1a1d 0200  nop              ;222 fillers
              1a1e 0200  nop
              1a1f 0200  nop
              * 222 times
              1afb fe00  bra  ac          ;+-----------------------------------+
              1afc fcfd  bra  $1afd       ;|                                   |
              1afd 1404  ld   $04,y       ;| Trampoline for page $1a00 lookups |
              1afe e068  jmp  y,$68       ;|                                   |
              1aff c218  st   [$18]       ;+-----------------------------------+
              1b00
