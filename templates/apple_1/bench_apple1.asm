;<--------------------------------------->
; Benchmark template for Apple 1 / WozMon
;                     by OrionSoft [2026]
;<--------------------------------------->

PrintChar	= $FFEF
PrintHex	= $FFDC
PrintHex4	= $FFE5
BackToMonitor	= $FF1F
Reset		= $FF00

	.zp
tmpw1:	ds	2
tmpw2:	ds	2
tmp:	ds	1
crc8:	ds	1

ZP_BASE	= crc8+1

	.code
	.bank	0

;--------------------------------
;- Boot / Init

	.org	$280

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
	lda	#$FF		; Init CRC8
	sta	<crc8

;	.include	"../../bench_cpu/6502/bench_cpu_6502.asm"
	.include	"../../bench_ram/6502/bench_ram_6502.asm"

	ldx	#LOW(txt_good)
	ldy	#HIGH(txt_good)
	lda	<crc8
	cmp	#BENCHMARK_CRC8_RESULT
	beq	crcValid
	ldx	#LOW(txt_error)
	ldy	#HIGH(txt_error)
crcValid:
	jsr	Print
	jmp	BackToMonitor

;--------------------------------
; Subroutines

Print:
	stx	<tmpw1
	sty	<tmpw1+1
	ldy	#0
.loop:	lda	[<tmpw1],y
	bne	.print
	rts
.print:	ora	#$80
	jsr	PrintChar
	iny
	jmp	.loop

WaitKey:
	lda	$D011
	bpl	WaitKey
	lda	$D010
	rts

;********************************

txt_title:	db	13,"RETRO RAM BENCHMARK BY ORIONSOFT 2026",13,0
txt_presskey:	db	"PRESS A KEY TO BEGIN...",13,0
txt_start:	db	"BENCHMARK RESULT:",0
txt_good:	db	"VALIDATED!",13,0
txt_error:	db	"ERROR!",13,0

rambase:
RAM_BASE = rambase

