;<--------------------------------->
; Benchmark template for Atari 2600
;               by OrionSoft [2026]
;<--------------------------------->

	.code
	.bank	0
	.org	$F000

	; VCS hardware defines

VSYNC	= $00
VBLANK	= $01
WSYNC	= $02
NUSIZ0	= $04
NUSIZ1	= $05
COLUP0	= $06
COLUP1	= $07
COLUPF	= $08
COLUBK	= $09
CTRLPF	= $0A
PF0  	= $0D
PF1  	= $0E
PF2  	= $0F
RESP0	= $10
RESP1	= $11
GRP0 	= $1B
GRP1 	= $1C
ENAM0	= $1D
ENAM1	= $1E
ENABL	= $1F
HMP0 	= $20
HMP1 	= $21
VDELP0	= $25
VDELP1	= $26
HMOVE	= $2A
INPT4	= $0C
TIMINT	= $285
TIM64T	= $296

	; Screen timing

SCANLINE_TIME	= 76

;	.if	PAL
;VBLANK_LINES	= 45
;SCREEN_LINES	= 228
;OVERSCAN_LINES	= 36
;	.else		; NTSC
VBLANK_LINES	= 37
SCREEN_LINES	= 192
OVERSCAN_LINES	= 30
;	.endif

	; Zero Page variables

crc8	= $80
ZP_BASE	= $81	; Keep crc8
counter	= $81
tmp	= $82
txtptr	= $83

Start:
	; Clear Memory
	sei
	cld
	ldx	#0
	txa
	tay
clrstk:	dex
	txs
	pha
	bne	clrstk

	lda	#LOW(txt_title)
	ldy	#HIGH(txt_title)
	jsr	SetText

MainDisplayLoop:
	lda	#0
	ldy	#$82
	sty	<VBLANK	; VBlank
	sta	<WSYNC
	sty	<VSYNC	; VSync On
	sta	<WSYNC	; VSync for 3 lines
	sta	<WSYNC
	sta	<WSYNC
	sta	<VSYNC	; VSync Off

	lda	#(VBLANK_LINES*SCANLINE_TIME)/64
	sta	TIM64T	; Configure Timer for VBlank Timing

;---------------------------------------->
; Setup Drawing: 48 pixels sprite centered on screen

	lda	#1
	sta	<VDELP0
	sta	<VDELP1
	lda	#3
	sta	<NUSIZ0
	sta	<NUSIZ1
	lda	#$F

	sta	<WSYNC
	sta	<COLUP0
	sta	<COLUP1
	lda	#0
	sta	<PF0
	sta	<PF1
	sta	<PF2
	sta	<ENAM0
	sta	<ENAM1
	sta	<ENABL
	sta	<CTRLPF
	sta	<COLUBK
	sta	<COLUPF
	sta	<RESP0		; -> Cycle 38 (Position Sprite 0 to center of screen 55)
	lda	#$C0
	sta	<RESP1		; -> Cycle 43 (Position Sprite 1 to center of screen 55+8)
	sta	<HMP0
	lda	#$30
	sta	<HMP1
	sta	<WSYNC
	sta	<HMOVE
	sta	<WSYNC

	lda	#31-1		; 31 lines sprite
	sta	<counter

;---------------------------------------->
; Wait for VBlank to Finish

	lda	#0
.vbwait:
	bit	TIMINT
	bpl	.vbwait
	sta	<VBLANK		; VBlank Off just before the end of the last VBlank line

;---------------------------------------->
; Drawing Start !

	ldy	#80
.UpperLoop:
	sta	<WSYNC
	dey
	bne	.UpperLoop

.TextLoop:
	ldy	<counter
	lda	[<txtptr],y
	sta	<GRP0
	sta	<WSYNC
	lda	[<txtptr+2],y
	sta	<GRP1
	lda	[<txtptr+4],y
	sta	<GRP0
	lda	[<txtptr+6],y
	sta	<tmp
	lda	[<txtptr+8],y
	tax
	lda	[<txtptr+10],y
	tay
	lda	<tmp
	sta	<GRP1
	stx	<GRP0
	sty	<GRP1
	sta	<GRP0
	dec	<counter
	bpl	.TextLoop

	lda	#0
	sta	<GRP0
	sta	<GRP1
	sta	<GRP0

	ldy	#SCREEN_LINES-(31+80)
.BottomLoop:
	sta	<WSYNC
	dey
	bne	.BottomLoop
	sta	<WSYNC

;---------------------------------------->
; Overscan

	lda	#$82	; VBlank On
	sta	<VBLANK

	lda	#(OVERSCAN_LINES*SCANLINE_TIME)/64
	sta	TIM64T	; Configure Timer for VBlank Timing
.ovloop:
	bit	TIMINT	; Wait for Overscan to Finish (using PreConfigured Timer)
	bpl	.ovloop

;---------------------------------------->

	lda	#$80		; Joystick Button
	bit	<INPT4		; Compare it to Button Register
	beq	StartBenchMark
	jmp	MainDisplayLoop

;---------------------------------------->

SetText:
	ldx	#-12		; 6 columns of 8 pixels * 16bits pointer
.sloop:	sta	<txtptr+12,x	; Store Low
	sty	<txtptr+13,x	; Store High
	clc
	adc	#31		; next column (31 pixels height)
	bcc	.snc
	iny
.snc:	inx
	inx
	bne	.sloop          ; sort quand X repasse à 0
	rts

;---------------------------------------->

StartBenchMark:

	lda	#$FF		; Init CRC8
	sta	<crc8

	.include	"../../bench_cpu/6502/bench_cpu_6502.asm"

	lda	<crc8
	cmp	#BENCHMARK_CRC8_RESULT
	beq	crcValid
	lda	#LOW(txt_error)
	ldy	#HIGH(txt_error)
	jmp	next_display
crcValid:
	lda	#LOW(txt_valid)
	ldy	#HIGH(txt_valid)
next_display:
	jsr	SetText
	jmp	MainDisplayLoop

;---------------------------------------->

	.ORG	$FC00	; aligned to skip page boundary cycle stuff

txt_title:
	db	$00,$00,$00,$00,$00,$00,$8A,$8A,$CC,$AA,$CC,$00,$00,$00,$C4,$A4,$C4,$AA,$CA,$00,$00,$00,$00,$00,$00,$00,$AC,$A8,$CC,$A8,$CD
	db	$00,$00,$00,$00,$00,$00,$D9,$84,$C8,$91,$CC,$00,$00,$00,$19,$25,$25,$25,$19,$00,$33,$2A,$33,$2A,$33,$00,$94,$95,$99,$95,$D8
	db	$11,$12,$12,$12,$39,$00,$86,$45,$86,$05,$C6,$00,$00,$00,$53,$54,$94,$54,$93,$00,$49,$5A,$7A,$6A,$49,$00,$C1,$22,$22,$22,$C1
	db	$86,$41,$42,$44,$83,$00,$72,$52,$52,$52,$57,$00,$00,$00,$25,$AC,$BC,$B5,$24,$00,$AA,$2A,$3A,$2A,$AB,$00,$A3,$22,$32,$2A,$B2
	db	$25,$25,$27,$25,$72,$00,$23,$24,$24,$24,$73,$00,$00,$00,$8C,$52,$92,$12,$CC,$00,$AA,$AA,$AE,$AA,$64,$00,$80,$80,$80,$80,$80
	db	$52,$52,$62,$52,$67,$00,$24,$AC,$BC,$B4,$24,$00,$00,$00,$84,$84,$C4,$84,$EE,$00,$A9,$AA,$CC,$AA,$C9,$00,$00,$00,$00,$00,$00

	.ORG	$FD00	; aligned to skip page boundary cycle stuff

txt_valid:
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$AD,$A8,$CC,$A9,$CC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$9D,$55,$95,$15,$D5,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$90,$11,$10,$11,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$12,$2A,$2B,$2A,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$B5,$A5,$A5,$A5,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$40,$40,$40,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	.ORG	$FE00	; aligned to skip page boundary cycle stuff

txt_error:
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$AD,$A8,$CC,$A9,$CC,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$9D,$55,$95,$15,$D5,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$90,$11,$10,$11,$38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$35,$25,$36,$25,$36,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$54,$64,$54,$63,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$28,$A8,$B0,$A8,$30,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

	.ORG	$FFFA
	dw	Start	; NMI
	dw	Start	; RESET
	dw	Start	; IRQ

