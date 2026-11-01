;<----------------------------->
; CPU Benchmark for 68000
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	equ	702	; 16bits test CRC8 should be 0xB1
BENCHMARK_CRC8_RESULT	equ	$B1

	moveq	#1,d0	; m
.mainloop:
	move.w	d0,d1	; n = m;
.next:	cmpi.w	#1,d1	; while (n != 1)
	beq.s	.done

	move.w	d1,d2
	eor.b	d1,d7	; crc8 ^= n & 0xFF;
	lsr.w	#8,d2
	moveq	#8-1,d3	; bit counter
.blop1:	add.b	d7,d7	; crc << 1
	bcc.s	.noC1
	eor.b	#$9B,d7	; CDMA2000
.noC1:	dbra	d3,.blop1

	eor.b	d2,d7	; crc8 ^= n >> 8;
	moveq	#8-1,d3	; bit counter
.blop2:	add.b	d7,d7	; crc << 1
	bcc.s	.noC2
	eor.b	#$9B,d7	; CDMA2000
.noC2:	dbra	d3,.blop2

	btst	#0,d1	; if ((n & 1) == 0)	// n%2
	bne.s	.odd
	lsr.w	#1,d1	;   n = n >> 1;		// n/2
	bra.s	.next
.odd:			; else
	move.w	d1,d2	;   n = n + n + n + 1;	// 3*n+1
	add.w	d1,d1
	addq.w	#1,d2
	add.w	d2,d1
	bra.s	.next

.done:	addq.w	#1,d0	; for (m = 1; m <= ITERATIONS; m++)
	cmpi.w	#BENCHMARK_ITERATIONS,d0
	ble.s	.mainloop

