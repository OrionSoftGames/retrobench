	.text

BENCHMARK_ITERATIONS	equ	7000
BENCHMARK_CRC8_RESULT	equ	$47

	; Generate_CRC8_Table
	lea	CRC8_Table,a0
	moveq	#0,d0
.loop8:	move.b	d0,d1		; crc
	moveq	#8-1,d2		; bit
.bloop:	add.b	d1,d1		; crc << 1
	bcc.s	.noC
	eor.b	#$9B,d1		; CDMA2000
.noC:	dbra	d2,.bloop
	move.b	d1,(a0)+
	addq.b	#1,d0
	bne.s	.loop8

	move.w	#$1337,d6	; randseed

	; Generate Random Numbers
	lea	RandomTable,a0
	move.w	#(BENCHMARK_ITERATIONS/2)-1,d0
.randloop:
	add.w	d6,d6		; rand
	bcc.s	.done
	eori.b	#$AF,d6
.done:	move.w	d6,(a0)+
	dbra	d0,.randloop

	; Shell Sort
	lea	RandomTable,a0
	move.w	#BENCHMARK_ITERATIONS,d0

	move.w	d0,d1
SortLoop:
	lsr.w	#1,d1		; gap = n / 2
	beq.s	SortDone	; for (int gap = n / 2; gap > 0; gap /= 2)

	move.w	d1,d2		; i = gap
.forLoop:
 	cmp.w	d0,d2		; for (int i = gap; i < n; i++)
 	bhs.s	SortLoop

	move.b	(a0,d2.w),d4	; temp = arr[i];
	move.w	d2,d3		; j = i;
.whileLoop:
	cmp.w	d1,d3		; j >= gap
	blt.s	.out

	move.w	d3,d5
	sub.w	d1,d5		; j - gap
	move.b	(a0,d5.w),d6
	cmp.b	d6,d4		; arr[j - gap] > temp
	bhs.s	.out
	move.b	d6,(a0,d3.w)	; arr[j] = arr[j - gap];
	move.w	d5,d3		; j -= gap;
	bra.s	.whileLoop
.out:
	move.b	d4,(a0,d3.w)	; arr[j] = temp;
	addq.w	#1,d2
 	bra.s	.forLoop
SortDone:

	; CRC8 Verification
	lea	CRC8_Table,a0
	lea	RandomTable,a1
	move.w	#BENCHMARK_ITERATIONS-1,d0
.crcloop:
	move.b	(a1)+,d1
	eor.b	d1,d7
	move.b	(a0,d7.w),d7	; crc8 = CRC8_Table[crc8 ^ RandomTable[i]];
	dbra	d0,.crcloop

	.bss

CRC8_Table:	ds.b	256
RandomTable:	ds.b	BENCHMARK_ITERATIONS

	.text

