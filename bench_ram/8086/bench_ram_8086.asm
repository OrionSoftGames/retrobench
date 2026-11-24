;<----------------------------->
; RAM Benchmark for 8086
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	equ	7000
BENCHMARK_CRC8_RESULT	equ	0x47

	push	dx	; Save CRC8 init
	cld

	; Generate_CRC8_Table
	xor	bx,bx
.loop8:	mov	al,bl			; crc
	mov	cx,8			; 8 bits
.bloop:	add	al,al			; crc << 1
	jnc	.noC
	xor	al,0x9B			; CDMA2000
.noC:	loop	.bloop
	mov	[CRC8_Table+bx],al
	inc	bl
	jnz	.loop8

	; Generate Random Numbers
	mov	dx,0x1337		; randseed
	mov	di,RandomTable
	mov	cx,BENCHMARK_ITERATIONS/2
.randloop:
	add	dx,dx			; rand
	jnc	.done
	xor	dl,0xAF
.done:	mov	[di],dx
	inc	di
	inc	di
	loop	.randloop

	; Shell Sort
	; bp = gap, si = i, di = j, bx = j-gap, dl = temp, al = arr[j-gap]
	mov	bp,BENCHMARK_ITERATIONS
SortLoop:
	shr	bp,1			; gap = n / 2
	jz	SortDone
	mov	si,bp			; i = gap
.forLoop:
	cmp	si,BENCHMARK_ITERATIONS	; i < n
	jae	SortLoop
	mov	dl,[RandomTable+si]	; temp = arr[i]
	mov	di,si			; j = i
.whileLoop:
	cmp	di,bp			; j >= gap
	jl	.out
	mov	bx,di
	sub	bx,bp			; j - gap
	mov	al,[RandomTable+bx]
	cmp	dl,al			; arr[j-gap] > temp
	jae	.out
	mov	[RandomTable+di],al	; arr[j] = arr[j-gap]
	mov	di,bx			; j -= gap
	jmp	short .whileLoop
.out:
	mov	[RandomTable+di],dl	; arr[j] = temp
	inc	si
	jmp	short .forLoop
SortDone:

	; CRC8 Verification
	pop	bx			; Restore CRC8
	xor	bh,bh
	mov	si,RandomTable
	mov	cx,BENCHMARK_ITERATIONS
.crcloop:
	lodsb
	xor	bl,al
	mov	bl,[CRC8_Table+bx]	; crc8 = CRC8_Table[crc8 ^ RandomTable[i]]
	loop	.crcloop
	mov	dl,bl

	section .bss

CRC8_Table:	resb	256
RandomTable:	resb	BENCHMARK_ITERATIONS

	section .text

