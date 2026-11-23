;<---------------------------------------->
; Benchmark template for Megadrive/Genesis
;                      by OrionSoft [2026]
;<---------------------------------------->

	.text

BENCHMARK_IS_GRAPHIC	equ	0

VDP_DATA	equ	$C00000
VDP_CTRL	equ	$C00004

VRAM_TILE	equ	$0000	; 48k
VRAM_LAYER_B	equ	$C000	; 4k		; 64x32
VRAM_WINDOW	equ	$D000	; 2k
VRAM_HSCROLL	equ	$D800	; 1k
VRAM_SPRITE	equ	$DC00	; 1k
VRAM_LAYER_A	equ	$E000	; 8k		; (64x64 Use Front Layer Only)

MAP_WIDTH_32	equ	$00
MAP_WIDTH_64	equ	$01
MAP_WIDTH_128	equ	$03

MAP_HEIGHT_32	equ	$00
MAP_HEIGHT_64	equ	$10
MAP_HEIGHT_128	equ	$30

;***********************
; MegaDrive Cart Header
;***********************

	dc.l	$01000000	; Stack
	dc.l	Start
	dc.l	Error,Error,Error,Error,Error,Error,Error,Error,Error,Error,Error
	dc.l	Error,Error,Error,Error,Error,Error,Error,Error,Error,Error,Error
	dc.l	Error,INT,EXTINT,INT,HINT,INT,VINT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT
	dc.l	INT,INT,INT,INT,INT,INT,INT,INT

	dc.b	"SEGA MEGA DRIVE "	; Console Name
	dc.b	"OrionSoft - 2026"	; Copyright
	dc.b	"Benchmark - OrionSoft 2026                      "	; Game Name
	dc.b	"Benchmark - OrionSoft 2026                      "	; Overseas Name
	dc.b	"GM xxxxxxxx-42"	; Serial
	dc.w	$0000			; Checksum
	dc.b	"J               "	; IO Support (Joypad)
	dc.l	$00000000	; Rom Start
	dc.l	$003FFFFF	; Rom End
	dc.l	$00FF0000	; RAM Start
	dc.l	$00FFFFFF	; RAM End
	dc.b	"            "	; No SRAM
	dc.b	"            "	; Modem
	dc.b	"Benchmark - OrionSoft 2026              "	; Note
	dc.b	"JUE             "	; Country Japan, USA, Europe

;---------------------------------------->
; Interrupts

	even
VINT:
	addq.w	#1,TimeRef
HINT:
INT:
EXTINT:	rte
Error:	bra.s	Error

;---------------------------------------->
; Boot

Start:
	move	#$2700,sr

	tst.l	$A10008
	bne.s	SkipJoyDetect
	tst.w	$A1000C
SkipJoyDetect:
	bne.s	SkipSetup

	; Sega Security Code (SEGA)
	move.b	$A10001,d0
	andi.b	#$0F,d0
	beq.s	WrongVersion
	move.l	#'SEGA',$A14000
WrongVersion:

SkipSetup:
	; Clear RAM
	lea	$ff0000,a0
	moveq	#0,d0
	move.w	#((1<<16)/(4*4))-1,d1	; 64k of RAM
.ClearRam:
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	move.l	d0,(a0)+
	dbra	d1,.ClearRam
	;----

	lea	$1000000,a7		; Stack at top of RAM
	lea	VDP_CTRL,a0

	; Init VDP registers
	lea	VDPregs,a1
	moveq	#19-1,d0
	move.w	#$8000,d1
VDPiLoop:
	move.b	(a1)+,d1	; Reg Value from Table
	move.w	d1,(a0)		; Send to VDP
	add.w	#$0100,d1	; Reg++
	dbra	d0,VDPiLoop

	lea	VDP_DATA,a1
	moveq	#0,d0

	;------------
	; Clear VRAM

	move.l	#$40000000,(a0)
	move.w	#$1FFF,d1	; 64k of VRAM
.ClearVRam:
	move.l	d0,(a1)
	move.l	d0,(a1)
	dbra	d1,.ClearVRam

	;------------
	; Clear CRAM

	move.l	#$C0000000,(a0)
	moveq	#(4*16)-1,d1	; 4*16 colors
.ClearCRam:
	move.w	d0,(a1)
	dbra	d1,.ClearCRam
	;----

	;---------------
	; Clear VScroll

	move.l	#$40000010,(a0)
	moveq	#40-1,d1
.ClearVSRam:
	move.w	d0,(a1)
	dbra	d1,.ClearVSRam
	;----

	lea	$A10009,a0	; Joypad 1&2 Init
	moveq	#$40,d0
	move.b	d0,(a0)
	move.b	d0,2(a0)

	move	#$2000,sr

;---------------------------------------->
; Main Benchmark Code

	; Unpack 1bpp Font to 4bpp in VRAM
	moveq	#0,d0
	bsr	SetVramAddress
	lea	VDP_DATA,a2

	lea	Font8_1b,a0
	lea	FontEnd,a1
UnpackFont:
	moveq	#0,d1
	moveq	#7-1,d2
	move.b	(a0)+,d0	; One tile line @1bpp (8 pixels)
UpkBit:	add.b	d0,d0		; Unpack each bit to 4bpp
	roxl.l	#4,d1
	dbra	d2,UpkBit
	add.b	d0,d0		; Last bit
	roxl.l	#1,d1
	move.l	d1,(a2)		; Send pixels to VRAM
	cmpa.l	a0,a1
	bne.s	UnpackFont

	moveq	#0,d0
	move.w	d0,PrintY
	moveq	#1,d1
	move.w	#$EEE,d2	; White Font
	bsr	SetColor

	lea	txt_title,a0
	bsr	Print

	if	BENCHMARK_IS_GRAPHIC
	lea	txt_benchmode,a0
	else
	lea	txt_presskey,a0
	endif
	bsr	Print
	bsr	WaitKey

	lea	txt_start,a0
	bsr	Print

	if	BENCHMARK_IS_GRAPHIC

BlankScreen:	; TODO

	endif

;------------------------------->

Bench:
	bsr	WaitVBL
	clr.w	TimeRef

	move.w	#$FF,d7		; CRC8 init

;	include	"../../bench_cpu/68k/bench_cpu_68k.asm"
	include	"../../bench_ram/68k/bench_ram_68k.asm"

	if	BENCHMARK_IS_GRAPHIC

	bsr	WaitVBL
	bsr	ReadJoypad1

	else

	endif

	; Copy text to ram so we can modify it
	lea	txt_time,a0
	lea	txtrtime,a1
	moveq	#txt_timeEnd-txt_time,d0
	bsr	Memcpy

	; Convert time to string for display
	lea	txtrtimeEnd,a0
	move.w	TimeRef,d0
	mulu	#1000,d0
	move.w	VDP_CTRL,d1	; Check PAL mode Flag
	andi.w	#1,d1
	bne.s	IsPAL
	divu	#60,d0		; no PAL = 60 FPS
	bra.s	NotPAL
IsPAL:	divu	#50,d0		; PAL = 50 FPS
NotPAL:	ext.l	d0
TimeToStr:
	divu.w	#10,d0
	swap	d0
	addi.b	#'0',d0
	move.b	d0,-(a0)
	clr.w	d0
	swap	d0
	tst.w	d0
	bne.s	TimeToStr

	lea	txt_good,a0
	cmpi.b	#BENCHMARK_CRC8_RESULT,d7
	beq.s	crc_is_ok
	lea	txt_error,a0
crc_is_ok:
	bsr	Print
	lea	txtrtime,a0
	bsr	Print
	bsr	WaitKey
EndLoop:
	bra.s	EndLoop

	if	BENCHMARK_IS_GRAPHIC

PutPixel:	; TODO

	endif

;---------------------------------------->
; Utils

WaitKey:
	bsr	WaitVBL
	bsr	ReadJoypad1
	tst.b	d0
	beq.s	WaitKey
	rts

ReadJoypad1:
	lea	$A10003,a0
	clr.b	(a0)
	nop
	nop
	nop
	move.b	(a0),d0
	move.b	#$40,(a0)
	andi.b	#$30,d0
	lsl.b	#2,d0
	move.b	(a0),d1
	andi.b	#$3F,d1
	or.b	d1,d0
	not.b	d0
	rts

WaitVBL:
	lea	VDP_CTRL,a0
.Activ:	move.w	(a0),d0		; Wait for End of VBLank
	andi.w	#8,d0
	bne.s	.Activ
.Blank:	move.w	(a0),d0		; Wait for Start of VBlank
	andi.w	#8,d0
	beq.s	.Blank
	rts

; d0 = Palette Index (0-3)
; d1 = Inner Palette Index (0-15)
; d2 = Color

SetColor:
	lsl.w	#4,d0	; 16=<<4
	add.w	d1,d0
	add.w	d0,d0	; *word
	bsr	SetCramAddress
	lea	VDP_DATA,a1
	move.w	d2,(a1)
	rts

; A0-->A1 , D0 length
Memcpy:
	tst.l	d0
	beq.s	.out
.loop:	move.b	(a0)+,(a1)+
	subq.l	#1,d0
	bne.s	.loop
.out:	rts

; Print a Text at X/Y on Map A
; d0 = X
; d1 = Y
; a0 = Text

Print:
	moveq	#0,d0
	move.w	PrintY,d1
	addq.w	#1,d1
	move.w	d1,PrintY
	bsr	PrintSetVram
	moveq	#0,d0
.loop:	move.b	(a0)+,d0
	beq.s	.done
	subi.b	#' ',d0
	move.w	d0,(a1)
	bra.s	.loop
.done:	rts

PrintSetVram:
	lsl.w	#6,d1		; Y*64 (MAP is 64x64)
	add.w	d1,d0		; +X
	add.w	d0,d0		; *word
	addi.w	#VRAM_LAYER_A,d0
	bsr	SetVramAddress
	lea	VDP_DATA,a1
	rts

SetCramAddress:	; d0 = Address
	movem.l	d1-d2,-(a7)
	move.l	#$C0000000,d1
	bra.s	iSetVDPAddress

SetVramAddress:	; d0 = Address
	movem.l	d1-d2,-(a7)
	move.l	#$40000000,d1

iSetVDPAddress:
	move.w	d0,d2		; Address
	and.w	#$3FFF,d2	; Lower Bits
	swap	d2
	move.w	d0,d2		; Address
	rol.w	#2,d2		; Upper Bits
	andi.w	#3,d2
	or.l	d1,d2		; Add VDP Command
	move.l	d2,VDP_CTRL
	movem.l	(a7)+,d1-d2
	rts

;---------------------------------------->

txt_title:	dc.b	"Retro RAM Benchmark by OrionSoft 2026",0
	if	BENCHMARK_IS_GRAPHIC
txt_benchmode:	dc.b	"Press B for bench or C for graphic mode",0
	else
txt_presskey:	dc.b	"Press Start button to begin...",0
	endif
txt_start:	dc.b	"Benchmark result:",0
txt_good:	dc.b	"Validated!",0
txt_error:	dc.b	"Error!",0
txt_time:	dc.b	"Time:      ms",0
txt_timeEnd:

VDPregs:
	dc.b	$04,$74,$38,$34,$06,$6E,$00,$00,$00,$00,$00,$00,$81,$36,$00,$02,$01,$00,$FF	; 48k Tile Vram, Map 64x32 max
	even
Font8_1b:	; 1 bits Font 8x8
	dc.b	$00,$00,$00,$00,$00,$00,$00,$00
	dc.b	$30,$78,$78,$30,$30,$00,$30,$00
	dc.b	$6C,$6C,$6C,$00,$00,$00,$00,$00
	dc.b	$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00
	dc.b	$30,$7C,$C0,$78,$0C,$F8,$30,$00
	dc.b	$00,$C6,$CC,$18,$30,$66,$C6,$00
	dc.b	$38,$6C,$38,$76,$DC,$CC,$76,$00
	dc.b	$60,$60,$C0,$00,$00,$00,$00,$00
	dc.b	$18,$30,$60,$60,$60,$30,$18,$00
	dc.b	$60,$30,$18,$18,$18,$30,$60,$00
	dc.b	$00,$66,$3C,$FF,$3C,$66,$00,$00
	dc.b	$00,$30,$30,$FC,$30,$30,$00,$00
	dc.b	$00,$00,$00,$00,$00,$70,$30,$60
	dc.b	$00,$00,$00,$FC,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$30,$30,$00
	dc.b	$06,$0C,$18,$30,$60,$C0,$80,$00
	dc.b	$78,$CC,$DC,$FC,$EC,$CC,$78,$00
	dc.b	$30,$F0,$30,$30,$30,$30,$FC,$00
	dc.b	$78,$CC,$0C,$38,$60,$CC,$FC,$00
	dc.b	$78,$CC,$0C,$38,$0C,$CC,$78,$00
	dc.b	$1C,$3C,$6C,$CC,$FE,$0C,$0C,$00
	dc.b	$FC,$C0,$F8,$0C,$0C,$CC,$78,$00
	dc.b	$38,$60,$C0,$F8,$CC,$CC,$78,$00
	dc.b	$FC,$CC,$0C,$18,$30,$60,$60,$00
	dc.b	$78,$CC,$CC,$78,$CC,$CC,$78,$00
	dc.b	$78,$CC,$CC,$7C,$0C,$18,$70,$00
	dc.b	$00,$00,$30,$30,$00,$30,$30,$00
	dc.b	$00,$00,$30,$30,$00,$70,$30,$60
	dc.b	$18,$30,$60,$C0,$60,$30,$18,$00
	dc.b	$00,$00,$FC,$00,$FC,$00,$00,$00
	dc.b	$60,$30,$18,$0C,$18,$30,$60,$00
	dc.b	$78,$CC,$0C,$18,$30,$00,$30,$00
	dc.b	$7C,$C6,$DE,$DE,$DE,$C0,$78,$00
	dc.b	$30,$78,$CC,$CC,$FC,$CC,$CC,$00
	dc.b	$FC,$66,$66,$7C,$66,$66,$FC,$00
	dc.b	$3C,$66,$C0,$C0,$C0,$66,$3C,$00
	dc.b	$FC,$6C,$66,$66,$66,$6C,$FC,$00
	dc.b	$FE,$62,$68,$78,$68,$62,$FE,$00
	dc.b	$FE,$62,$68,$78,$68,$60,$F0,$00
	dc.b	$3C,$66,$C0,$C0,$CE,$66,$3E,$00
	dc.b	$CC,$CC,$CC,$FC,$CC,$CC,$CC,$00
	dc.b	$78,$30,$30,$30,$30,$30,$78,$00
	dc.b	$1E,$0C,$0C,$0C,$CC,$CC,$78,$00
	dc.b	$E6,$66,$6C,$78,$6C,$66,$E6,$00
	dc.b	$F0,$60,$60,$60,$62,$66,$FE,$00
	dc.b	$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00
	dc.b	$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00
	dc.b	$38,$6C,$C6,$C6,$C6,$6C,$38,$00
	dc.b	$FC,$66,$66,$7C,$60,$60,$F0,$00
	dc.b	$78,$CC,$CC,$CC,$DC,$78,$1C,$00
	dc.b	$FC,$66,$66,$7C,$78,$6C,$E6,$00
	dc.b	$78,$CC,$E0,$38,$1C,$CC,$78,$00
	dc.b	$FC,$B4,$30,$30,$30,$30,$78,$00
	dc.b	$CC,$CC,$CC,$CC,$CC,$CC,$FC,$00
	dc.b	$CC,$CC,$CC,$CC,$CC,$78,$30,$00
	dc.b	$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00
	dc.b	$C6,$C6,$6C,$38,$6C,$C6,$C6,$00
	dc.b	$CC,$CC,$CC,$78,$30,$30,$78,$00
	dc.b	$FE,$CC,$98,$30,$62,$C6,$FE,$00
	dc.b	$78,$60,$60,$60,$60,$60,$78,$00
	dc.b	$C0,$60,$30,$18,$0C,$06,$02,$00
	dc.b	$78,$18,$18,$18,$18,$18,$78,$00
	dc.b	$10,$38,$6C,$C6,$00,$00,$00,$00
	dc.b	$00,$00,$00,$00,$00,$00,$00,$FF
	dc.b	$30,$30,$18,$00,$00,$00,$00,$00
	dc.b	$00,$00,$78,$0C,$7C,$CC,$76,$00
	dc.b	$E0,$60,$7C,$66,$66,$66,$BC,$00
	dc.b	$00,$00,$78,$CC,$C0,$CC,$78,$00
	dc.b	$1C,$0C,$0C,$7C,$CC,$CC,$76,$00
	dc.b	$00,$00,$78,$CC,$FC,$C0,$78,$00
	dc.b	$38,$6C,$60,$F0,$60,$60,$F0,$00
	dc.b	$00,$00,$76,$CC,$CC,$7C,$0C,$F8
	dc.b	$E0,$60,$6C,$76,$66,$66,$E6,$00
	dc.b	$30,$00,$70,$30,$30,$30,$78,$00
	dc.b	$18,$00,$78,$18,$18,$18,$D8,$70
	dc.b	$E0,$60,$66,$6C,$78,$6C,$E6,$00
	dc.b	$70,$30,$30,$30,$30,$30,$78,$00
	dc.b	$00,$00,$EC,$FE,$D6,$C6,$C6,$00
	dc.b	$00,$00,$F8,$CC,$CC,$CC,$CC,$00
	dc.b	$00,$00,$78,$CC,$CC,$CC,$78,$00
	dc.b	$00,$00,$DC,$66,$66,$7C,$60,$F0
	dc.b	$00,$00,$76,$CC,$CC,$7C,$0C,$1E
	dc.b	$00,$00,$D8,$6C,$6C,$60,$F0,$00
	dc.b	$00,$00,$7C,$C0,$78,$0C,$F8,$00
	dc.b	$10,$30,$7C,$30,$30,$34,$18,$00
	dc.b	$00,$00,$CC,$CC,$CC,$CC,$76,$00
	dc.b	$00,$00,$CC,$CC,$CC,$78,$30,$00
	dc.b	$00,$00,$C6,$C6,$D6,$FE,$6C,$00
	dc.b	$00,$00,$C6,$6C,$38,$6C,$C6,$00
	dc.b	$00,$00,$CC,$CC,$CC,$7C,$0C,$F8
	dc.b	$00,$00,$FC,$98,$30,$64,$FC,$00
	dc.b	$1C,$30,$30,$E0,$30,$30,$1C,$00
	dc.b	$18,$18,$18,$00,$18,$18,$18,$00
	dc.b	$E0,$30,$30,$1C,$30,$30,$E0,$00
	dc.b	$76,$DC,$00,$00,$00,$00,$00,$00
	dc.b	$10,$38,$6C,$C6,$C6,$C6,$FE,$00
FontEnd:

;---------------------------------------->
; RAM
	.bss
PrintY:		ds.w	1
TimeRef:	ds.w	1
txtrtime:	ds.b	11
txtrtimeEnd:	ds.b	3

