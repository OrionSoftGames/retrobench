;<---------------------------------->
; Benchmark template for Thomson MO5
; Made as a disk boot sector.
;                by OrionSoft [2026]
;<---------------------------------->

CALL	MACRO
	SWI
	FCB	&1
	ENDM

PUTC	EQU	$02
GETC	EQU	$0A
DISK	EQU	$26

DK_READ	EQU	$02	; CMD
DK_CMD	EQU	$2048
DK_DRV	EQU	$2049
DK_TRK	EQU	$204A
DK_SECT	EQU	$204C
DK_BUF	EQU	$204F

CLS	EQU	$0C
ESC	EQU	$1B
CTXT	EQU	$40	; Text Color
CBKG	EQU	$50	; BG Color
CBDR	EQU	$60	; Border Color
BLACK	EQU	$00
WHITE	EQU	$07

	ORG	$2100		; Zeropage
crc8	RMB	1

	ORG	$2200

	LDX	#txt_title
	BSR	Print

	; Load Benchmark program from disk

	CLR	<DK_DRV		; DiskInit
	CLR	<DK_TRK
	LDA	#DK_READ
	STA	<DK_CMD

	LDA	#2		; Size / 256
	LDX	#$0002		; Track/Sector
	LDY	#$3000		; Buffer

	STX	<DK_TRK+1	; Store Track/Sector in 16bits because DK_SECT is following DK_TRK+1
	STY	<DK_BUF		; Buffer Address
	LDB	<DK_SECT	; B = Cur Sector (for later CMPB)
	ADDA	<DK_BUF		; A = Size + Buffer Start Address -> to get Buffer End Address
.load:
				; Read One Sector
	CALL	DISK
	CMPB	#16		; 16 Sector per Track
	BNE	.NextSector
	CLRB			; Reset Sector to 1
	INC	<DK_TRK+1	; Next Track
.NextSector:
	INCB			; Next Sector
	STB	<DK_SECT
	INC	<DK_BUF		; Buffer += 256
	CMPA	<DK_BUF		; Check if end of buffer
	BNE	.load		; Else load next sector

	LDX	#txt_presskey
	BSR	Print
WaitKey:
	CALL	GETC
	CMPB	#13
	BNE	WaitKey

	LDX	#txt_start
	BSR	Print

;------------------------------->

Bench:
	LDA	#$21	; Benchmark Zeropage at $2100
	PSHS	DP
	TFR	A,DP

	LDA	#$FF	; CRC8 init
	STA	<crc8

	JSR	$3000	; Bench starts there

	LDA	<crc8
	STB	<crc8	; B is the reference checksum loaded by the benchmark

	; Verify Checksum and display confirmation text
	LDX	#txt_good
	CMPA	<crc8
	BEQ	crc_is_ok
	LDX	#txt_error
crc_is_ok:
	PULS	DP	; Restore Zeropage before calling monitor
	BSR	Print
EndLoop:
	BRA	EndLoop

;------->

Print:	; X = Text
	LDB	,X+
	BEQ	.out
	CALL	PUTC
	BRA	Print
.out	RTS

;------->

; Leave space at $227F for boot sector checksum !

	ORG	$2280

txt_title:	FCB	ESC,CBDR|BLACK,ESC,CBKG|BLACK,ESC,CTXT|WHITE,CLS
		FCB	"Retro CPU Benchmark by OrionSoft 2026",10,13,0
txt_presskey:	FCB	"Press Entree to start...",10,13,0
txt_start:	FCB	"Benchmark result: ",0
txt_good:	FCB	"validated!",10,13,0
txt_error:	FCB	"error!",10,13,0

