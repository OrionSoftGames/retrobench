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

;	xor	ah,ah
;	mov	al,4	; CGA 320x200x4
;	int	10h

	; 2 bits per pixels

	%endif

;------------------------------->

	xor	ah,ah
	int	0x1A		; Get Ticks
	push	dx

Bench:
	mov	cl,0xFF		; CRC8 init

	%include	"../../bench_cpu/8086/bench_cpu_8086.asm"
;	%include	"../../bench_ram/8086/bench_ram_8086.asm"

	%ifdef	BENCHMARK_IS_GRAPHIC
	; TODO: Esc key to exit in graphic mode
	%endif

	pop	bx		; Old Ticks
	push	cx		; Save CRC8

	xor	ah,ah
	int	0x1A		; Get Ticks
	sub	dx,bx		; Compute time interval

	mov	ax,dx
	mov	bx,10000
	mul	bx		; DX:AX = time interval * 1000ms * 10
	mov	bx,182		; Int 1Ah count at about 18,2Hz
	div	bx		; AX = Result in msec

	; Convert time result in ASCII
	mov	di,txt_timeEnd
	mov	bx,10
	xor	cx,cx	; counter
pd_div:
	xor	dx,dx	; DX:AX / 10
	div	bx	; AX = quotient, DX = reste (0..9)
	push	dx	; push for later display
	inc	cx
	test	ax,ax
	jnz	pd_div
pd_out:
	pop	dx
	add	dl,'0'
	push	ax
	mov	al,dl
	stosb
	pop	ax
	loop	pd_out

	mov	dx,txt_good
	pop	cx		; Restore CRC8
	cmp	cl,BENCHMARK_CRC8_RESULT
	je	crc_is_ok
	mov	dx,txt_error
crc_is_ok:
	mov	ah,9
	int	0x21

	mov	dx,txt_time
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
txt_time:	db	"Time: "
txt_timeEnd:	db	"     ms",10,13,'$'

