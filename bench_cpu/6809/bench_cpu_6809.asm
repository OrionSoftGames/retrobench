;<----------------------------->
; CPU Benchmark for 6809
;           by OrionSoft [2026]
;<----------------------------->

BENCHMARK_ITERATIONS	equ	702	; 16bits test CRC8 should be 0xB1
BENCHMARK_CRC8_RESULT	equ	$B1

	ORG	$2100		; Zeropage
crc8	RMB	1
N	RMB	2

	org	$3000

	SETDP	$21

	ldy	#1	; M = 1
.mainloop:
	tfr	y,d	; n = m;
.next:	cmpd	#1	; while (n != 1)
	beq	.done

	std	<N

	eorb	<crc8
	ldx	#8	; bit
.blop1:	aslb		; crc << 1
	bcc	.noC1	; if (crc & 0x80)
	eorb	#$9B	; crc ^= 0x9B
.noC1:	leax	-1,x	; bit--
	bne	.blop1	; bit loop
	stb	<crc8

	eora	<crc8
	ldx	#8	; bit
.blop2:	asla		; crc << 1
	bcc	.noC2	; if (crc & 0x80)
	eora	#$9B	; crc ^= 0x9B
.noC2:	leax	-1,x	; bit--
	bne	.blop2	; bit loop
	sta	<crc8

	ldd	<N
	lsra		; n >> 1, C = bit 0
	rorb
	bcc	.next
	std	<N	; 3*n+1
	aslb		; n+n
	rola
	addd	<N
	addd	#2
	aslb		; n+n
	rola
	bra	.next

.done:	leay	1,y	; for (m = 1; m <= ITERATIONS; m++)
	cmpy	#BENCHMARK_ITERATIONS
	ble	.mainloop

	ldb	#BENCHMARK_CRC8_RESULT
	rts

