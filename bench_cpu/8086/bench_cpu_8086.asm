;<----------------------------->
; CPU Benchmark for 8086
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	equ	702
BENCHMARK_CRC8_RESULT	equ	0xB1

	mov	ax,1	; m
.mainloop:
	mov	bx,ax	; n = m;
.next:	cmp	bx,1	; while (n != 1)
	je	.done

	xor	dl,bl	; crc8 ^= n & 0xFF;
	mov	cl,8	; bit counter
.blop1:	add	dl,dl	; crc << 1
	jnc	.noC1
	xor	dl,0x9B	; CDMA2000
.noC1:	dec	cl	; bit--
	jne	.blop1

	xor	dl,bh	; crc8 ^= n >> 8;
	mov	cl,8	; bit counter
.blop2:	add	dl,dl	; crc << 1
	jnc	.noC2
	xor	dl,0x9B	; CDMA2000
.noC2:	dec	cl	; bit--
	jne	.blop2

	shr	bx,1	; n >> 1, C = bit 0
	jnc	.next
	mov	cx,bx	; 3*n+1
	add	bx,bx
	add	bx,cx
	add	bx,2
	add	bx,bx
	jmp	.next

.done:	inc	ax	; for (m = 1; m <= ITERATIONS; m++)
	cmp	ax,BENCHMARK_ITERATIONS
	jle	.mainloop

