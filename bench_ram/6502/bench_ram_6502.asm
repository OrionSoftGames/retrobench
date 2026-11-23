;<----------------------------->
; RAM Benchmark for 6502
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	= 7000
BENCHMARK_CRC8_RESULT	= $47

randseed = ZP_BASE
ptr	 = randseed+2
cnt	 = ptr+2
qn	 = cnt+2
qgap	 = qn+2
qi	 = qgap+2
qj	 = qi+2

CRC8_Table = RAM_BASE		; RAM_BASE MUST BE EVEN
RandomTable = CRC8_Table+256

	; Generate_CRC8_Table
	ldy	#0	; byte
c8loop:	tya		; crc
	ldx	#8	; bit
bloop:	asl		; crc << 1
	bcc	skip8	; if (crc & 0x80)
	eor	#$9B	; crc ^= 0x9B // CDMA2000
skip8:	dex		; bit--
	bne	bloop	; bit loop
	sta	CRC8_Table,y
	iny		; byte++
	bne	c8loop	; byte loop

	ldx	#$13
	ldy	#$37
	stx	<randseed+1
	sty	<randseed

	; Generate Random Numbers
	clc
	lda	#LOW(RandomTable)
	tay
	stz	<ptr
	adc	#LOW(BENCHMARK_ITERATIONS)
	sta	<cnt
	lda	#HIGH(RandomTable)
	sta	<ptr+1
	adc	#HIGH(BENCHMARK_ITERATIONS)
	sta	<cnt+1
.randloop:
	asl	<randseed	; randseed << 1
	rol	<randseed+1
	bcc	.done
	lda	<randseed
	eor	#$AF
	sta	<randseed
.done:	lda	<randseed+1
	sta	[<ptr],y
	iny
	lda	randseed
	sta	[<ptr],y
	iny			; RandomTable ptr++
	beq	.rIncPtr
.rVerifPtr:
	cpy	<cnt
	bne	.randloop
	lda	<ptr+1
	cmp	<cnt+1
	bne	.randloop
	bra	.randdone
.rIncPtr:
	inc	<ptr+1
	bra	.rVerifPtr
.randdone:


	; Shell Sort
	ldx	#HIGH(BENCHMARK_ITERATIONS)
	ldy	#LOW(BENCHMARK_ITERATIONS)
	stx	<qn+1
	sty	<qn
	stx	<qgap+1
	sty	<qgap
	ldy	#0
SortLoop:
	lsr	<qgap+1		; gap = n / 2
	ror	<qgap

	lda	<qgap
	ora	<qgap+1
	bne	.letsGo		; for (int gap = n / 2; gap > 0; gap /= 2)
	jmp	SortDone
.letsGo
	lda	<qgap
	sta	<qi
	lda	<qgap+1
	sta	<qi+1		; i = gap
.forLoop:
	lda	<qn+1		; for (int i = gap; i < n; i++)
	cmp	<qi+1
	beq	.ss1
	bcs	.ss2
	bra	SortLoop
.ss1:	lda	<qi
	cmp	<qn
	bcs	SortLoop
.ss2:
	clc
	lda	<qi
	adc	#LOW(RandomTable)
	sta	<ptr
	lda	<qi+1
	adc	#HIGH(RandomTable)
	sta	<ptr+1
	lda	[<ptr],y	; temp = arr[i];
	sta	<tmp

	lda	<qi
	sta	<qj
	lda	<qi+1
	sta	<qj+1		; j = i;
.whileLoop:
	lda	<qj+1		; j >= gap
	cmp	<qgap+1
	beq	.sf1
	bcs	.sf2
	bra	.out
.sf1:	lda	<qgap
	cmp	<qj
	beq	.sf2
	bcs	.out
.sf2:
	sec
	lda	<qj
	sbc	<qgap
	sta	<tmpw1
	lda	<qj+1
	sbc	<qgap+1
	sta	<tmpw1+1	; j - gap

	clc
	lda	<tmpw1
	adc	#LOW(RandomTable)
	sta	<ptr
	lda	<tmpw1+1
	adc	#HIGH(RandomTable)
	sta	<ptr+1
	lda	[<ptr],y	; arr[j - gap]
	cmp	<tmp		; arr[j - gap] > temp
	beq	.out
	bcc	.out
	tax
	clc
	lda	<qj
	adc	#LOW(RandomTable)
	sta	<tmpw2
	lda	<qj+1
	adc	#HIGH(RandomTable)
	sta	<tmpw2+1	; arr[j]
	txa
	sta	[<tmpw2],y	; arr[j] = arr[j - gap];
	lda	<tmpw1
	sta	<qj
	lda	<tmpw1+1
	sta	<qj+1		; j -= gap;
	bra	.whileLoop
.out:
	clc
	lda	<qj
	adc	#LOW(RandomTable)
	sta	<tmpw2
	lda	<qj+1
	adc	#HIGH(RandomTable)
	sta	<tmpw2+1
	lda	<tmp
	sta	[<tmpw2],y	; arr[j] = temp;

	inc	<qi
	bne	.here
	inc	<qi+1
.here:	jmp	.forLoop
SortDone:

	; CRC8 Verification
	clc
	lda	#LOW(RandomTable)
	tay
	stz	<ptr
	adc	#LOW(BENCHMARK_ITERATIONS)
	sta	<cnt
	lda	#HIGH(RandomTable)
	sta	<ptr+1
	adc	#HIGH(BENCHMARK_ITERATIONS)
	sta	<cnt+1
.crcloop:
	lda	[<ptr],y
	eor	<crc8
	tax
	lda	CRC8_Table,x	; crc8 = CRC8_Table[crc8 ^ RandomTable[i]];
	sta	<crc8
	iny			; RandomTable ptr++
	beq	.IncPtr
.VerifPtr:
	cpy	<cnt
	bne	.crcloop
	lda	<ptr+1
	cmp	<cnt+1
	bne	.crcloop
	bra	.crcdone
.IncPtr:
	inc	<ptr+1
	bra	.VerifPtr
.crcdone:

