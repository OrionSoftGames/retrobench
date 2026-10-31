BENCHMARK_ITERATIONS	=	702
BENCHMARK_CRC8_RESULT	=	$B1

M	=	ZP_BASE
N	=	M+2
btmp	=	N+2

	lda	#1
	sta	M
	lda	#0
	sta	M+1
.mainloop:
	lda	M	; n = m;
	sta	N
	lda	M+1
	sta	N+1

.next:	lda	N+1	; while (n != 1)
	bne	.goCRC
	lda	N
	cmp	#1
	beq	.done
.goCRC:
	lda	crc8
	eor	N	; crc8 ^= n & 0xFF;
	ldx	#8	; bit
bloop1:	asl		; crc << 1
	bcc	skip1	; if (crc & 0x80)
	eor	#$9B	; crc ^= 0x9B // CDMA2000
skip1:	dex		; bit--
	bne	bloop1	; bit loop

	eor	N+1	; crc8 ^= n >> 8;
	ldx	#8	; bit
bloop2:	asl		; crc << 1
	bcc	skip2	; if (crc & 0x80)
	eor	#$9B	; crc ^= 0x9B // CDMA2000
skip2:	dex		; bit--
	bne	bloop2	; bit loop
	sta	crc8

	lda	#1	; if ((n & 1) == 0)	// n%2
	and	N
	bne	.odd
	lsr	N+1	;   n = n >> 1;		// n/2
	ror	N
	jmp	.next
.odd:			; else
	lda	N
	asl		; n = (3*n)+1
	tax
	lda	N+1
	rol
	tay
	sec
	txa
	adc	N
	sta	N
	tya
	adc	N+1
	sta	N+1

	jmp	.next

.done:	inc	M	; for (m = 1; m <= ITERATIONS; m++)
	bne	.loc
	inc	M+1
.loc:	lda	M+1
	cmp	#BENCHMARK_ITERATIONS>>8
	bne	.mainloop
	lda	M
	cmp	#BENCHMARK_ITERATIONS&$FF
	bcc	.mainloop
	beq	.mainloop	; BCC+BEQ = BLE

