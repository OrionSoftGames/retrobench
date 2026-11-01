;<----------------------------->
; Benchmark template for PC/DOS
;           by OrionSoft [2026]
;<----------------------------->

	org	100h

;%define	BENCHMARK_IS_GRAPHIC

	mov	dx,txt_title
	mov	ah,9
	int	0x21

	%ifdef	BENCHMARK_IS_GRAPHIC
	mov	dx,txt_benchmode
	%else
	mov	dx,txt_presskey
	%endif
	mov	ah,9
	int	0x21
	mov	ah,8	; Read char in AL
	int	0x21

	mov	dx,txt_start
	mov	ah,9
	int	0x21

	%ifdef	BENCHMARK_IS_GRAPHIC
	; TODO
	; Set graphic mode
	; Clear screen
	%endif

;------------------------------->

Bench:
	cli			; Disable interrupts

	mov	cl,0xFF		; CRC8 init

	%include	"../../bench_cpu/8086/bench_cpu_8086.asm"
;	%include	"../../bench_ram/8086/bench_ram_8086.asm"

	%ifdef	BENCHMARK_IS_GRAPHIC
	; TODO: Esc key to exit in graphic mode
	%endif

	sti			; Restore interrupts

	mov	dx,txt_good
	cmp	cl,BENCHMARK_CRC8_RESULT
	je	crc_is_ok
	mov	dx,txt_error
crc_is_ok:
	mov	ah,9
	int	0x21
	mov	ah,8	; Read char
	int	0x21

	mov	ax,0x4C
	int	0x21

	%ifdef	BENCHMARK_IS_GRAPHIC
PutPixel:
	; TODO
	%endif

;------------------------------->

txt_title:	db	"Retro CPU Benchmark by OrionSoft 2026",10,13,'$'
	%ifdef	BENCHMARK_IS_GRAPHIC
txt_benchmode:	db	"Press B for bench or G for graphic mode",10,13,'$'
	%else
txt_presskey:	db	"Press Return to start...",10,13,'$'
	%endif
txt_start:	db	"Benchmark result: ",'$'
txt_good:	db	"validated!",10,13,'$'
txt_error:	db	"error!",10,13,'$'
txt_time:	db	"Time: ",0

