;<--------------------------------------------->
; Benchmark template for PC Engine / TurboGrafx
;                           by OrionSoft [2026]
;<--------------------------------------------->

_xres	.equ 320

	.zp
vblcnt:	ds	1
joypad:	ds	1
PrintY:	ds	1
tmpw1:	ds	2
tmpw2:	ds	2
tmp:	ds	1

crc8:	ds	1

ZP_BASE	= crc8+1

	.bss

txtrtime:	ds	14
rambase:
RAM_BASE = rambase

	.code
	.bank	0

;--------------------------------
;- Interrupt vectors

	.org	$FFF6

	.dw	_irq2
	.dw	_irq1
	.dw	_timer
	.dw	_nmi
	.dw	_reset

;--------------------------------

VramWriteAdrs	.equ	0
VramReadAdrs	.equ	1
VramRead	.equ	2
VramWrite	.equ	2
VControlReg	.equ	5
VScanline	.equ	6
VScrollX	.equ	7
VScrollY	.equ	8
VBGSize		.equ	9
VHSR		.equ	$A
VHDR		.equ	$B
VVPR		.equ	$C
VVDW		.equ	$D
VVCR		.equ	$E
VDMAControlReg	.equ	$F
VSATB		.equ	$13

VDCStatusReg	.equ	$0000
VDCWriteLow	.equ	VDCStatusReg+2
VDCWriteHigh	.equ	VDCStatusReg+3

VCEReg		.equ	$0400
VCEPalLow	.equ	VCEReg+2
VCEPalHigh	.equ	VCEReg+3
VCEColorLow	.equ	VCEReg+4
VCEColorHigh	.equ	VCEReg+5

JoyPadReg	.equ	$1000

SELLOW		.equ	0
SELHIGH		.equ	1
CLRLOW		.equ	0
CLRHIGH		.equ	2

;--------------------------------

VReg	.macro
	st0	#\1
	.endm

VPort	.macro
	st1	#LOW(\1)
	st2	#HIGH(\1)
	.endm

addw	.macro
	 clc
	 lda	LOW_BYTE \2
	 adc	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \2
	 adc	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

lsrw	.macro			; logical shift-right word-sized
	 lsr	\1+1		; value (at stated memory
	 ror	\1		; location)
	.endm

stw	.macro
	 lda	LOW_BYTE \1
	 sta	LOW_BYTE \2
	 lda	HIGH_BYTE \1
	 sta	HIGH_BYTE \2
	.endm

HSR	.macro
	 .if (\1 <= 272)
	  ; low res
	  st1	#$02
	  st2	#(18 - (((\1 / 8) - 1) / 2))
	 .else
	  ; high res
	  st1	#$03
	  st2	#(24 - (((\1 / 8) - 1) / 2))
	 .endif
	.endm

HDR	.macro
	 st1	#((\1 / 8) - 1)
	 .if (\1 <= 272)
	  ; low res
	  st2	#(38 - ((18 - (((\1 / 8) - 1) / 2)) + (\1 / 8)))
	 .else
	  ; high res
	  st2	#(54 - ((24 - (((\1 / 8) - 1) / 2)) + (\1 / 8)))
	 .endif
	.endm

;--------------------------------
;- Boot / Init

	.org	$E000
_reset:
	sei			; Disable interrupts
	csh			; Select 7.16 MHz clock
	cld			; Clear decimal flag
	ldx	#$FF		; Initialize stack
	txs
	txa			; Map I/O @ $0000
	tam	#0
	lda	#$F8		; Map Main RAM @ $2000
	tam	#1

	lda	#1
	tam	#2
	inc	A
	tam	#3
	inc	A
	tam	#4
	inc	A
	tam	#5
	inc	A
	tam	#6

	stz	$2000		; Clear RAM
	tii	$2000,$2001,$1FFF

	stz	$0C01		; TimerControl: Init timer

; Configure VDC Port

	VReg	VControlReg
	VPort	0		; BLACK_OUT

	VReg	VScanline
	VPort	0

	VReg	VScrollX
	VPort	0

	VReg	VScrollY
	VPort	0

	VReg	VBGSize
	VPort	%0010000	; BG_64x32

	VReg	VHSR
	HSR	_xres

	VReg	VHDR
	HDR	_xres

	VReg	VVPR
	VPort	$1702

	VReg	VVDW
	VPort	$00DF

	VReg	VVCR
	VPort	$000C

	VReg	VDMAControlReg
	VPort	$0010

	VReg	VSATB
	VPort	$7F00

; Set pixel clock frequency

	.if (_xres <= 272)
	 stz	VCEReg
	.else
	 lda	#1
	 sta	VCEReg
	.endif

	stz	VCEPalLow	; BG Palette
	stz	VCEPalHigh

	stz	VCEColorLow	; Black BG
	stz	VCEColorHigh
	lda	#$80		; Font Color
	sta	VCEColorLow
	lda	#$01
	sta	VCEColorHigh

	stz	VCEPalLow	; Sprite Palette
	lda	#1
	sta	VCEPalHigh
	stz	VCEColorLow	; Black Border
	stz	VCEColorHigh

	; Clear Screen
	VReg	VramWriteAdrs
	VPort	$0000		; BAT
	VReg	VramWrite
	ldy	#32
ClrY:	ldx	#64
ClrX:	VPort	$800/16		; Blank space from first tile of Font
	dex
	bne	ClrX
	dey
	bne	ClrY

	; Setup Font Ptr
	lda	#LOW(Font8_1b)
	sta	<tmpw1
	lda	#HIGH(Font8_1b)
	sta	<tmpw1+1

	; Unpack 1bpp Font in VRAM
	VReg	VramWriteAdrs
	VPort	$800
	VReg	VramWrite
	ldy	#0
UpkFnt:	ldx	#8
NxtFnt:	lda	[<tmpw1],y	; Load 1bpp font
	sta	VDCWriteLow	; Plane 0: Font 1bpp
	stz	VDCWriteHigh	; Plane 1: zero
	inc	<tmpw1		; font ptr++
	bne	PtrNxt
	inc	<tmpw1+1
PtrNxt:	dex
	bne	NxtFnt
	ldx	#8
SkpFnt:	stz	VDCWriteLow	; Skip plane 2/3
	stz	VDCWriteHigh
	dex
	bne	SkpFnt
	lda	<tmpw1
	cmp	#LOW(FontEnd)	; End of Data ?
	bne	UpkFnt
	lda	<tmpw1+1
	cmp	#HIGH(FontEnd)
	bne	UpkFnt

	; Enable interrupts
	lda	#1
	sta	$1402		; IRQ1
	stz	$1403		; IRQ_Timer
	cli

	VReg	VControlReg
	VPort	%10001000	; BG_ON | IRQ_ON

	stz	<PrintY

;--------------------------------
; Benchmark

	ldx	#LOW(txt_title)
	ldy	#HIGH(txt_title)
	jsr	Print
	ldx	#LOW(txt_presskey)
	ldy	#HIGH(txt_presskey)
	jsr	Print
	jsr	WaitKey

	ldx	#LOW(txt_start)
	ldy	#HIGH(txt_start)
	jsr	Print

;------------------------------->

Bench:
	jsr	WaitVBL
	stz	<vblcnt

	lda	#$FF		; Init CRC8
	sta	<crc8

	.include	"../../bench_cpu/6502/bench_cpu_6502.asm"
;	.include	"../../bench_ram/6502/bench_ram_6502.asm"

	sei
	; Convert time to string for display
	tii	txt_time,txtrtime,txt_timeEnd-txt_time
	jsr	vbl_to_ms
	cli

	ldx	#LOW(txt_good)
	ldy	#HIGH(txt_good)
	lda	<crc8
	cmp	#BENCHMARK_CRC8_RESULT
	beq	crcValid
	ldx	#LOW(txt_error)
	ldy	#HIGH(txt_error)
crcValid:
	bsr	Print

	ldx	#LOW(txtrtime)
	ldy	#HIGH(txtrtime)
	jsr	Print
	jsr	WaitKey
EndLoop:
	jmp	EndLoop

;--------------------------------
; Subroutines

Print:	; x/y = TextPtr
	stx	<tmpw1
	sty	<tmpw1+1

	lda	<PrintY
	sta	<tmpw2+1
	stz	<tmpw2
	lsrw	<tmpw2		; Y*64 BG size
	lsrw	<tmpw2		; <<6 = <<8 >>2

	VReg	VramWriteAdrs
	stw	<tmpw2,VDCWriteLow

	VReg	VramWrite
	ldy	#0
.wsloop:
	lda	[<tmpw1],y
	beq	.getout
	clc
	adc	#($800/16)-' '	; Tile Base minus Space (first char in tiles)
	sta	VDCWriteLow
	stz	VDCWriteHigh
	iny
	jmp	.wsloop
.getout:
	inc	<PrintY		; Next line
	rts

;--------------------------------

WaitKey:
	jsr	WaitVBL
	jsr	ReadJoypad
	lda	<joypad
	beq	WaitKey
	rts

WaitVBL:
	stz	<vblcnt
.wait:	lda	<vblcnt
	beq	.wait
	rts

;--------------------------------

ReadJoypad:
	lda	#CLRLOW | SELHIGH	; Reset to Joypad 1
	sta	JoyPadReg
	lda	#CLRHIGH | SELHIGH
	sta	JoyPadReg

	pha	; Joypad Wait
	nop
	nop
	pla

	lda	#CLRLOW | SELHIGH
	sta	JoyPadReg

	pha	; Joypad Wait
	nop
	nop
	pla

	lda	JoyPadReg	; Read Joypad (Arrows)
	asl	a		; in the upper part of the accumulator
	asl	a
	asl	a
	asl	a
	sta	<joypad

;	lda	#CLRLOW | SELLOW
	stz	JoyPadReg

	pha	; Joypad Wait
	nop
	nop
	pla

	lda	JoyPadReg	; Read Joypad (Buttons)
	and	#$0F		; in the low part of the accumulator
	ora	<joypad
	eor	#$FF
	sta	<joypad		; Now Joypad contain: <>v^RS21

	rts

;--------------------------------

vbl_to_ms:
        ; ---- tmpw1 = vblcount * 50 (multiplication par décalages/additions)
        lda     <vblcnt
        sta     <tmp
        stz     <tmpw1
        stz     <tmpw1+1
        lda     #50
        sta     <tmpw2
        stz     <tmpw2+1
        ldx     #8
.mul:
        lsr     <tmp
        bcc     .noadd
        clc
        lda     <tmpw1
        adc     <tmpw2
        sta     <tmpw1
        lda     <tmpw1+1
        adc     <tmpw2+1
        sta     <tmpw1+1
.noadd:
        asl     <tmpw2
        rol     <tmpw2+1
        dex
        bne     .mul

        ; ---- tmpw1 = tmpw1 / 3 (division restoring 16 bits, reste dans A)
        ldx     #16
        cla
.div:
        asl     <tmpw1
        rol     <tmpw1+1
        rol     A
        cmp     #3
        bcc     .nosub
        sbc     #3              ; carry = 1 après le cmp
        inc     <tmpw1           ; bit de quotient (bit 0 libre après le asl)
.nosub:
        dex
        bne     .div

        ; ---- conversion tmpw1 -> 5 chiffres ASCII dans txtrtime
        ldx     #0
.digit:
        lda     #'0'
        sta     txtrtime+6,x
.sub:
        sec
        lda     <tmpw1
        sbc     pow10_lo,x
        tay                     ; octet bas du résultat
        lda     <tmpw1+1
        sbc     pow10_hi,x
        bcc     .next           ; négatif : chiffre terminé
        sta     <tmpw1+1
        sty     <tmpw1
        inc     txtrtime+6,x
        bra     .sub
.next:
        inx
        cpx     #5
        bne     .digit
        rts

pow10_lo:   .db LOW(10000),LOW(1000),LOW(100),LOW(10),LOW(1)
pow10_hi:   .db HIGH(10000),HIGH(1000),HIGH(100),HIGH(10),HIGH(1)

;--------------------------------
; Interrupts

_timer:	stz	$0C01	; TimerControl
	rti
_irq1:	pha
	lda	VDCStatusReg	; IRQ1 Ack
	and	#$20		; VBLANK ?
	beq	irqend
	inc	<vblcnt
irqend:	pla
_nmi:
_irq2:	rti

;********************************

	.data
	.bank	1
	.org	$4000

txt_title:	db	"Retro CPU Benchmark by OrionSoft 2026",0
txt_presskey:	db	"Press a button to begin...",0
txt_start:	db	"Benchmark result:",0
txt_good:	db	"Validated!",0
txt_error:	db	"Error!",0
txt_time:	db	"Time:      ms",0
txt_timeEnd:

Font8_1b:	; 1 bits Font 8x8
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$30,$78,$78,$30,$30,$00,$30,$00
	db	$6C,$6C,$6C,$00,$00,$00,$00,$00
	db	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00
	db	$30,$7C,$C0,$78,$0C,$F8,$30,$00
	db	$00,$C6,$CC,$18,$30,$66,$C6,$00
	db	$38,$6C,$38,$76,$DC,$CC,$76,$00
	db	$60,$60,$C0,$00,$00,$00,$00,$00
	db	$18,$30,$60,$60,$60,$30,$18,$00
	db	$60,$30,$18,$18,$18,$30,$60,$00
	db	$00,$66,$3C,$FF,$3C,$66,$00,$00
	db	$00,$30,$30,$FC,$30,$30,$00,$00
	db	$00,$00,$00,$00,$00,$70,$30,$60
	db	$00,$00,$00,$FC,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$30,$30,$00
	db	$06,$0C,$18,$30,$60,$C0,$80,$00
	db	$78,$CC,$DC,$FC,$EC,$CC,$78,$00
	db	$30,$F0,$30,$30,$30,$30,$FC,$00
	db	$78,$CC,$0C,$38,$60,$CC,$FC,$00
	db	$78,$CC,$0C,$38,$0C,$CC,$78,$00
	db	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00
	db	$FC,$C0,$F8,$0C,$0C,$CC,$78,$00
	db	$38,$60,$C0,$F8,$CC,$CC,$78,$00
	db	$FC,$CC,$0C,$18,$30,$60,$60,$00
	db	$78,$CC,$CC,$78,$CC,$CC,$78,$00
	db	$78,$CC,$CC,$7C,$0C,$18,$70,$00
	db	$00,$00,$30,$30,$00,$30,$30,$00
	db	$00,$00,$30,$30,$00,$70,$30,$60
	db	$18,$30,$60,$C0,$60,$30,$18,$00
	db	$00,$00,$FC,$00,$FC,$00,$00,$00
	db	$60,$30,$18,$0C,$18,$30,$60,$00
	db	$78,$CC,$0C,$18,$30,$00,$30,$00
	db	$7C,$C6,$DE,$DE,$DE,$C0,$78,$00
	db	$30,$78,$CC,$CC,$FC,$CC,$CC,$00
	db	$FC,$66,$66,$7C,$66,$66,$FC,$00
	db	$3C,$66,$C0,$C0,$C0,$66,$3C,$00
	db	$FC,$6C,$66,$66,$66,$6C,$FC,$00
	db	$FE,$62,$68,$78,$68,$62,$FE,$00
	db	$FE,$62,$68,$78,$68,$60,$F0,$00
	db	$3C,$66,$C0,$C0,$CE,$66,$3E,$00
	db	$CC,$CC,$CC,$FC,$CC,$CC,$CC,$00
	db	$78,$30,$30,$30,$30,$30,$78,$00
	db	$1E,$0C,$0C,$0C,$CC,$CC,$78,$00
	db	$E6,$66,$6C,$78,$6C,$66,$E6,$00
	db	$F0,$60,$60,$60,$62,$66,$FE,$00
	db	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00
	db	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00
	db	$38,$6C,$C6,$C6,$C6,$6C,$38,$00
	db	$FC,$66,$66,$7C,$60,$60,$F0,$00
	db	$78,$CC,$CC,$CC,$DC,$78,$1C,$00
	db	$FC,$66,$66,$7C,$78,$6C,$E6,$00
	db	$78,$CC,$E0,$38,$1C,$CC,$78,$00
	db	$FC,$B4,$30,$30,$30,$30,$78,$00
	db	$CC,$CC,$CC,$CC,$CC,$CC,$FC,$00
	db	$CC,$CC,$CC,$CC,$CC,$78,$30,$00
	db	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00
	db	$C6,$C6,$6C,$38,$6C,$C6,$C6,$00
	db	$CC,$CC,$CC,$78,$30,$30,$78,$00
	db	$FE,$CC,$98,$30,$62,$C6,$FE,$00
	db	$78,$60,$60,$60,$60,$60,$78,$00
	db	$C0,$60,$30,$18,$0C,$06,$02,$00
	db	$78,$18,$18,$18,$18,$18,$78,$00
	db	$10,$38,$6C,$C6,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$FF
	db	$30,$30,$18,$00,$00,$00,$00,$00
	db	$00,$00,$78,$0C,$7C,$CC,$76,$00
	db	$E0,$60,$7C,$66,$66,$66,$BC,$00
	db	$00,$00,$78,$CC,$C0,$CC,$78,$00
	db	$1C,$0C,$0C,$7C,$CC,$CC,$76,$00
	db	$00,$00,$78,$CC,$FC,$C0,$78,$00
	db	$38,$6C,$60,$F0,$60,$60,$F0,$00
	db	$00,$00,$76,$CC,$CC,$7C,$0C,$F8
	db	$E0,$60,$6C,$76,$66,$66,$E6,$00
	db	$30,$00,$70,$30,$30,$30,$78,$00
	db	$18,$00,$78,$18,$18,$18,$D8,$70
	db	$E0,$60,$66,$6C,$78,$6C,$E6,$00
	db	$70,$30,$30,$30,$30,$30,$78,$00
	db	$00,$00,$EC,$FE,$D6,$C6,$C6,$00
	db	$00,$00,$F8,$CC,$CC,$CC,$CC,$00
	db	$00,$00,$78,$CC,$CC,$CC,$78,$00
	db	$00,$00,$DC,$66,$66,$7C,$60,$F0
	db	$00,$00,$76,$CC,$CC,$7C,$0C,$1E
	db	$00,$00,$D8,$6C,$6C,$60,$F0,$00
	db	$00,$00,$7C,$C0,$78,$0C,$F8,$00
	db	$10,$30,$7C,$30,$30,$34,$18,$00
	db	$00,$00,$CC,$CC,$CC,$CC,$76,$00
	db	$00,$00,$CC,$CC,$CC,$78,$30,$00
	db	$00,$00,$C6,$C6,$D6,$FE,$6C,$00
	db	$00,$00,$C6,$6C,$38,$6C,$C6,$00
	db	$00,$00,$CC,$CC,$CC,$7C,$0C,$F8
	db	$00,$00,$FC,$98,$30,$64,$FC,$00
	db	$1C,$30,$30,$E0,$30,$30,$1C,$00
	db	$18,$18,$18,$00,$18,$18,$18,$00
	db	$E0,$30,$30,$1C,$30,$30,$E0,$00
	db	$76,$DC,$00,$00,$00,$00,$00,$00
	db	$10,$38,$6C,$C6,$C6,$C6,$FE,$00
FontEnd:

