;<----------------------------->
; CPU Benchmark for 8086
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	equ	702	; 16bits test CRC8 should be 0xB1
BENCHMARK_CRC8_RESULT	equ	0xB1

	mov	ax,1	; m
.mainloop:
	mov	bx,ax	; n = m;
.next:	cmp	bx,1	; while (n != 1)
	je	.done

	xor	cl,bl	; crc8 ^= n & 0xFF;
	mov	dl,8	; bit counter
.blop1:	add	cl,cl	; crc << 1
	jnc	.noC1
	xor	cl,0x9B	; CDMA2000
.noC1:	dec	dl	; bit--
	jne	.blop1

	xor	cl,bh	; crc8 ^= n >> 8;
	mov	dl,8	; bit counter
.blop2:	add	cl,cl	; crc << 1
	jnc	.noC2
	xor	cl,0x9B	; CDMA2000
.noC2:	dec	dl	; bit--
	jne	.blop2

	test	bl,1	; if ((n & 1) == 0)	// n%2
	jne	.odd
	shr	bx,1	;   n = n >> 1;		// n/2
	jmp	.next
.odd:			; else
	mov	dx,bx	;   n = n + n + n + 1;	// 3*n+1
	add	bx,bx
	inc	dx
	add	bx,dx
	jmp	.next

.done:	inc	ax	; for (m = 1; m <= ITERATIONS; m++)
	cmp	ax,BENCHMARK_ITERATIONS
	jle	.mainloop

