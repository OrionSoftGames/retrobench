;<-------------------------------------->
; Benchmark template for Atari ST/Falcon
;                    by OrionSoft [2026]
;<-------------------------------------->

	section	text

BENCHMARK_IS_GRAPHIC	equ	0

	pea.l	txt_title
	move.w	#9,-(a7)
	trap	#1
	addq.l	#6,a7

	ifne	BENCHMARK_IS_GRAPHIC
	pea.l	txt_benchmode
	else
	pea.l	txt_presskey
	endif
	move.w	#9,-(a7)	; Cconws()
	trap	#1
	move.w	#7,-(a7)	; Crawcin()
	trap	#1
	addq.l	#8,a7

	pea.l	txt_start
	move.w	#9,-(a7)
	trap	#1
	addq.l	#6,a7

	clr.l	-(a7)		; Supervisor Mode
	move.w	#$20,-(a7)
	trap	#1
	addq.l	#6,a7
	move.l	d0,old_stack

; TODO, keep TimerC custom routine for time count

	ifne	BENCHMARK_IS_GRAPHIC

	move.w	#2,-(a7)	; PhysBase();
	trap	#14
	addq.l	#2,a7
	move.l	d0,a0		; Screen Ptr

	move.l	a0,a1
	lea	32000(a0),a2
.BlankScreen:
	move.l	d7,(a1)+
	cmpa.l	a1,a2
	bne.s	.BlankScreen

	endif

;------------------------------->

Bench:
	move.w	sr,d0
	move.w	d0,-(a7)	; Save interrupts
	move.w	#$2700,sr	; Disable interrupts

	move.w	#$FF,d7		; CRC8 init

	include	"../../bench_cpu/68k/bench_cpu_68k.asm"

	ifne	BENCHMARK_IS_GRAPHIC

;	cmp.b	#$39,$FFFFFC02.w	; TODO: Space key to exit in graphic mode

	else

	endif

	move.w	(a7)+,d0	; Restore interrupts
	move.w	d0,sr

	move.l	old_stack,-(a7)	; User Mode
	move.w	#$20,-(a7)
	trap	#1
	addq.l	#6,a7

	lea	txt_good,a0
	cmpi.b	#BENCHMARK_CRC8_RESULT,d7
	beq.s	crc_is_ok
	lea	txt_error,a0
crc_is_ok:
	move.l	a0,-(a7)
	move.w	#9,-(a7)	; Cconws()
	trap	#1
	move.w	#7,-(a7)	; Crawcin()
	trap	#1
	addq.l	#8,a7

	clr.l	-(a7)		; Exit
	trap	#1

	ifne	BENCHMARK_IS_GRAPHIC

PutPixel:
	movea.l	a0,a1		; d3=X, d4=Y, a1=screen
	move.w	#$8000,d1
	move.w	d3,d0
	andi.w	#15,d0
	lsr.w	d0,d1
	move.w	d4,d0
	lsl.w	#5,d4
	lsl.w	#7,d0
	add.w	d4,d0
	adda.w	d0,a1
	lsr.w	#1,d3
	andi.w	#-8,d3
	adda.w	d3,a1
	not.w	d1
	and.w	d1,(a1)		; Green Dot (on standard TOS palette)
	and.w	d1,4(a1)
	and.w	d1,6(a1)

	endif

;------------------------------->

	section	data

txt_title:	dc.b	"Retro CPU Benchmark by OrionSoft 2026",10,13,0
	ifne	BENCHMARK_IS_GRAPHIC
txt_benchmode:	dc.b	"Press B for bench or G for graphic mode",10,13,0
	else
txt_presskey:	dc.b	"Press Return to start...",10,13,0
	endif
txt_start:	dc.b	"Benchmark result: ",0
txt_good:	dc.b	"validated!",10,13,0
txt_error:	dc.b	"error!",10,13,0
txt_time:	dc.b	"Time: ",0

;------------------------------->

	section	bss

old_stack:	ds.l	1

