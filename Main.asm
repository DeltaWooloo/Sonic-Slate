	include	"_def/Z80 Instructions.asm"
	cpu	68000
	include	"_def/System.asm"
	include	"_def/Debugger.asm"
	include	"_def/SMPS2ASM.asm"
	include	"_def/RAM.asm"
	include	"_def/Constants.asm"
	include	"_def/Macros.asm"

align macro
	cnop 0,\1
	endm
	
StartOfRom:
Vectors:	dc.l $FFFE00, EntryPoint, BusError, AddressError
		dc.l IllegalInstr, ZeroDivide, ChkInstr, TrapvInstr
		dc.l PrivilegeViol, Trace, Line1010Emu,	Line1111Emu
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorTrap, ErrorTrap,	ErrorTrap
		dc.l PalToCRAM,	ErrorTrap, loc_B10, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
System:	dc.b 'SEGA MEGA DRIVE ' ; Hardware system ID
Date:		dc.b '(R)NAME 2000.JAN' ; Release date
Title_Local:	dc.b 'SONIC SLATE                                     ' ; Domestic name
Title_Int:	dc.b 'SONIC SLATE                                     ' ; International name
Serial:		dc.b 'RH 00000000-00'   ; Serial/version number
Checksum:	dc.w 0
		dc.b 'J               ' ; I/O support
RomStartLoc:	dc.l StartOfRom		; ROM start
RomEndLoc:	dc.l EndOfRom-1		; ROM end
RamStartLoc:	dc.l $FF0000		; RAM start
RamEndLoc:	dc.l $FFFFFF		; RAM end
SRAMSupport:	dc.l $20202020		; change to $5241E020 to create	SRAM
		dc.l $20202020		; SRAM start
		dc.l $20202020		; SRAM end
Notes:		dc.b '                                                    '
Region:		dc.b 'JUE             ' ; Region

; ===========================================================================

ErrorTrap:
		bra.s	ErrorTrap
; ===========================================================================

EntryPoint:
		tst.l	($A10008).l	; test port A control
		bne.s	PortA_Ok
		tst.w	($A1000C).l	; test port C control

PortA_Ok:
		bne.s	PortC_Ok
		lea	SetupValues(pc),a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version
		andi.b	#$F,d0
		beq.s	SkipSecurity
		move.l	#'SEGA',$2F00(a1)

SkipSecurity:
		move.w	(a4),d0		; check	if VDP works
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp		; set usp to $0
		moveq	#$17,d1

VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to	VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop
		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear	the screen
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset	the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	WaitForZ80	; if not, branch
		moveq	#$25,d2

Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop
		move.w	d0,(a2)
		move.w	d0,(a1)		; start	the Z80
		move.w	d7,(a2)		; reset	the Z80

ClrRAMLoop:
		move.l	d0,-(a6)
		dbf	d6,ClrRAMLoop	; clear	the entire RAM
		move.l	(a5)+,(a4)	; set VDP display mode and increment
		move.l	(a5)+,(a4)	; set VDP to CRAM write
		moveq	#$1F,d3

ClrCRAMLoop:
		move.l	d0,(a3)
		dbf	d3,ClrCRAMLoop	; clear	the CRAM
		move.l	(a5)+,(a4)
		moveq	#$13,d4

ClrVDPStuff:
		move.l	d0,(a3)
		dbf	d4,ClrVDPStuff
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset	the PSG
		dbf	d5,PSGInitLoop
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear	all registers
		move	#$2700,sr	; set the sr

PortC_Ok:
		bra.s	GameProgram
; ===========================================================================
SetupValues:	dc.w $8000		; XREF: PortA_Ok
		dc.w $3FFF
		dc.w $100

		dc.l $A00000		; start	of Z80 RAM
		dc.l $A11100		; Z80 bus request
		dc.l $A11200		; Z80 reset
		dc.l $C00000
		dc.l $C00004		; address for VDP registers

		dc.b 4,	$14, $30, $3C	; values for VDP registers
		dc.b 7,	$6C, 0,	0
		dc.b 0,	0, $FF,	0
		dc.b $81, $37, 0, 1
		dc.b 1,	0, 0, $FF
		dc.b $FF, 0, 0,	$80

		dc.l $40000080

		dc.b $AF, 1, $D9, $1F, $11, $27, 0, $21, $26, 0, $F9, $77 ; Z80	instructions
		dc.b $ED, $B0, $DD, $E1, $FD, $E1, $ED,	$47, $ED, $4F
		dc.b $D1, $E1, $F1, 8, $D9, $C1, $D1, $E1, $F1,	$F9, $F3
		dc.b $ED, $56, $36, $E9, $E9

		dc.w $8104		; value	for VDP	display	mode
		dc.w $8F02		; value	for VDP	increment
		dc.l $C0000000		; value	for CRAM write mode
		dc.l $40000010

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================

GameProgram:
		cmpi.l	#'init',($FFFFFFFC).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch
		lea	($FFFFFE00).w,a6
		moveq	#0,d7
		move.w	#$7F,d6

loc_348:
		move.l	d7,(a6)+
		dbf	d6,loc_348
		move.b	($A10001).l,d0
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFF8).w
		move.l	#'init',($FFFFFFFC).w ; set flag so checksum won't be run again

GameInit:
		lea	($FF0000).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6

GameClrRAM:
		move.l	d7,(a6)+
		dbf	d6,GameClrRAM	; fill RAM ($0000-$FDFF) with $0
		jsr	(InitDMAQueue).l 
		bsr.w	VDPSetupGame
		bsr.w	SoundDriverLoad
		bsr.w	JoypadInit
		move.b	#ScnID_SEGA,($FFFFF600).w ; set Game Mode to Sega Screen

MainGameLoop:
		move.b	($FFFFF600).w,d0 ; load	Game Mode
		andi.w	#$1C,d0
		jsr	GameModeArray(pc,d0.w) ; jump to apt location in ROM
		bra.s	MainGameLoop
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:
		bra.w	JMPTo_SEGA	; Sega Screen ($00)
; ===========================================================================
		bra.w	JMPTo_Title	; Title	Screen ($04)
; ===========================================================================
		bra.w	JMPTo_Level		; Normal Level ($0C)
; ===========================================================================
		rts	
; ===========================================================================

JMPTo_SEGA:
		jmp	SegaScreen

JMPTo_Title:
		jmp	TitleScreen

JMPTo_Level:
		jmp	Level

Art_Text:	incbin	artunc\menutext.bin	; text used in level select and debug mode
		even

; ===========================================================================

loc_B10:				; XREF: Vectors
		movem.l	d0-a6,-(sp)
		tst.b	($FFFFF62A).w
		beq.s	loc_B88
		move.w	($C00004).l,d0
		move.l	#$40000010,($C00004).l
		move.l	($FFFFF616).w,($C00000).l
		btst	#6,($FFFFFFF8).w
		beq.s	loc_B42
		move.w	#$700,d0

loc_B3E:
		dbf	d0,loc_B3E

loc_B42:
		move.b	($FFFFF62A).w,d0
		move.b	#0,($FFFFF62A).w
		move.w	#1,($FFFFF644).w
		andi.w	#$3E,d0
		move.w	off_B6E(pc,d0.w),d0
		jsr	off_B6E(pc,d0.w)

loc_B5E:				; XREF: loc_B88
		jsr	sub_71B4C

loc_B64:				; XREF: loc_D50
		addq.l	#1,($FFFFFE0C).w
		movem.l	(sp)+,d0-a6
		rte	
; ===========================================================================
off_B6E:	dc.w loc_B88-off_B6E, loc_C32-off_B6E
		dc.w loc_C44-off_B6E, loc_C5E-off_B6E
		dc.w loc_C6E-off_B6E, loc_DA6-off_B6E
		dc.w loc_E72-off_B6E, loc_F8A-off_B6E
		dc.w loc_C64-off_B6E, loc_F9A-off_B6E
		dc.w loc_C36-off_B6E, loc_FA6-off_B6E
		dc.w loc_E72-off_B6E
; ===========================================================================

loc_B88:				; XREF: loc_B10; off_B6E
		cmpi.b	#$80|ScnID_Level,($FFFFF600).w
		beq.s	loc_B9A
		cmpi.b	#ScnID_Level,($FFFFF600).w
		bne.w	loc_B5E

loc_B9A:
		cmpi.b	#1,($FFFFFE10).w ; is level LZ ?
		bne.w	loc_B5E		; if not, branch
		move.w	($C00004).l,d0
		btst	#6,($FFFFFFF8).w
		beq.s	loc_BBA
		move.w	#$700,d0

loc_BB6:
		dbf	d0,loc_BB6

loc_BBA:
		move.w	#1,($FFFFF644).w
		move.w	#$100,($A11100).l

loc_BC8:
		btst	#0,($A11100).l
		bne.s	loc_BC8
		tst.b	($FFFFF64E).w
		bne.s	loc_BFE
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_C22
; ===========================================================================

loc_BFE:				; XREF: loc_BC8
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_C22:				; XREF: loc_BC8
		move.w	($FFFFF624).w,(a5)
        move.b	($FFFFF625).w,($FFFFFE07).w
		move.w	#0,($A11100).l
		bra.w	loc_B5E
; ===========================================================================

loc_C32:				; XREF: off_B6E
		bsr.w	sub_106E

loc_C36:				; XREF: off_B6E
		tst.w	($FFFFF614).w
		beq.w	locret_C42
		subq.w	#1,($FFFFF614).w

locret_C42:
		rts	
; ===========================================================================

loc_C44:				; XREF: off_B6E
		bsr.w	sub_106E
		bsr.w	sub_6886
		bsr.w	sub_1642
		tst.w	($FFFFF614).w
		beq.w	locret_C5C
		subq.w	#1,($FFFFF614).w

locret_C5C:
		rts	
; ===========================================================================

loc_C5E:				; XREF: off_B6E
		bsr.w	sub_106E
		rts	
; ===========================================================================

loc_C64:				; XREF: off_B6E
loc_C6E:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_C76:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_C76		; if not, branch
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_CB0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_CD4
; ===========================================================================

loc_CB0:				; XREF: loc_C76
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_CD4:				; XREF: loc_C76
		move.w	($FFFFF624).w,(a5)
		move.b	($FFFFF625).w,($FFFFFE07).w
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		jsr	(ProcessDMAQueue).l

loc_D50:
		move.w	#0,($A11100).l
		movem.l	($FFFFF700).w,d0-d7
		movem.l	d0-d7,($FFFFFF10).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,($FFFFFF30).w
		cmpi.b	#$60,($FFFFF625).w
		bcc.s	VInt_UpdateArt
		move.b	#1,($FFFFF64F).w
		addq.l	#4,sp
		bra.w	loc_B64

; ---------------------------------------------------------------------------
; Subroutine to	run a demo for an amount of time
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VInt_UpdateArt:				; XREF: loc_D50; PalToCRAM
		bsr.w	LoadTilesAsYouMove
		jsr	AniArt_Load
		jsr	HudUpdate
		bsr.w	sub_165E
		rts	
; End of function VInt_UpdateArt

; ===========================================================================

loc_DA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_DAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_DAE		; if not, branch
		bsr.w	ReadJoypads
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l
		jsr	(ProcessDMAQueue).l

loc_E64:
		tst.w	($FFFFF614).w
		beq.w	locret_E70
		subq.w	#1,($FFFFF614).w

locret_E70:
		rts	
; ===========================================================================

loc_E72:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_E7A:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_E7A		; if not, branch
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_EB4
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_ED8
; ===========================================================================

loc_EB4:				; XREF: loc_E7A
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_ED8:				; XREF: loc_E7A
		move.w	($FFFFF624).w,(a5)
		move.b	($FFFFF625).w,($FFFFFE07).w
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)

loc_EEE:
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		jsr	(ProcessDMAQueue).l

loc_F54:
		move.w	#0,($A11100).l	; start	the Z80
		movem.l	($FFFFF700).w,d0-d7
		movem.l	d0-d7,($FFFFFF10).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,($FFFFFF30).w
		bsr.w	LoadTilesAsYouMove
		jsr	AniArt_Load
		jsr	HudUpdate
		bsr.w	sub_1642
		rts	
; ===========================================================================

loc_F8A:				; XREF: off_B6E
		bsr.w	sub_106E
		addq.b	#1,($FFFFF628).w
		move.b	#$E,($FFFFF62A).w
		rts	
; ===========================================================================

loc_F9A:				; XREF: off_B6E
		bsr.w	sub_106E
		move.w	($FFFFF624).w,(a5)
		move.b	($FFFFF625).w,($FFFFFE07).w
		bra.w	sub_1642
; ===========================================================================

loc_FA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_FAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_FAE		; if not, branch
		bsr.w	ReadJoypads
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		jsr	(ProcessDMAQueue).l

loc_1060:
		tst.w	($FFFFF614).w
		beq.w	locret_106C
		subq.w	#1,($FFFFF614).w

locret_106C:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_106E:				; XREF: loc_C32; et al
		move.w	#$100,($A11100).l ; stop the Z80

loc_1076:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_1076	; if not, branch
		bsr.w	ReadJoypads
		tst.b	($FFFFF64E).w
		bne.s	loc_10B0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.s	loc_10D4
; ===========================================================================

loc_10B0:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_10D4:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function sub_106E

; ---------------------------------------------------------------------------
; Subroutine to	move pallets from the RAM to CRAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalToCRAM:
        tst.w    ($FFFFF644).w
        beq.s    locret_119C
        move.w    #0,($FFFFF644).w
        movem.l    d0-d1/a0-a2,-(sp)
 
        lea    ($C00000).l,a1
        move.w    #$8ADF,4(a1)        ; Reset HInt timing
        move.w  #$100,($A11100).l ; stop the Z80
@z80loop:
        btst    #0,($A11100).l
        bne.s   @z80loop ; loop until it says it's stopped
        movea.l    ($FFFFF610).w,a2
        moveq    #$F,d0        ; adjust to push artifacts off screen
@loop:
        dbf    d0,@loop    ; waste a few cycles here

        move.w    (a2)+,d1
        move.b    ($FFFFFE07).w,d0
        subi.b    #200,d0    ; is H-int occuring below line 200?
        bcs.s    @transferColors    ; if it is, branch
        sub.b    d0,d1
        bcs.s    @skipTransfer

@transferColors:
        move.w    (a2)+,d0
        lea    ($FFFFFA80).w,a0
        adda.w    d0,a0
        addi.w    #$C000,d0
        swap    d0
        move.l    d0,4(a1)    ; write to CRAM at appropriate address
        move.l    (a0)+,(a1)    ; transfer two colors
        move.w    (a0)+,(a1)    ; transfer the third color
        nop
        nop
        moveq    #$24,d0

@wasteSomeCycles:
        dbf    d0,@wasteSomeCycles
        dbf    d1,@transferColors    ; repeat for number of colors

@skipTransfer:
        move.w  #0,($A11100).l    ; start the Z80
        movem.l    (sp)+,d0-d1/a0-a2
        tst.b    ($FFFFF64F).w
        bne.s    loc_119E

locret_119C:
		rte	
; ===========================================================================

loc_119E:				; XREF: PalToCRAM
		clr.b	($FFFFF64F).w
		movem.l	d0-a6,-(sp)
		bsr.w	VInt_UpdateArt
		jsr	sub_71B4C
		movem.l	(sp)+,d0-a6
		rte	
; End of function PalToCRAM

; ---------------------------------------------------------------------------
; Subroutine to	initialise joypads
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


JoypadInit:				; XREF: GameClrRAM
		move.w	#$100,($A11100).l ; stop the Z80

Joypad_WaitZ80:
		btst	#0,($A11100).l	; has the Z80 stopped?
		bne.s	Joypad_WaitZ80	; if not, branch
		moveq	#$40,d0
		move.b	d0,($A10009).l	; init port 1 (joypad 1)
		move.b	d0,($A1000B).l	; init port 2 (joypad 2)
		move.b	d0,($A1000D).l	; init port 3 (extra)
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to	read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ReadJoypads:
		lea	($FFFFF604).w,a0 ; address where joypad	states are written
		lea	($A10003).l,a1	; first	joypad port
		bsr.s	Joypad_Read	; do the first joypad
		addq.w	#2,a1		; do the second	joypad

Joypad_Read:
		move.b	#0,(a1)
		nop	
		nop	
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1)
		nop	
		nop	
		move.b	(a1),d1
		andi.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts	
; End of function ReadJoypads


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDPSetupGame:				; XREF: GameClrRAM; ChecksumError
		lea	($C00004).l,a0
		lea	($C00000).l,a1
		lea	(VDPSetupArray).l,a2
		moveq	#$12,d7

VDP_Loop:
		move.w	(a2)+,(a0)
		dbf	d7,VDP_Loop	; set the VDP registers

		move.w	(VDPSetupArray+2).l,d0
		move.w	d0,($FFFFF60C).w
		move.w	#$8ADF,($FFFFF624).w
		moveq	#0,d0
		move.l	#$C0000000,($C00004).l ; set VDP to CRAM write
		move.w	#$3F,d7

VDP_ClrCRAM:
		move.w	d0,(a1)
		dbf	d7,VDP_ClrCRAM	; clear	the CRAM

		clr.l	($FFFFF616).w
		clr.l	($FFFFF61A).w
		move.l	d1,-(sp)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$94FF93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000080,(a5)
		move.w	#0,($C00000).l	; clear	the screen

loc_128E:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_128E

		move.w	#$8F02,(a5)
		move.l	(sp)+,d1
		rts	
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:	dc.w $8004, $8134, $8230, $8328	; XREF: VDPSetupGame
		dc.w $8407, $857C, $8600, $8700
		dc.w $8800, $8900, $8A00, $8B00
		dc.w $8C81, $8D3F, $8E00, $8F02
		dc.w $9001, $9100, $9200

; ---------------------------------------------------------------------------
; Subroutine to	clear the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearScreen:
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000083,(a5)
		move.w	#0,($C00000).l

loc_12E6:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_12E6

		move.w	#$8F02,(a5)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$60000083,(a5)
		move.w	#0,($C00000).l

loc_1314:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_1314

		move.w	#$8F02,(a5)
		move.l	#0,($FFFFF616).w
		move.l	#0,($FFFFF61A).w
		lea	($FFFFF800).w,a1
		moveq	#0,d0
		move.w	#$A0,d1

loc_133A:
		move.l	d0,(a1)+
		dbf	d1,loc_133A

		lea	($FFFFCC00).w,a1
		moveq	#0,d0
		move.w	#$FF,d1

loc_134A:
		move.l	d0,(a1)+
		dbf	d1,loc_134A
		rts	
; End of function ClearScreen

; ---------------------------------------------------------------------------
; Subroutine to	load the sound driver
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SoundDriverLoad:			; XREF: GameClrRAM; TitleScreen
		nop	
		move.w	#$100,($A11100).l ; stop the Z80
		move.w	#$100,($A11200).l ; reset the Z80
		lea	(Kos_Z80).l,a0	; load sound driver
		lea	($A00000).l,a1
		bsr.w	KosDec		; decompress
		move.w	#0,($A11200).l
		nop	
		nop	
		nop	
		nop	
		move.w	#$100,($A11200).l ; reset the Z80
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function SoundDriverLoad

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PlaySound:
		move.b	d0,($FFFFF00A).w
		rts	
; End of function PlaySound

; ---------------------------------------------------------------------------
; Subroutine to	play a special sound/music (E0-E4)
;
; E0 - Fade out
; E1 - Sega
; E2 - Speed up
; E3 - Normal speed
; E4 - Stop
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PlaySound_Special:
		move.b	d0,($FFFFF00B).w
		rts	
; End of function PlaySound_Special

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	pause the game
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PauseGame:				; XREF: Level_MainLoop; et al
		tst.b	($FFFFFE12).w	; do you have any lives	left?
		beq.s	Unpause		; if not, branch
		tst.w	($FFFFF63A).w	; is game already paused?
		bne.s	loc_13BE	; if yes, branch
		btst	#7,($FFFFF605).w ; is Start button pressed?
		beq.s	Pause_DoNothing	; if not, branch

loc_13BE:
		move.w	#1,($FFFFF63A).w ; freeze time
		move.b	#1,($FFFFF003).w ; pause music

loc_13CA:
		move.b	#$10,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.b	($FFFFFFE1).w	; is slow-motion cheat on?
		beq.s	Pause_ChkStart	; if not, branch
		btst	#6,($FFFFF605).w ; is button A pressed?
		beq.s	Pause_ChkBC	; if not, branch
		move.b	#ScnID_Title,($FFFFF600).w ; set game mode to 4 (title screen)
		bra.s	loc_1404
; ===========================================================================

Pause_ChkBC:				; XREF: PauseGame
		btst	#4,($FFFFF604).w ; is button B pressed?
		bne.s	Pause_SlowMo	; if yes, branch
		btst	#5,($FFFFF605).w ; is button C pressed?
		bne.s	Pause_SlowMo	; if yes, branch

Pause_ChkStart:				; XREF: PauseGame
		btst	#7,($FFFFF605).w ; is Start button pressed?
		beq.s	loc_13CA	; if not, branch

loc_1404:				; XREF: PauseGame
		move.b	#$80,($FFFFF003).w

Unpause:				; XREF: PauseGame
		move.w	#0,($FFFFF63A).w ; unpause the game

Pause_DoNothing:			; XREF: PauseGame
		rts	
; ===========================================================================

Pause_SlowMo:				; XREF: PauseGame
		move.w	#1,($FFFFF63A).w
		move.b	#$80,($FFFFF003).w
		rts	
; End of function PauseGame

	include	"Misc/DMA Queue.asm"

; ---------------------------------------------------------------------------
; Subroutine to	display	patterns via the VDP
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ShowVDPGraphics:			; XREF: SegaScreen; TitleScreen
		lea	($C00000).l,a6
		move.l	#$800000,d4

loc_142C:
		move.l	d0,4(a6)
		move.w	d1,d3

loc_1432:
		move.w	(a1)+,(a6)
		dbf	d3,loc_1432
		add.l	d4,d0
		dbf	d2,loc_142C
		rts	
; End of function ShowVDPGraphics

; ==============================================================================
; ------------------------------------------------------------------------------
; Nemesis decompression routine
; ------------------------------------------------------------------------------
; Optimized by vladikcomper
; ------------------------------------------------------------------------------
 
NemDec_RAM:
    movem.l d0-a1/a3-a6,-(sp)
    lea NemDec_WriteRowToRAM(pc),a3
    bra.s   NemDec_Main
 
; ------------------------------------------------------------------------------
NemDec:
    movem.l d0-a1/a3-a6,-(sp)
    lea $C00000,a4      ; load VDP Data Port     
    lea NemDec_WriteRowToVDP(pc),a3
 
NemDec_Main:
    lea $FFFFAA00,a1        ; load Nemesis decompression buffer
    move.w  (a0)+,d2        ; get number of patterns
    bpl.s   @0          ; are we in Mode 0?
    lea $A(a3),a3       ; if not, use Mode 1
@0  lsl.w   #3,d2
    movea.w d2,a5
    moveq   #7,d3
    moveq   #0,d2
    moveq   #0,d4
    bsr.w   NemDec4
    move.b  (a0)+,d5        ; get first byte of compressed data
    asl.w   #8,d5           ; shift up by a byte
    move.b  (a0)+,d5        ; get second byte of compressed data
    move.w  #$10,d6         ; set initial shift value
    bsr.s   NemDec2
    movem.l (sp)+,d0-a1/a3-a6
    rts
 
; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, processes the actual compressed data
; ---------------------------------------------------------------------------
 
NemDec2:
    move.w  d6,d7
    subq.w  #8,d7           ; get shift value
    move.w  d5,d1
    lsr.w   d7,d1           ; shift so that high bit of the code is in bit position 7
    cmpi.b  #%11111100,d1       ; are the high 6 bits set?
    bcc.s   NemDec_InlineData   ; if they are, it signifies inline data
    andi.w  #$FF,d1
    add.w   d1,d1
    sub.b   (a1,d1.w),d6        ; ~~ subtract from shift value so that the next code is read next time around
    cmpi.w  #9,d6           ; does a new byte need to be read?
    bcc.s   @0          ; if not, branch
    addq.w  #8,d6
    asl.w   #8,d5
    move.b  (a0)+,d5        ; read next byte
@0  move.b  1(a1,d1.w),d1
    move.w  d1,d0
    andi.w  #$F,d1          ; get palette index for pixel
    andi.w  #$F0,d0
 
NemDec_GetRepeatCount:
    lsr.w   #4,d0           ; get repeat count
 
NemDec_WritePixel:
    lsl.l   #4,d4           ; shift up by a nybble
    or.b    d1,d4           ; write pixel
    dbf d3,NemDec_WritePixelLoop; ~~
    jmp (a3)            ; otherwise, write the row to its destination
; ---------------------------------------------------------------------------
 
NemDec3:
    moveq   #0,d4           ; reset row
    moveq   #7,d3           ; reset nybble counter
 
NemDec_WritePixelLoop:
    dbf d0,NemDec_WritePixel
    bra.s   NemDec2
; ---------------------------------------------------------------------------
 
NemDec_InlineData:
    subq.w  #6,d6           ; 6 bits needed to signal inline data
    cmpi.w  #9,d6
    bcc.s   @0
    addq.w  #8,d6
    asl.w   #8,d5
    move.b  (a0)+,d5
@0  subq.w  #7,d6           ; and 7 bits needed for the inline data itself
    move.w  d5,d1
    lsr.w   d6,d1           ; shift so that low bit of the code is in bit position 0
    move.w  d1,d0
    andi.w  #$F,d1          ; get palette index for pixel
    andi.w  #$70,d0         ; high nybble is repeat count for pixel
    cmpi.w  #9,d6
    bcc.s   NemDec_GetRepeatCount
    addq.w  #8,d6
    asl.w   #8,d5
    move.b  (a0)+,d5
    bra.s   NemDec_GetRepeatCount
 
; ---------------------------------------------------------------------------
; Subroutines to output decompressed entry
; Selected depending on current decompression mode
; ---------------------------------------------------------------------------
 
NemDec_WriteRowToVDP:
loc_1502:
    move.l  d4,(a4)         ; write 8-pixel row
    subq.w  #1,a5
    move.w  a5,d4           ; have all the 8-pixel rows been written?
    bne.s   NemDec3         ; if not, branch
    rts
; ---------------------------------------------------------------------------
 
NemDec_WriteRowToVDP_XOR:
    eor.l   d4,d2           ; XOR the previous row by the current row
    move.l  d2,(a4)         ; and write the result
    subq.w  #1,a5
    move.w  a5,d4
    bne.s   NemDec3
    rts
; ---------------------------------------------------------------------------
 
NemDec_WriteRowToRAM:
    move.l  d4,(a4)+        ; write 8-pixel row
    subq.w  #1,a5
    move.w  a5,d4           ; have all the 8-pixel rows been written?
    bne.s   NemDec3         ; if not, branch
    rts
; ---------------------------------------------------------------------------
 
NemDec_WriteRowToRAM_XOR:
    eor.l   d4,d2           ; XOR the previous row by the current row
    move.l  d2,(a4)+        ; and write the result
    subq.w  #1,a5
    move.w  a5,d4
    bne.s   NemDec3
    rts
 
; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, builds the code table (in RAM)
; ---------------------------------------------------------------------------
 
NemDec4:
    move.b  (a0)+,d0        ; read first byte
 
@ChkEnd:
    cmpi.b  #$FF,d0         ; has the end of the code table description been reached?
    bne.s   @NewPalIndex        ; if not, branch
    rts
; ---------------------------------------------------------------------------
 
@NewPalIndex:
    move.w  d0,d7
 
@ItemLoop:
    move.b  (a0)+,d0        ; read next byte
    bmi.s   @ChkEnd         ; ~~
    move.b  d0,d1
    andi.w  #$F,d7          ; get palette index
    andi.w  #$70,d1         ; get repeat count for palette index
    or.w    d1,d7           ; combine the two
    andi.w  #$F,d0          ; get the length of the code in bits
    move.b  d0,d1
    lsl.w   #8,d1
    or.w    d1,d7           ; combine with palette index and repeat count to form code table entry
    moveq   #8,d1
    sub.w   d0,d1           ; is the code 8 bits long?
    bne.s   @ItemShortCode      ; if not, a bit of extra processing is needed
    move.b  (a0)+,d0        ; get code
    add.w   d0,d0           ; each code gets a word-sized entry in the table
    move.w  d7,(a1,d0.w)        ; store the entry for the code
    bra.s   @ItemLoop       ; repeat
; ---------------------------------------------------------------------------
 
@ItemShortCode:
    move.b  (a0)+,d0        ; get code
    lsl.w   d1,d0           ; shift so that high bit is in bit position 7
    add.w   d0,d0           ; get index into code table
    moveq   #1,d5
    lsl.w   d1,d5
    subq.w  #1,d5           ; d5 = 2^d1 - 1
    lea (a1,d0.w),a6        ; ~~
 
@ItemShortCodeLoop:
    move.w  d7,(a6)+        ; ~~ store entry
    dbf d5,@ItemShortCodeLoop   ; repeat for required number of entries
    bra.s   @ItemLoop

; ---------------------------------------------------------------------------
; Subroutine to	load pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		lea	($FFFFF680).w,a2

loc_1598:
		tst.l	(a2)
		beq.s	loc_15A0
		addq.w	#6,a2
		bra.s	loc_1598
; ===========================================================================

loc_15A0:				; XREF: LoadPLC
		move.w	(a1)+,d0
		bmi.s	loc_15AC

loc_15A4:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_15A4

loc_15AC:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC2:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		bsr.s	ClearPLC
		lea	($FFFFF680).w,a2
		move.w	(a1)+,d0
		bmi.s	loc_15D8

loc_15D0:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_15D0

loc_15D8:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC2

; ---------------------------------------------------------------------------
; Subroutine to	clear the pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearPLC:				; XREF: LoadPLC2
		lea	($FFFFF680).w,a2
		moveq	#$1F,d0

ClearPLC_Loop:
		clr.l	(a2)+
		dbf	d0,ClearPLC_Loop
		rts	
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to	use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_RAM:				; XREF: Pal_FadeTo
		tst.l	($FFFFF680).w
		beq.s	locret_1640
		tst.w	($FFFFF6F8).w
		bne.s	locret_1640
		movea.l	($FFFFF680).w,a0
		lea	(loc_1502).l,a3
		lea	($FFFFAA00).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_160E
		adda.w	#$A,a3

loc_160E:
		andi.w	#$7FFF,d2
		bsr.w	NemDec4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d0,($FFFFF6E8).w
		move.l	d0,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w
		move.w	d2,($FFFFF6F8).w

locret_1640:
		rts	
; End of function RunPLC_RAM


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1642:				; XREF: loc_C44; loc_F54; loc_F9A
		tst.w	($FFFFF6F8).w
		beq.w	locret_16DA
		move.w	#9,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$120,($FFFFF684).w
		bra.s	loc_1676
; End of function sub_1642


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_165E:				; XREF: VInt_UpdateArt
		tst.w	($FFFFF6F8).w
		beq.s	locret_16DA
		move.w	#3,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$60,($FFFFF684).w

loc_1676:				; XREF: sub_1642
		lea	($C00004).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	($FFFFF680).w,a0
		movea.l	($FFFFF6E0).w,a3
		move.l	($FFFFF6E4).w,d0
		move.l	($FFFFF6E8).w,d1
		move.l	($FFFFF6EC).w,d2
		move.l	($FFFFF6F0).w,d5
		move.l	($FFFFF6F4).w,d6
		lea	($FFFFAA00).w,a1

loc_16AA:				; XREF: sub_165E
		movea.w	#8,a5
		bsr.w	NemDec3
		subq.w	#1,($FFFFF6F8).w
		beq.s	loc_16DC
		subq.w	#1,($FFFFF6FA).w
		bne.s	loc_16AA
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d1,($FFFFF6E8).w
		move.l	d2,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_16DA:				; XREF: sub_1642
		rts	
; ===========================================================================

loc_16DC:	; XREF: sub_165E
		lea	($FFFFF680).w,a0
		lea	6(a0),a1
		moveq	#$E,d0	; do $F cues

loc_16E2:	; XREF: sub_165E
		move.l	(a1)+,(a0)+
		move.w	(a1)+,(a0)+
		dbf	d0,loc_16E2
		moveq	#0,d0
		move.l	d0,(a0)+	; clear the last cue to avoid overcopying it
		move.w	d0,(a0)+
		rts
; End of function sub_165E

; ---------------------------------------------------------------------------
; Subroutine to	execute	the pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_ROM:
		lea	(ArtLoadCues).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; load number of entries in the	PLC

RunPLC_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0		; divide address by $20
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,($C00004).l	; put the VRAM address into VDP
		bsr.w	NemDec		; decompress
		dbf	d1,RunPLC_Loop	; loop for number of entries
		rts	
; End of function RunPLC_ROM

; ---------------------------------------------------------------------------
; Enigma decompression algorithm
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


EniDec:
		movem.l	d0-d7/a1-a5,-(sp)
		movea.w	d0,a3
		move.b	(a0)+,d0
		ext.w	d0
		movea.w	d0,a5
		move.b	(a0)+,d4
		lsl.b	#3,d4
		movea.w	(a0)+,a2
		adda.w	a3,a2
		movea.w	(a0)+,a4
		adda.w	a3,a4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6

loc_173E:				; XREF: loc_1768
		moveq	#7,d0
		move.w	d6,d7
		sub.w	d0,d7
		move.w	d5,d1
		lsr.w	d7,d1
		andi.w	#$7F,d1
		move.w	d1,d2
		cmpi.w	#$40,d1
		bcc.s	loc_1758
		moveq	#6,d0
		lsr.w	#1,d2

loc_1758:
		bsr.w	sub_188C
		andi.w	#$F,d2
		lsr.w	#4,d1
		add.w	d1,d1
		jmp	loc_17B4(pc,d1.w)
; End of function EniDec

; ===========================================================================

loc_1768:				; XREF: loc_17B4
		move.w	a2,(a1)+
		addq.w	#1,a2
		dbf	d2,loc_1768
		bra.s	loc_173E
; ===========================================================================

loc_1772:				; XREF: loc_17B4
		move.w	a4,(a1)+
		dbf	d2,loc_1772
		bra.s	loc_173E
; ===========================================================================

loc_177A:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_177E:
		move.w	d1,(a1)+
		dbf	d2,loc_177E
		bra.s	loc_173E
; ===========================================================================

loc_1786:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_178A:
		move.w	d1,(a1)+
		addq.w	#1,d1
		dbf	d2,loc_178A
		bra.s	loc_173E
; ===========================================================================

loc_1794:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_1798:
		move.w	d1,(a1)+
		subq.w	#1,d1
		dbf	d2,loc_1798
		bra.s	loc_173E
; ===========================================================================

loc_17A2:				; XREF: loc_17B4
		cmpi.w	#$F,d2
		beq.s	loc_17C4

loc_17A8:
		bsr.w	loc_17DC
		move.w	d1,(a1)+
		dbf	d2,loc_17A8
		bra.s	loc_173E
; ===========================================================================

loc_17B4:				; XREF: EniDec
		bra.s	loc_1768
; ===========================================================================
		bra.s	loc_1768
; ===========================================================================
		bra.s	loc_1772
; ===========================================================================
		bra.s	loc_1772
; ===========================================================================
		bra.s	loc_177A
; ===========================================================================
		bra.s	loc_1786
; ===========================================================================
		bra.s	loc_1794
; ===========================================================================
		bra.s	loc_17A2
; ===========================================================================

loc_17C4:				; XREF: loc_17A2
		subq.w	#1,a0
		cmpi.w	#$10,d6
		bne.s	loc_17CE
		subq.w	#1,a0

loc_17CE:
		move.w	a0,d0
		lsr.w	#1,d0
		bcc.s	loc_17D6
		addq.w	#1,a0

loc_17D6:
		movem.l	(sp)+,d0-d7/a1-a5
		rts	
; ===========================================================================

loc_17DC:				; XREF: loc_17A2
		move.w	a3,d3
		move.b	d4,d1
		add.b	d1,d1
		bcc.s	loc_17EE
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_17EE
		ori.w	#-$8000,d3

loc_17EE:
		add.b	d1,d1
		bcc.s	loc_17FC
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_17FC
		addi.w	#$4000,d3

loc_17FC:
		add.b	d1,d1
		bcc.s	loc_180A
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_180A
		addi.w	#$2000,d3

loc_180A:
		add.b	d1,d1
		bcc.s	loc_1818
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_1818
		ori.w	#$1000,d3

loc_1818:
		add.b	d1,d1
		bcc.s	loc_1826
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_1826
		ori.w	#$800,d3

loc_1826:
		move.w	d5,d1
		move.w	d6,d7
		sub.w	a5,d7
		bcc.s	loc_1856
		move.w	d7,d6
		addi.w	#$10,d6
		neg.w	d7
		lsl.w	d7,d1
		move.b	(a0),d5
		rol.b	d7,d5
		add.w	d7,d7
		and.w	word_186C-2(pc,d7.w),d5
		add.w	d5,d1

loc_1844:				; XREF: loc_1868
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.b	(a0)+,d5
		lsl.w	#8,d5
		move.b	(a0)+,d5
		rts	
; ===========================================================================

loc_1856:				; XREF: loc_1826
		beq.s	loc_1868
		lsr.w	d7,d1
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.w	a5,d0
		bra.s	sub_188C
; ===========================================================================

loc_1868:				; XREF: loc_1856
		moveq	#$10,d6

loc_186A:
		bra.s	loc_1844
; ===========================================================================
word_186C:	dc.w 1,	3, 7, $F, $1F, $3F, $7F, $FF, $1FF, $3FF, $7FF
		dc.w $FFF, $1FFF, $3FFF, $7FFF,	$FFFF	; XREF: loc_1856

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_188C:				; XREF: EniDec
		sub.w	d0,d6
		cmpi.w	#9,d6
		bcc.s	locret_189A
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

locret_189A:
		rts	
; End of function sub_188C

; ===========================================================================
; ---------------------------------------------------------------------------
; Kosinski decompression routine
;
; Created by vladikcomper
; Special thanks to flamewing and MarkeyJester
; ---------------------------------------------------------------------------
 
_Kos_RunBitStream macro
    dbf d2,@skip\@
    moveq   #7,d2
    move.b  d1,d0
    swap    d3
    bpl.s   @skip\@
    move.b  (a0)+,d0            ; get desc. bitfield
    move.b  (a0)+,d1            ;
    move.b  (a4,d0.w),d0            ; reload converted desc. bitfield from a LUT
    move.b  (a4,d1.w),d1            ;
@skip\@
    endm
; ---------------------------------------------------------------------------
 
KosDec:
    moveq   #7,d7
    moveq   #0,d0
    moveq   #0,d1
    lea KosDec_ByteMap(pc),a4
    move.b  (a0)+,d0            ; get desc field low-byte
    move.b  (a0)+,d1            ; get desc field hi-byte
    move.b  (a4,d0.w),d0            ; reload converted desc. bitfield from a LUT
    move.b  (a4,d1.w),d1            ;
    moveq   #7,d2               ; set repeat count to 8
    moveq   #-1,d3              ; d3 will be desc field switcher
    clr.w   d3              ;
    bra.s   KosDec_FetchNewCode
 
KosDec_FetchCodeLoop:
    ; code 1 (Uncompressed byte)
    _Kos_RunBitStream
    move.b  (a0)+,(a1)+
 
KosDec_FetchNewCode:
    add.b   d0,d0               ; get a bit from the bitstream
    bcs.s   KosDec_FetchCodeLoop        ; if code = 0, branch
 
    ; codes 00 and 01
    _Kos_RunBitStream
    moveq   #0,d4               ; d4 will contain copy count
    add.b   d0,d0               ; get a bit from the bitstream
    bcs.s   KosDec_Code_01
 
    ; code 00 (Dictionary ref. short)
    _Kos_RunBitStream
    add.b   d0,d0               ; get a bit from the bitstream
    addx.w  d4,d4
    _Kos_RunBitStream
    add.b   d0,d0               ; get a bit from the bitstream
    addx.w  d4,d4
    _Kos_RunBitStream
    moveq   #-1,d5
    move.b  (a0)+,d5            ; d5 = displacement
 
KosDec_StreamCopy:
    lea (a1,d5),a3
    move.b  (a3)+,(a1)+         ; do 1 extra copy (to compensate for +1 to copy counter)
 
KosDec_copy:
    move.b  (a3)+,(a1)+
    dbf d4,KosDec_copy
    bra.w   KosDec_FetchNewCode
; ---------------------------------------------------------------------------
KosDec_Code_01:
    ; code 01 (Dictionary ref. long / special)
    _Kos_RunBitStream
    move.b  (a0)+,d6            ; d6 = %LLLLLLLL
    move.b  (a0)+,d4            ; d4 = %HHHHHCCC
    moveq   #-1,d5
    move.b  d4,d5               ; d5 = %11111111 HHHHHCCC
    lsl.w   #5,d5               ; d5 = %111HHHHH CCC00000
    move.b  d6,d5               ; d5 = %111HHHHH LLLLLLLL
    and.w   d7,d4               ; d4 = %00000CCC
    bne.s   KosDec_StreamCopy       ; if CCC=0, branch
 
    ; special mode (extended counter)
    move.b  (a0)+,d4            ; read cnt
    beq.s   KosDec_Quit         ; if cnt=0, quit decompression
    subq.b  #1,d4
    beq.w   KosDec_FetchNewCode     ; if cnt=1, fetch a new code
 
    lea (a1,d5),a3
    move.b  (a3)+,(a1)+         ; do 1 extra copy (to compensate for +1 to copy counter)
    move.w  d4,d6
    not.w   d6
    and.w   d7,d6
    add.w   d6,d6
    lsr.w   #3,d4
    jmp KosDec_largecopy(pc,d6.w)
 
KosDec_largecopy:
    rept 8
    move.b  (a3)+,(a1)+
    endr
    dbf d4,KosDec_largecopy
    bra.w   KosDec_FetchNewCode
 
KosDec_Quit:
    rts
 
; ---------------------------------------------------------------------------
; A look-up table to invert bits order in desc. field bytes
; ---------------------------------------------------------------------------
 
KosDec_ByteMap:
    dc.b    $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
    dc.b    $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
    dc.b    $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
    dc.b    $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
    dc.b    $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
    dc.b    $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
    dc.b    $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
    dc.b    $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
    dc.b    $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
    dc.b    $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
    dc.b    $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
    dc.b    $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
    dc.b    $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
    dc.b    $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
    dc.b    $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
    dc.b    $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF
 
; ===========================================================================

; ---------------------------------------------------------------------------
; Pallet cycling routine loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Load:				; XREF: Demo; Level_MainLoop; End_MainLoop
		cmp.b	#6,($FFFFD000+Obj_Routine).w
		bge.s	@DontRunPalCycle
		moveq	#0,d2
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0 ; get level number
		add.w	d0,d0		; multiply by 2
		move.w	PalCycle(pc,d0.w),d0 ; load animated pallets offset index into d0
		jmp	PalCycle(pc,d0.w) ; jump to PalCycle + offset index

@DontRunPalCycle:
		rts
; End of function PalCycle_Load

; ===========================================================================
; ---------------------------------------------------------------------------
; Pallet cycling routines
; ---------------------------------------------------------------------------
PalCycle:	dc.w PalCycle_GHZ-PalCycle

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

PalCycle_GHZ:				; XREF: PalCycle
		rts	
; End of function PalCycle_GHZ

; ---------------------------------------------------------------------------
; Subroutine to	fade out and fade in
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeTo:
		move.w	#$3F,($FFFFF626).w

Pal_FadeTo2:
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		moveq	#0,d1
		move.b	($FFFFF627).w,d0

Pal_ToBlack:
		move.w	d1,(a0)+
		dbf	d0,Pal_ToBlack	; fill pallet with $000	(black)
		moveq	#$0E,d4					; MJ: prepare maximum colour check
		moveq	#$00,d6					; MJ: clear d6

loc_1DCE:
		bsr.w	RunPLC_RAM
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bchg	#$00,d6					; MJ: change delay counter
		beq	loc_1DCE				; MJ: if null, delay a frame
		bsr.s	Pal_FadeIn
		subq.b	#$02,d4					; MJ: decrease colour check
		bne	loc_1DCE				; MJ: if it has not reached null, branch
		move.b	#$12,($FFFFF62A).w			; MJ: wait for V-blank again (so colours transfer)
		bra	DelayProgram				; MJ: ''

; End of function Pal_FadeTo

; ---------------------------------------------------------------------------
; Pallet fade-in subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeIn:				; XREF: Pal_FadeTo
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		lea	($FFFFFB80).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1DFA:
		bsr.s	Pal_AddColor
		dbf	d0,loc_1DFA
		cmpi.b	#1,($FFFFFE10).w
		bne.s	locret_1E24
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		lea	($FFFFFA00).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1E1E:
		bsr.s	Pal_AddColor
		dbf	d0,loc_1E1E

locret_1E24:
		rts	
; End of function Pal_FadeIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor:				; XREF: Pal_FadeIn
		move.b	(a1),d5					; MJ: load blue
		move.w	(a1)+,d1				; MJ: load green and red
		move.b	d1,d2					; MJ: load red
		lsr.b	#$04,d1					; MJ: get only green
		andi.b	#$0E,d2					; MJ: get only red
		move.w	(a0),d3					; MJ: load current colour in buffer
		cmp.b	d5,d4					; MJ: is it time for blue to fade?
		bhi	FCI_NoBlue				; MJ: if not, branch
		addi.w	#$0200,d3				; MJ: increase blue

FCI_NoBlue:
		cmp.b	d1,d4					; MJ: is it time for green to fade?
		bhi	FCI_NoGreen				; MJ: if not, branch
		addi.b	#$20,d3					; MJ: increase green

FCI_NoGreen:
		cmp.b	d2,d4					; MJ: is it time for red to fade?
		bhi	FCI_NoRed				; MJ: if not, branch
		addq.b	#$02,d3					; MJ: increase red

FCI_NoRed:
		move.w	d3,(a0)+				; MJ: save colour
		rts						; MJ: return

; End of function Pal_AddColor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeFrom:
		move.w	#$3F,($FFFFF626).w
		moveq	#$07,d4					; MJ: set repeat times
		moveq	#$00,d6					; MJ: clear d6

loc_1E5C:
		bsr.w	RunPLC_RAM
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bchg	#$00,d6					; MJ: change delay counter
		beq	loc_1E5C				; MJ: if null, delay a frame
		bsr.s	Pal_FadeOut
		dbf	d4,loc_1E5C
		rts	
; End of function Pal_FadeFrom

; ---------------------------------------------------------------------------
; Pallet fade-out subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeOut:				; XREF: Pal_FadeFrom
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1E82:
		bsr.s	Pal_DecColor
		dbf	d0,loc_1E82

		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1E98:
		bsr.s	Pal_DecColor
		dbf	d0,loc_1E98
		rts	
; End of function Pal_FadeOut


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor:				; XREF: Pal_FadeOut
		move.w	(a0),d5					; MJ: load colour
		move.w	d5,d1					; MJ: copy to d1
		move.b	d1,d2					; MJ: load green and red
		move.b	d1,d3					; MJ: load red
		andi.w	#$0E00,d1				; MJ: get only blue
		beq	FCO_NoBlue				; MJ: if blue is finished, branch
		subi.w	#$0200,d5				; MJ: decrease blue

FCO_NoBlue:
		andi.w	#$00E0,d2				; MJ: get only green (needs to be word)
		beq	FCO_NoGreen				; MJ: if green is finished, branch
		subi.b	#$20,d5					; MJ: decrease green

FCO_NoGreen:
		andi.b	#$0E,d3					; MJ: get only red
		beq	FCO_NoRed				; MJ: if red is finished, branch
		subq.b	#$02,d5					; MJ: decrease red

FCO_NoRed:
		move.w	d5,(a0)+				; MJ: save new colour
		rts						; MJ: return

; End of function Pal_DecColor

; ---------------------------------------------------------------------------
; Subroutine to	fill the pallet	with white
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_MakeWhite:
        move.w #$3F,($FFFFF626).w
        moveq #0,d0
        lea ($FFFFFB00).w,a0
        move.b ($FFFFF626).w,d0
        adda.w d0,a0
        move.w #$EEE,d1
        move.b ($FFFFF627).w,d0

PalWhite_Loop:
        move.w d1,(a0)+
        dbf d0,PalWhite_Loop ; fill pallet with $000 (black)
        moveq #$0E,d4 ; MJ: prepare maximum colour check
        moveq #$00,d6 ; MJ: clear d6

loc_1EF4:
        bsr.w RunPLC_RAM
        move.b #$12,($FFFFF62A).w
        bsr.w DelayProgram
        bchg #$00,d6 ; MJ: change delay counter
        beq loc_1EF4 ; MJ: if null, delay a frame
        bsr.s Pal_WhiteToBlack
        subq.b #$02,d4 ; MJ: decrease colour check
        bne loc_1EF4 ; MJ: if it has not reached null, branch
        move.b #$12,($FFFFF62A).w ; MJ: wait for V-blank again (so colours transfer)
        bra DelayProgram ; MJ: ''
; End of function Pal_MakeWhite


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Pal_WhiteToBlack: ; XREF: Pal_MakeWhite
        moveq #0,d0
        lea ($FFFFFB00).w,a0
        lea ($FFFFFB80).w,a1
        move.b ($FFFFF626).w,d0
        adda.w d0,a0
        adda.w d0,a1
        move.b ($FFFFF627).w,d0

loc_1F20:
        bsr.s Pal_DecColor2
        dbf d0,loc_1F20
        cmpi.b #1,($FFFFFE10).w
        bne.s locret_1F4A
        moveq #0,d0
        lea ($FFFFFA80).w,a0
        lea ($FFFFFA00).w,a1
        move.b ($FFFFF626).w,d0
        adda.w d0,a0
        adda.w d0,a1
        move.b ($FFFFF627).w,d0

loc_1F44:
        bsr.s Pal_DecColor2
        dbf d0,loc_1F44

locret_1F4A:
        rts
; End of function Pal_WhiteToBlack


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor2: ; XREF: Pal_WhiteToBlack
        move.b (a1),d5 ; MJ: load blue
        move.w (a1)+,d1 ; MJ: load green and red
        move.b d1,d2 ; MJ: load red
        lsr.b #$04,d1 ; MJ: get only green
        andi.b #$0E,d2 ; MJ: get only red
        move.w (a0),d3 ; MJ: load current colour in buffer
        cmp.b d5,d4 ; MJ: is it time for blue to fade?
        bls FCI2_NoBlue ; MJ: if not, branch
        subi.w #$0200,d3 ; MJ: dencrease blue

FCI2_NoBlue:
        cmp.b d1,d4 ; MJ: is it time for green to fade?
        bls FCI2_NoGreen ; MJ: if not, branch
        subi.b #$20,d3 ; MJ: dencrease green

FCI2_NoGreen:
        cmp.b d2,d4 ; MJ: is it time for red to fade?
        bls FCI2_NoRed ; MJ: if not, branch
        subq.b #$02,d3 ; MJ: dencrease red

FCI2_NoRed:
        move.w d3,(a0)+ ; MJ: save colour
        rts ; MJ: return
; End of function Pal_DecColor2

; ---------------------------------------------------------------------------
; Subroutine to make a white flash
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Pal_MakeFlash:
        move.w #$3F,($FFFFF626).w
        moveq #$07,d4 ; MJ: set repeat times
        moveq #$00,d6 ; MJ: clear d6

loc_1F86:
        bsr.w RunPLC_RAM
        move.b #$12,($FFFFF62A).w
        bsr.w DelayProgram
        bchg #$00,d6 ; MJ: change delay counter
        beq loc_1F86 ; MJ: if null, delay a frame
        bsr.s Pal_ToWhite
        dbf d4,loc_1F86
        rts
; End of function Pal_MakeFlash


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Pal_ToWhite: ; XREF: Pal_MakeFlash
        moveq #0,d0
        lea ($FFFFFB00).w,a0
        move.b ($FFFFF626).w,d0
        adda.w d0,a0
        move.b ($FFFFF627).w,d0

loc_1FAC:
        bsr.s Pal_AddColor2
        dbf d0,loc_1FAC

        moveq #0,d0
        lea ($FFFFFA80).w,a0
        move.b ($FFFFF626).w,d0
        adda.w d0,a0
        move.b ($FFFFF627).w,d0

loc_1FC2:
        bsr.s Pal_AddColor2
        dbf d0,loc_1FC2
        rts
; End of function Pal_ToWhite


; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor2: ; XREF: Pal_ToWhite
        move.w (a0),d5 ; MJ: load colour
        cmpi.w #$EEE,d5
        beq.s FCO2_NoRed
        move.w d5,d1 ; MJ: copy to d1
        move.b d1,d2 ; MJ: load green and red
        move.b d1,d3 ; MJ: load red
        andi.w #$0E00,d1 ; MJ: get only blue
        cmpi.w #$0E00,d1
        beq FCO2_NoBlue ; MJ: if blue is finished, branch
        addi.w #$0200,d5 ; MJ: increase blue

FCO2_NoBlue:
        andi.w #$00E0,d2 ; MJ: get only green (needs to be word)
        cmpi.w #$00E0,d2
        beq FCO2_NoGreen ; MJ: if green is finished, branch
        addi.b #$20,d5 ; MJ: increase green

FCO2_NoGreen:
        andi.b #$0E,d3 ; MJ: get only red
        cmpi.b #$0E,d3
        beq FCO2_NoRed ; MJ: if red is finished, branch
        addq.b #$02,d5 ; MJ: increase red

FCO2_NoRed:
        move.w d5,(a0)+ ; MJ: save new colour
        rts ; MJ: return
; End of function Pal_AddColor2

; ---------------------------------------------------------------------------
; Pallet cycling routine - Sega	logo
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Sega:				; XREF: SegaScreen
		tst.b	($FFFFF635).w
		bne.s	loc_206A
		lea	($FFFFFB20).w,a1
		lea	(Pal_Sega1).l,a0
		moveq	#5,d1
		move.w	($FFFFF632).w,d0

loc_2020:
		bpl.s	loc_202A
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.s	loc_2020
; ===========================================================================

loc_202A:				; XREF: PalCycle_Sega
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2034
		addq.w	#2,d0

loc_2034:
		cmpi.w	#$60,d0
		bcc.s	loc_203E
		move.w	(a0)+,(a1,d0.w)

loc_203E:
		addq.w	#2,d0
		dbf	d1,loc_202A
		move.w	($FFFFF632).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2054
		addq.w	#2,d0

loc_2054:
		cmpi.w	#$64,d0
		blt.s	loc_2062
		move.w	#$401,($FFFFF634).w
		moveq	#-$C,d0

loc_2062:
		move.w	d0,($FFFFF632).w
		moveq	#1,d0
		rts	
; ===========================================================================

loc_206A:				; XREF: loc_202A
		subq.b	#1,($FFFFF634).w
		bpl.s	loc_20BC
		move.b	#4,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0
		bcs.s	loc_2088
		moveq	#0,d0
		rts	
; ===========================================================================

loc_2088:				; XREF: loc_206A
		move.w	d0,($FFFFF632).w
		lea	(Pal_Sega2).l,a0
		lea	(a0,d0.w),a0
		lea	($FFFFFB04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	($FFFFFB20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1

loc_20A8:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_20B2
		addq.w	#2,d0

loc_20B2:
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbf	d1,loc_20A8

loc_20BC:
		moveq	#1,d0
		rts	
; End of function PalCycle_Sega

; ===========================================================================

Pal_Sega1:	incbin	pallet\sega1.bin
Pal_Sega2:	incbin	pallet\sega2.bin

; ---------------------------------------------------------------------------
; Subroutines to load pallets
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad1:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		adda.w	#$80,a3
		move.w	(a1)+,d7

loc_2110:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2110
		rts	
; End of function PalLoad1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad2:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		move.w	(a1)+,d7

loc_2128:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2128
		rts	
; End of function PalLoad2

; ---------------------------------------------------------------------------
; Underwater pallet loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad3_Water:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$80,a3
		move.w	(a1)+,d7

loc_2144:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2144
		rts	
; End of function PalLoad3_Water


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad4_Water:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$100,a3
		move.w	(a1)+,d7

loc_2160:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2160
		rts	
; End of function PalLoad4_Water

; ===========================================================================
; ---------------------------------------------------------------------------
; Pallet pointers
; ---------------------------------------------------------------------------
PalPointers:
	include "_inc\Pallet pointers.asm"

; ---------------------------------------------------------------------------
; Pallet data
; ---------------------------------------------------------------------------
Pal_Title:	incbin	pallet\title.bin
Pal_LevelSel:	incbin	pallet\levelsel.bin
Pal_Sonic:	incbin	pallet\sonic.bin
Pal_GHZ:	incbin	pallet\ghz.bin

; ---------------------------------------------------------------------------
; Subroutine to	delay the program by ($FFFFF62A) frames
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DelayProgram:				; XREF: PauseGame
		move	#$2300,sr

loc_29AC:
		tst.b	($FFFFF62A).w
		bne.s	loc_29AC
		rts	
; End of function DelayProgram

; ---------------------------------------------------------------------------
; Subroutine to	generate a pseudo-random number	in d0
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RandomNumber:
		move.l	($FFFFF636).w,d1
		bne.s	loc_29C0
		move.l	#$2A6D365A,d1

loc_29C0:
		move.l	d1,d0
		asl.l	#2,d1
		add.l	d0,d1
		asl.l	#3,d1
		add.l	d0,d1
		move.w	d1,d0
		swap	d1
		add.w	d1,d0
		move.w	d0,d1
		swap	d1
		move.l	d1,($FFFFF636).w
		rts	
; End of function RandomNumber


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


CalcSine:
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d1
		subi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d0
		rts	
; End of function CalcSine

; ===========================================================================

Sine_Data:	incbin	misc\sinewave.bin	; values for a 360� sine wave

; ===========================================================================
		movem.l	d1-d2,-(sp)
		move.w	d0,d1
		swap	d1
		moveq	#0,d0
		move.w	d0,d1
		moveq	#7,d2

loc_2C80:
		rol.l	#2,d1
		add.w	d0,d0
		addq.w	#1,d0
		sub.w	d0,d1
		bcc.s	loc_2C9A
		add.w	d0,d1
		subq.w	#1,d0
		dbf	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	
; ===========================================================================

loc_2C9A:
		addq.w	#1,d0
		dbf	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	

; -------------------------------------------------------------------------
; 2-argument arctangent (angle between (0,0) and (x,y))
; Based on http://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle
; -------------------------------------------------------------------------
; PARAMETERS:
;       d1.w - X value
;       d2.w - Y value
; RETURNS:
;       d0.b - 2-argument arctangent value (angle between (0,0) and (x,y))
; -------------------------------------------------------------------------

CalcAngle:
        moveq   #0,d0                           ; Default to bottom right quadrant
        tst.w   d1                              ; Is the X value negative?
        beq.s   CalcAngle_XZero                 ; If the X value is zero, branch
        bpl.s   CalcAngle_CheckY                ; If not, branch
        not.w   d1                              ; If so, get the absolute value
        moveq   #4,d0                           ; Shift to left quadrant
 
CalcAngle_CheckY:
        tst.w   d2                              ; Is the Y value negative?
        beq.s   CalcAngle_YZero                 ; If the Y value is zero, branch
        bpl.s   CalcAngle_CheckOctet            ; If not, branch
        not.w   d2                              ; If so, get the absolute value
        addq.b  #2,d0                           ; Shift to top quadrant

CalcAngle_CheckOctet:
        cmp.w   d2,d1                           ; Are we horizontally closer to the center?
        bcc.s   CalcAngle_Divide                ; If not, branch
        exg.l   d1,d2                           ; If so, divide Y from X instead
        addq.b  #1,d0                           ; Use octant that's horizontally closer to the center
 
CalcAngle_Divide:
        move.w  d1,-(sp)                        ; Shrink X and Y down into bytes
        moveq   #0,d3
        move.b  (sp)+,d3
        move.b  WordShiftTable(pc,d3.w),d3
        lsr.w   d3,d1
        lsr.w   d3,d2

        lea     Log2Table(pc),a2                ; Perform logarithmic division
        move.b  (a2,d2.w),d2
        sub.b   (a2,d1.w),d2
        bne.s   CalcAngle_GetAtan2Val
        move.w  #$FF,d2                         ; Edge case where X and Y values are too close for the division to handle

CalcAngle_GetAtan2Val:
        lea     Atan2Table(pc),a2               ; Get atan2 value
        move.b  (a2,d2.w),d2
        move.b  OctantAdjust(pc,d0.w),d0
        eor.b   d2,d0
        rts

; -------------------------------------------------------------------------

CalcAngle_YZero:
        tst.b   d0                              ; Was the X value negated?
        beq.s   CalcAngle_End                   ; If not, branch (d0 is already 0, so no need to set it again on branch)
        moveq   #$FFFFFF80,d0                   ; 180 degrees

CalcAngle_End:
        rts

CalcAngle_XZero:
        tst.w   d2                              ; Is the Y value negative?
        bmi.s   CalcAngle_XZeroYNeg             ; If so, branch
        moveq   #$40,d0                         ; 90 degrees
        rts

CalcAngle_XZeroYNeg:
        moveq   #$FFFFFFC0,d0                   ; 270 degrees
        rts
 
; -------------------------------------------------------------------------

OctantAdjust:
        dc.b    %00000000                       ; +X, +Y, |X|>|Y|
        dc.b    %00111111                       ; +X, +Y, |X|<|Y|
        dc.b    %11111111                       ; +X, -Y, |X|>|Y|
        dc.b    %11000000                       ; +X, -Y, |X|<|Y|
        dc.b    %01111111                       ; -X, +Y, |X|>|Y|
        dc.b    %01000000                       ; -X, +Y, |X|<|Y|
        dc.b    %10000000                       ; -X, -Y, |X|>|Y|
        dc.b    %10111111                       ; -X, -Y, |X|<|Y|

WordShiftTable:
        dc.b    $00, $01, $02, $02, $03, $03, $03, $03
        dc.b    $04, $04, $04, $04, $04, $04, $04, $04
        dc.b    $05, $05, $05, $05, $05, $05, $05, $05
        dc.b    $05, $05, $05, $05, $05, $05, $05, $05
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07

Log2Table:
        dc.b    $00, $00, $1F, $32, $3F, $49, $52, $59
        dc.b    $5F, $64, $69, $6E, $72, $75, $79, $7C
        dc.b    $7F, $82, $84, $87, $89, $8C, $8E, $90
        dc.b    $92, $94, $95, $97, $99, $9A, $9C, $9E
        dc.b    $9F, $A0, $A2, $A3, $A4, $A6, $A7, $A8
        dc.b    $A9, $AA, $AC, $AD, $AE, $AF, $B0, $B1
        dc.b    $B2, $B3, $B4, $B5, $B5, $B6, $B7, $B8
        dc.b    $B9, $BA, $BA, $BB, $BC, $BD, $BE, $BE
        dc.b    $BF, $C0, $C0, $C1, $C2, $C2, $C3, $C4
        dc.b    $C4, $C5, $C6, $C6, $C7, $C8, $C8, $C9
        dc.b    $C9, $CA, $CA, $CB, $CC, $CC, $CD, $CD
        dc.b    $CE, $CE, $CF, $CF, $D0, $D0, $D1, $D1
        dc.b    $D2, $D2, $D3, $D3, $D4, $D4, $D5, $D5
        dc.b    $D5, $D6, $D6, $D7, $D7, $D8, $D8, $D8
        dc.b    $D9, $D9, $DA, $DA, $DA, $DB, $DB, $DC
        dc.b    $DC, $DC, $DD, $DD, $DE, $DE, $DE, $DF
        dc.b    $DF, $DF, $E0, $E0, $E0, $E1, $E1, $E1
        dc.b    $E2, $E2, $E2, $E3, $E3, $E3, $E4, $E4
        dc.b    $E4, $E5, $E5, $E5, $E6, $E6, $E6, $E7
        dc.b    $E7, $E7, $E8, $E8, $E8, $E8, $E9, $E9
        dc.b    $E9, $EA, $EA, $EA, $EA, $EB, $EB, $EB
        dc.b    $EC, $EC, $EC, $EC, $ED, $ED, $ED, $ED
        dc.b    $EE, $EE, $EE, $EE, $EF, $EF, $EF, $F0
        dc.b    $F0, $F0, $F0, $F1, $F1, $F1, $F1, $F1
        dc.b    $F2, $F2, $F2, $F2, $F3, $F3, $F3, $F3
        dc.b    $F4, $F4, $F4, $F4, $F5, $F5, $F5, $F5
        dc.b    $F5, $F6, $F6, $F6, $F6, $F7, $F7, $F7
        dc.b    $F7, $F7, $F8, $F8, $F8, $F8, $F8, $F9
        dc.b    $F9, $F9, $F9, $F9, $FA, $FA, $FA, $FA
        dc.b    $FA, $FB, $FB, $FB, $FB, $FB, $FC, $FC
        dc.b    $FC, $FC, $FC, $FD, $FD, $FD, $FD, $FD
        dc.b    $FE, $FE, $FE, $FE, $FE, $FE, $FF, $FF

Atan2Table:
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $02, $02, $02, $02, $02, $02, $02
        dc.b    $02, $02, $02, $02, $02, $02, $02, $02
        dc.b    $02, $02, $02, $02, $02, $02, $02, $02
        dc.b    $03, $03, $03, $03, $03, $03, $03, $03
        dc.b    $03, $03, $03, $03, $03, $03, $03, $03
        dc.b    $04, $04, $04, $04, $04, $04, $04, $04
        dc.b    $04, $04, $04, $05, $05, $05, $05, $05
        dc.b    $05, $05, $05, $05, $05, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $07, $07, $07
        dc.b    $07, $07, $07, $08, $08, $08, $08, $08
        dc.b    $08, $09, $09, $09, $09, $09, $09, $0A
        dc.b    $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B
        dc.b    $0C, $0C, $0C, $0C, $0D, $0D, $0D, $0D
        dc.b    $0E, $0E, $0E, $0F, $0F, $0F, $0F, $10
        dc.b    $10, $10, $11, $11, $11, $12, $12, $12
        dc.b    $13, $13, $13, $14, $14, $14, $15, $15
        dc.b    $16, $16, $16, $17, $17, $17, $18, $18
        dc.b    $19, $19, $1A, $1A, $1A, $1B, $1B, $1C
        dc.b    $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F

; ===========================================================================

; ---------------------------------------------------------------------------
; Sega screen
; ---------------------------------------------------------------------------

SegaScreen:				; XREF: GameModeArray
		move.b	#$E4,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$8700,(a6)
		move.w	#$8B00,(a6)
		clr.b	($FFFFF64E).w
		move	#$2700,sr
		move.w	($FFFFF60C).w,d0
		andi.b	#$BF,d0
		move.w	d0,($C00004).l
		bsr.w	ClearScreen
		move.l	#$40000000,($C00004).l
		lea	(Nem_SegaLogo).l,a0 ; load Sega	logo patterns
		bsr.w	NemDec
		lea	($FF0000).l,a1
		lea	(Eni_SegaLogo).l,a0 ; load Sega	logo mappings
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FF0000).l,a1
		move.l	#$65100003,d0
		moveq	#$17,d1
		moveq	#7,d2
		bsr.w	ShowVDPGraphics
		lea	($FF0180).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
        lea	($FFFFFB80).l,a3
        moveq	#$3F,d7
 
@loop:
        move.w	#$EEE,(a3)+    ; move data to RAM
        dbf	d7,@loop
        bsr.w	Pal_FadeTo ; added to allow fade in
		move.w	#-$A,($FFFFF632).w
		move.w	#0,($FFFFF634).w
		move.w	#0,($FFFFF662).w
		move.w	#0,($FFFFF660).w
        move.b    #0,($FFFFFFD0).w
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l

Sega_WaitPallet:
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	PalCycle_Sega
		bne.s	Sega_WaitPallet

		move.b	#$E1,d0
		bsr.w	PlaySound_Special ; play "SEGA"	sound
		move.b	#$14,($FFFFF62A).w
		bsr.w	DelayProgram
		move.w	#$1E,($FFFFF614).w

Sega_WaitEnd:
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.w	($FFFFF614).w
		beq.s	Sega_GotoTitle
		andi.b	#$80,($FFFFF605).w ; is	Start button pressed?
		beq.s	Sega_WaitEnd	; if not, branch

Sega_GotoTitle:
		move.b	#ScnID_Title,($FFFFF600).w ; go to title screen
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Title	screen
; ---------------------------------------------------------------------------

TitleScreen:				; XREF: GameModeArray
		move.b	#$E4,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		move	#$2700,sr
		bsr.w	SoundDriverLoad
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		move.w	#$9200,(a6)
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)
		clr.b	($FFFFF64E).w
		bsr.w	ClearScreen
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Title_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Title_ClrObjRam ; fill object RAM ($D000-$EFFF) with	$0

		lea	($FFFFFB80).w,a1
		moveq	#0,d0
		move.w	#$1F,d1

Title_ClrPallet:
		move.l	d0,(a1)+
		dbf	d1,Title_ClrPallet ; fill pallet with 0	(black)
        move.b    #0,($FFFFFFD0).w
		bsr.w	Pal_FadeTo
		move	#$2700,sr
		move.l	#$40000001,($C00004).l
		lea	(Nem_TitleFg).l,a0 ; load title	screen patterns
		bsr.w	NemDec
		lea	($C00000).l,a6
		move.l	#$50000003,4(a6)
		lea	(Art_Text).l,a5
		move.w	#$28F,d1

Title_LoadText:
		move.w	(a5)+,(a6)
		dbf	d1,Title_LoadText ; load uncompressed text patterns

		move.b	#0,($FFFFFE30).w ; clear lamppost counter
		move.w	#0,($FFFFFE08).w ; disable debug item placement	mode
		move.w	#0,($FFFFFFF0).w ; disable debug mode
		move.w	#0,($FFFFFFEA).w
		move.w	#0,($FFFFFE10).w ; set level to	GHZ (00)
		move.w	#0,($FFFFF634).w ; disable pallet cycling
		move.b	#0,($FFFFF744).w
		bsr.w	Pal_FadeFrom
		move	#$2700,sr
		bsr.w	ClearScreen
		lea	($FF0000).l,a1
		lea	(Eni_Title).l,a0 ; load	title screen mappings
		move.w	#0,d0
		bsr.w	EniDec
		lea	($FF0000).l,a1
		move.l	#$42080003,d0
		moveq	#$21,d1
		moveq	#$15,d2
		bsr.w	ShowVDPGraphics
		moveq	#PalID_Title,d0		; load title screen pallet
		bsr.w	PalLoad1
		move.b	#$8A,d0		; play title screen music
		bsr.w	PlaySound_Special
		move.b	#0,($FFFFFFFA).w ; disable debug mode
		move.w	#$178,($FFFFF614).w ; run title	screen for $178	frames
		lea	($FFFFD080).w,a1
		moveq	#0,d0
		move.w	#$F,d1

Title_ClrObjRam2:
		move.l	d0,(a1)+
		dbf	d1,Title_ClrObjRam2
		moveq	#PLCID_Main1,d0
		bsr.w	LoadPLC2
		move.w	#0,($FFFFFFE4).w
		move.w	#0,($FFFFFFE6).w
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l
		bsr.w	Pal_FadeTo

loc_317C:
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	ObjectsLoad
		jsr	BuildSprites
		bsr.w	RunPLC_RAM
		tst.b	($FFFFFFF8).w	; check	if the machine is US or	Japanese
		bpl.s	Title_RegionJ	; if Japanese, branch
		lea	(LevelSelectCode_US).l,a0 ; load US code
		bra.s	Title_EnterCheat
; ===========================================================================

Title_RegionJ:				; XREF: Title_ChkRegion
		lea	(LevelSelectCode_J).l,a0 ; load	J code

Title_EnterCheat:			; XREF: Title_ChkRegion
		move.w	($FFFFFFE4).w,d0
		adda.w	d0,a0
		move.b	($FFFFF605).w,d0 ; get button press
		andi.b	#$F,d0		; read only up/down/left/right buttons
		cmp.b	(a0),d0		; does button press match the cheat code?
		bne.s	loc_3210	; if not, branch
		addq.w	#1,($FFFFFFE4).w ; next	button press
		tst.b	d0
		bne.s	Title_CountC
		lea	($FFFFFFE0).w,a0
		move.w	($FFFFFFE6).w,d1
		lsr.w	#1,d1
		andi.w	#3,d1
		beq.s	Title_PlayRing
		tst.b	($FFFFFFF8).w
		bpl.s	Title_PlayRing
		moveq	#1,d1
		move.b	d1,1(a0,d1.w)

Title_PlayRing:
		move.b	#1,(a0,d1.w)	; activate cheat
		move.b	#$B5,d0		; play ring sound when code is entered
		bsr.w	PlaySound_Special
		bra.s	Title_CountC
; ===========================================================================

loc_3210:				; XREF: Title_EnterCheat
		tst.b	d0
		beq.s	Title_CountC
		cmpi.w	#9,($FFFFFFE4).w
		beq.s	Title_CountC
		move.w	#0,($FFFFFFE4).w

Title_CountC:
		move.b	($FFFFF605).w,d0
		andi.b	#$20,d0		; is C button pressed?
		beq.s	loc_3230	; if not, branch
		addq.w	#1,($FFFFFFE6).w ; increment C button counter

loc_3230:
		andi.b	#$80,($FFFFF605).w ; check if Start is pressed
		beq.w	loc_317C	; if not, branch

Title_ChkLevSel:
		tst.b	($FFFFFFE0).w	; check	if level select	code is	on
		beq.w	PlayLevel	; if not, play level
		btst	#6,($FFFFF604).w ; check if A is pressed
		beq.w	PlayLevel	; if not, play level
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		moveq	#PalID_LevSel,d0
		bsr.w	PalLoad2	; load level select pallet
		lea	($FFFFCC00).w,a1
		moveq	#0,d0
		move.w	#$DF,d1

Title_ClrScroll:
		move.l	d0,(a1)+
		dbf	d1,Title_ClrScroll ; fill scroll data with 0

		move.l	d0,($FFFFF616).w
		move	#$2700,sr
		lea	($C00000).l,a6
		move.l	#$60000003,($C00004).l
		move.w	#$3FF,d1

Title_ClrVram:
		move.l	d0,(a6)
		dbf	d1,Title_ClrVram ; fill	VRAM with 0

		bsr.w	LevSelTextLoad

; ---------------------------------------------------------------------------
; Level	Select
; ---------------------------------------------------------------------------

LevelSelect:
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	LevSelControls
		bsr.w	RunPLC_RAM
		tst.l	($FFFFF680).w
		bne.s	LevelSelect
		andi.b	#$F0,($FFFFF605).w ; is	A, B, C, or Start pressed?
		beq.s	LevelSelect	; if not, branch
		move.w	($FFFFFF82).w,d0
		cmpi.w	#2,d0		; have you selected item $14 (sound test)?
		bne.s	LevSel_Level	; if not, go to	Level subroutine
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0
		cmpi.w	#$94,d0		; is sound $80-$94 being played?
		bcs.s	LevSel_PlaySnd	; if yes, branch
		cmpi.w	#$A0,d0		; is sound $95-$A0 being played?
		bcs.s	LevelSelect	; if yes, branch

LevSel_PlaySnd:
		bsr.w	PlaySound_Special
		bra.s	LevelSelect
; ===========================================================================

LevSel_Level:			; XREF: LevelSelect
		add.w	d0,d0
		move.w	LSelectPointers(pc,d0.w),d0 ; load level number
		bmi.w	LevelSelect
		andi.w	#$3FFF,d0
		move.w	d0,($FFFFFE10).w ; set level number

PlayLevel:
		move.b	#ScnID_Level,($FFFFF600).w ; set	screen mode to $0C (level)
		move.b	#3,($FFFFFE12).w ; set lives to	3
		moveq	#0,d0
		move.w	d0,($FFFFFE20).w ; clear rings
		move.l	d0,($FFFFFE22).w ; clear time
		move.l	d0,($FFFFFE26).w ; clear score
		move.b	#$E0,d0
		bsr.w	PlaySound_Special ; fade out music
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select - level pointers
; ---------------------------------------------------------------------------
LSelectPointers:
		incbin	misc\ls_point.bin
		even
; ---------------------------------------------------------------------------
; Level	select codes
; ---------------------------------------------------------------------------
LevelSelectCode_J:
		incbin	misc\ls_jcode.bin
		even

LevelSelectCode_US:
		incbin	misc\ls_ucode.bin
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	change what you're selecting in the level select
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelControls:				; XREF: LevelSelect
		move.b	($FFFFF605).w,d1
		andi.b	#3,d1		; is up/down pressed and held?
		bne.s	LevSel_UpDown	; if yes, branch
		subq.w	#1,($FFFFFF80).w ; subtract 1 from time	to next	move
		bpl.s	LevSel_SndTest	; if time remains, branch

LevSel_UpDown:
		move.w	#$B,($FFFFFF80).w ; reset time delay
		move.b	($FFFFF604).w,d1
		andi.b	#3,d1		; is up/down pressed?
		beq.s	LevSel_SndTest	; if not, branch
		move.w	($FFFFFF82).w,d0
		btst	#0,d1		; is up	pressed?
		beq.s	LevSel_Down	; if not, branch
		subq.w	#1,d0		; move up 1 selection
		bcc.s	LevSel_Down
		moveq	#2,d0		; if selection moves below 0, jump to selection	$14

LevSel_Down:
		btst	#1,d1		; is down pressed?
		beq.s	LevSel_Refresh	; if not, branch
		addq.w	#1,d0		; move down 1 selection
		cmpi.w	#3,d0
		bcs.s	LevSel_Refresh
		moveq	#0,d0		; if selection moves above $14,	jump to	selection 0

LevSel_Refresh:
		move.w	d0,($FFFFFF82).w ; set new selection
		bsr.w	LevSelTextLoad	; refresh text
		rts	
; ===========================================================================

LevSel_SndTest:				; XREF: LevSelControls
		cmpi.w	#2,($FFFFFF82).w ; is	item $14 selected?
		bne.s	LevSel_NoMove	; if not, branch
		move.b	($FFFFF605).w,d1
		andi.b	#$C,d1		; is left/right	pressed?
		beq.s	LevSel_NoMove	; if not, branch
		move.w	($FFFFFF84).w,d0
		btst	#2,d1		; is left pressed?
		beq.s	LevSel_Right	; if not, branch
		subq.w	#1,d0		; subtract 1 from sound	test
		bcc.s	LevSel_Right
		moveq	#$4F,d0		; if sound test	moves below 0, set to $4F

LevSel_Right:
		btst	#3,d1		; is right pressed?
		beq.s	LevSel_Refresh2	; if not, branch
		addq.w	#1,d0		; add 1	to sound test
		cmpi.w	#$50,d0
		bcs.s	LevSel_Refresh2
		moveq	#0,d0		; if sound test	moves above $4F, set to	0

LevSel_Refresh2:
		move.w	d0,($FFFFFF84).w ; set sound test number
		bsr.w	LevSelTextLoad	; refresh text

LevSel_NoMove:
		rts	
; End of function LevSelControls

; ---------------------------------------------------------------------------
; Subroutine to load level select text
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelTextLoad:				; XREF: TitleScreen
		lea	(LevelMenuText).l,a1
		lea	($C00000).l,a6
		move.l	#$62100003,d4	; screen position (text)
		move.w	#$E680,d3	; VRAM setting
		moveq	#2,d1		; number of lines of text

loc_34FE:				; XREF: LevSelTextLoad+26j
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine
		addi.l	#$800000,d4
		dbf	d1,loc_34FE
		moveq	#0,d0
		move.w	($FFFFFF82).w,d0
		move.w	d0,d1
		move.l	#$62100003,d4
		lsl.w	#7,d0
		swap	d0
		add.l	d0,d4
		lea	(LevelMenuText).l,a1
		lsl.w	#3,d1
		move.w	d1,d0
		add.w	d1,d1
		add.w	d0,d1
		adda.w	d1,a1
		move.w	#$C680,d3
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine
		move.w	#$E680,d3
		cmpi.w	#2,($FFFFFF82).w
		bne.s	loc_3550
		move.w	#$C680,d3

loc_3550:
		move.l	#$63300003,($C00004).l ; screen	position (sound	test)
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0
		move.b	d0,d2
		lsr.b	#4,d0
		bsr.w	LevSel_ChgSnd
		move.b	d2,d0
		bsr.w	LevSel_ChgSnd
		rts	
; End of function LevSelTextLoad


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgSnd:				; XREF: LevSelTextLoad
		andi.w	#$F,d0
		cmpi.b	#$A,d0
		bcs.s	loc_3580
		addi.b	#7,d0

loc_3580:
		add.w	d3,d0
		move.w	d0,(a6)
		rts	
; End of function LevSel_ChgSnd


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgLine:				; XREF: LevSelTextLoad
		moveq	#$17,d2		; number of characters per line

loc_3588:
		moveq	#0,d0
		move.b	(a1)+,d0
		bpl.s	loc_3598
		move.w	#0,(a6)
		dbf	d2,loc_3588
		rts	
; ===========================================================================

loc_3598:				; XREF: LevSel_ChgLine
		add.w	d3,d0
		move.w	d0,(a6)
		dbf	d2,loc_3588
		rts	
; End of function LevSel_ChgLine

; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select menu text
; ---------------------------------------------------------------------------
LevelMenuText:	incbin	misc\menutext.bin
		even
; ---------------------------------------------------------------------------
; Music	playlist
; ---------------------------------------------------------------------------
MusicList:	incbin	misc\muslist.bin
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

Level:					; XREF: GameModeArray
		bset	#7,($FFFFF600).w ; add $80 to screen mode (for pre level sequence)
		move.b    #0,($FFFFFFD0).w
		tst.w	($FFFFFFF0).w
		bmi.s	loc_37B6
		move.b	#$E0,d0
		bsr.w	PlaySound_Special ; fade out music

loc_37B6:
		bsr.w	ClearPLC
		bsr.w	Pal_FadeFrom
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ClrRam
		move	#$2700,sr
		move.l	#$70000002,($C00004).l
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		move	#$2300,sr
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_37FC
		bsr.w	LoadPLC		; load level patterns

loc_37FC:
		moveq	#PLCID_Main2,d0
		bsr.w	LoadPLC		; load standard	patterns

Level_ClrRam:
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Level_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrObjRam ; clear object RAM

		lea	($FFFFF628).w,a1
		moveq	#0,d0
		move.w	#$15,d1

Level_ClrVars:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars ; clear misc variables

		lea	($FFFFF700).w,a1
		moveq	#0,d0
		move.w	#$3F,d1

Level_ClrVars2:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars2 ; clear misc variables

		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$47,d1

Level_ClrVars3:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars3 ; clear object variables

		move	#$2700,sr
		bsr.w	ClearScreen
		lea	($C00004).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$857C,(a6)
		move.w	#$9001,(a6)
		move.w	#$8004,(a6)
		move.w	#$8720,(a6)
		move.w	#$8ADF,($FFFFF624).w
		move.w	($FFFFF624).w,(a6)
		ResetDMAQueue
; PUT WATER HEIGHT CHECK
		move.w	#$1E,($FFFFFE14).w
		move	#$2300,sr
		moveq	#PalID_Sonic,d0
		bsr.w	PalLoad2	; load Sonic's pallet line
; PUT WATER CHECK HERE LATER
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3946
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lea	(MusicList).l,a1 ; load	music playlist
		move.b	(a1,d0.w),d0	; add d0 to a1
		bsr.w	PlaySound	; play music
		move.b	#$34,($FFFFD080).w ; load title	card object

Level_TtlCard:
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	ObjectsLoad
		jsr	BuildSprites
		bsr.w	RunPLC_RAM
		move.w	($FFFFD108).w,d0
		cmp.w	($FFFFD130).w,d0 ; has title card sequence finished?
		bne.s	Level_TtlCard	; if not, branch
		tst.l	($FFFFF680).w	; are there any	items in the pattern load cue?
		bne.s	Level_TtlCard	; if yes, branch
		jsr	Hud_Base

loc_3946:
		moveq	#PalID_Sonic,d0
		bsr.w	PalLoad1	; load Sonic's pallet line
		bsr.w	LevelSizeLoad
		bsr.w	DeformBgLayer
		bset	#2,($FFFFF754).w
		bsr.w	LoadZoneTiles	; load level art
		bsr.w	MainLoadBlockLoad ; load block mappings	and pallets
		bsr.w	LoadTilesFromStart
		bsr.w	ColIndexLoad
		move.b	#1,($FFFFD000).w ; load	Sonic object
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ChkDebug
        move.b    #1,($FFFFFFD0).w

Level_ChkDebug:
		tst.b	($FFFFFFE2).w	; has debug cheat been entered?
		beq.s	Level_LoadObj	; if not, branch
		btst	#6,($FFFFF604).w ; is A	button pressed?
		beq.s	Level_LoadObj	; if not, branch
		move.b	#1,($FFFFFFFA).w ; enable debug	mode

Level_LoadObj:
		move.w	#0,($FFFFF602).w
		move.w	#0,($FFFFF604).w
		jsr	ObjPosLoad
		move.b	#0,(Rings_manager_routine).w
		jsr	RingsManager
		jsr	ObjectsLoad
		jsr	BuildSprites
		moveq	#0,d0
		tst.b	($FFFFFE30).w	; are you starting from	a lamppost?
		bne.s	loc_39E8	; if yes, branch
		move.w	d0,($FFFFFE20).w ; clear rings
		move.l	d0,($FFFFFE22).w ; clear time
		move.b	d0,($FFFFFE1B).w ; clear lives counter

loc_39E8:
		move.b	d0,($FFFFFE1A).w
		move.b	d0,($FFFFFE2C).w ; clear shield
		move.b	d0,($FFFFFE2D).w ; clear invincibility
		move.b	d0,($FFFFFE2E).w ; clear speed shoes
		move.b	d0,($FFFFFE2F).w
		move.w	d0,($FFFFFE08).w
		move.w	d0,($FFFFFE02).w
		move.w	d0,($FFFFFE04).w
		bsr.w	OscillateNumInit
		move.b	#1,($FFFFFE1F).w ; update score	counter
		move.b	#1,($FFFFFE1D).w ; update rings	counter
		move.b	#1,($FFFFFE1E).w ; update time counter
		move.w	#0,($FFFFF790).w
; PUT WATER CHECK HERE LATER
		move.w	#3,d1

Level_DelayLoop:
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		dbf	d1,Level_DelayLoop

		move.w	#$202F,($FFFFF626).w
		bsr.w	Pal_FadeTo2
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ClrCardArt
		addq.b	#2,($FFFFD0A4).w ; make	title card move
		addq.b	#4,($FFFFD0E4).w
		addq.b	#4,($FFFFD124).w
		addq.b	#4,($FFFFD164).w
		bra.s	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#PLCID_Explode,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		addi.w	#PLCID_GHZAnimals,d0
		jsr	(LoadPLC).l	; load animal patterns (level no. + $15)

Level_StartGame:
		bclr	#7,($FFFFF600).w ; subtract 80 from screen mode

; ---------------------------------------------------------------------------
; Main level loop (when	all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
        bsr.w    PauseGame
        move.b    #8,($FFFFF62A).w
        bsr.w    DelayProgram
        addq.w    #1,($FFFFFE04).w    ; add 1 to level timer
        jsr    ObjectsLoad
        tst.w    ($FFFFFE02).w    ; is the level set to restart?
        bne.w    Level        ; if yes, branch
        tst.w    ($FFFFFE08).w
        bne.s    loc_3B10
        cmpi.b    #6,($FFFFD024).w    ; is Sonic dying?
        bcc.s    loc_3B14        ; if yes, branch

loc_3B10:
        bsr.w    DeformBgLayer

loc_3B14:
        jsr    BuildSprites
        jsr    ObjPosLoad
		jsr	RingsManager
        bsr.w    PalCycle_Load
        bsr.w    RunPLC_RAM
        bsr.w    OscillateNumDo
        bsr.w    ChangeRingFrame
        bsr.w    SignpostArtLoad
        cmpi.b    #ScnID_Level,($FFFFF600).w
        beq.w    Level_MainLoop    ; if screen mode is $0C    (level), branch
        rts            ; quit
; ===========================================================================

WaterTransition_LZ:    dc.w $13    ; # of entries - 1
        dc.w $62
        dc.w $68
        dc.w $7A
        dc.w $6E
        dc.w $74
        dc.w $42
        dc.w $48
        dc.w $4E
        dc.w $54
        dc.w $5A
        dc.w 2
        dc.w 8
        dc.w $E
        dc.w $14
        dc.w $1A
        dc.w $34
        dc.w $22
        dc.w $3A
        dc.w $2E
        dc.w $28

; ---------------------------------------------------------------------------
; Collision index loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColIndexLoad:				; XREF: Level
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lsl.w	#$03,d0					; MJ: multiply by 8 not 4
		move.l	ColPointers(pc,d0.w),($FFFFFFD0).w	; MJ: get first collision set
		add.w	#$04,d0					; MJ: increase to next location
		move.l	ColPointers(pc,d0.w),($FFFFFFD4).w	; MJ: get second collision set
		rts	
; End of function ColIndexLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision index pointers
; ---------------------------------------------------------------------------
ColPointers:
	include "_inc\Collision index pointers.asm"

; ---------------------------------------------------------------------------
; Oscillating number subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumInit:			; XREF: Level
		lea	($FFFFFE5E).w,a1
		lea	(Osc_Data).l,a2
		moveq	#$20,d1

Osc_Loop:
		move.w	(a2)+,(a1)+
		dbf	d1,Osc_Loop
		rts	
; End of function OscillateNumInit

; ===========================================================================
Osc_Data:	dc.w $7C, $80		; baseline values
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$50F0
		dc.w $11E, $2080
		dc.w $B4, $3080
		dc.w $10E, $5080
		dc.w $1C2, $7080
		dc.w $276, $80
		dc.w 0,	$80
		dc.w 0
		even

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumDo:				; XREF: Level
		cmpi.b	#6,($FFFFD024).w
		bcc.s	locret_41C4
		lea	($FFFFFE5E).w,a1
		lea	(Osc_Data2).l,a2
		move.w	(a1)+,d3
		moveq	#$F,d1

loc_4184:
		move.w	(a2)+,d2
		move.w	(a2)+,d4
		btst	d1,d3
		bne.s	loc_41A4
		move.w	2(a1),d0
		add.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bhi.s	loc_41BA
		bset	d1,d3
		bra.s	loc_41BA
; ===========================================================================

loc_41A4:				; XREF: OscillateNumDo
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bls.s	loc_41BA
		bclr	d1,d3

loc_41BA:
		addq.w	#4,a1
		dbf	d1,loc_4184
		move.w	d3,($FFFFFE5E).w

locret_41C4:
		rts	
; End of function OscillateNumDo

; ===========================================================================
Osc_Data2:	dc.w 2,	$10		; XREF: OscillateNumDo
		dc.w 2,	$18
		dc.w 2,	$20
		dc.w 2,	$30
		dc.w 4,	$20
		dc.w 8,	8
		dc.w 8,	$40
		dc.w 4,	$40
		dc.w 2,	$50
		dc.w 2,	$50
		dc.w 2,	$20
		dc.w 3,	$30
		dc.w 5,	$50
		dc.w 7,	$70
		dc.w 2,	$10
		dc.w 2,	$10
		even

; ---------------------------------------------------------------------------
; Subroutine to	change object animation	variables (rings, giant	rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChangeRingFrame:			; XREF: Level
		cmp.b	#6,($FFFFD000+Obj_Routine).w
		bge.s	locret_4272
		subq.b	#1,($FFFFFEC0).w
		bpl.s	loc_421C
		move.b	#$B,($FFFFFEC0).w
		subq.b	#1,($FFFFFEC1).w
		andi.b	#7,($FFFFFEC1).w

loc_421C:
		subq.b	#1,($FFFFFEC2).w
		bpl.s	loc_4232
		move.b	#7,($FFFFFEC2).w
		addq.b	#1,($FFFFFEC3).w
		andi.b	#3,($FFFFFEC3).w

loc_4232:
		subq.b	#1,($FFFFFEC4).w
		bpl.s	loc_4250
		move.b	#7,($FFFFFEC4).w
		addq.b	#1,($FFFFFEC5).w
		cmpi.b	#6,($FFFFFEC5).w
		bcs.s	loc_4250
		move.b	#0,($FFFFFEC5).w

loc_4250:
		tst.b	($FFFFFEC6).w
		beq.s	locret_4272
		moveq	#0,d0
		move.b	($FFFFFEC6).w,d0
		add.w	($FFFFFEC8).w,d0
		move.w	d0,($FFFFFEC8).w
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,($FFFFFEC7).w
		subq.b	#1,($FFFFFEC6).w

locret_4272:
		rts	
; End of function ChangeRingFrame

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SignpostArtLoad:			; XREF: Level
		tst.w	($FFFFFE08).w	; is debug mode	being used?
		bne.w	Signpost_Exit	; if yes, branch
		cmpi.b	#2,($FFFFFE11).w ; is act number 02 (act 3)?
		beq.s	Signpost_Exit	; if yes, branch
		move.w	($FFFFF700).w,d0
		move.w	($FFFFF72A).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0		; has Sonic reached the	edge of	the level?
		blt.s	Signpost_Exit	; if not, branch
		tst.b	($FFFFFE1E).w
		beq.s	Signpost_Exit
		cmp.w	($FFFFF728).w,d1
		beq.s	Signpost_Exit
		move.w	d1,($FFFFF728).w ; move	left boundary to current screen	position
		moveq	#PLCID_LevelEnd,d0
		bra.w	LoadPLC2	; load signpost	patterns
; ===========================================================================

Signpost_Exit:
		rts	
; End of function SignpostArtLoad

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	load level boundaries and start	locations
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelSizeLoad:				; XREF: TitleScreen; Level
		moveq	#0,d0
		move.b	d0,($FFFFF740).w
		move.b	d0,($FFFFF741).w
		move.b	d0,($FFFFF746).w
		move.b	d0,($FFFFF748).w
		move.b	d0,($FFFFF742).w
		move.w	($FFFFFE10).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	LevelSizeArray(pc,d0.w),a0 ; load level	boundaries
		move.w	(a0)+,d0
		move.w	d0,($FFFFF730).w
		move.l	(a0)+,d0
		move.l	d0,($FFFFF728).w
		move.l	d0,($FFFFF720).w
		move.l	(a0)+,d0
		move.l	d0,($FFFFF72C).w
		move.l	d0,($FFFFF724).w
		move.w	($FFFFF728).w,d0
		addi.w	#$240,d0
		move.w	d0,($FFFFF732).w
		move.w	#$1010,($FFFFF74A).w
		move.w	(a0)+,d0
		move.w	d0,($FFFFF73E).w
		bra.w	LevSz_ChkLamp
; ===========================================================================
; ---------------------------------------------------------------------------
; Level size array and start location array
; ---------------------------------------------------------------------------
LevelSizeArray:
        dc.w $0004, $0000, $24BF, $0000, $0300, $0060 ; Act 1
        dc.w $0004, $0000, $1EBF, $0000, $0300, $0060 ; Act 2
		even

; ===========================================================================

LevSz_ChkLamp:				; XREF: LevelSizeLoad
		tst.b	($FFFFFE30).w	; have any lampposts been hit?
		beq.s	LevSz_StartLoc	; if not, branch
		jsr	Obj79_LoadInfo
		move.w	($FFFFD008).w,d1
		move.w	($FFFFD00C).w,d0
		bra.s	loc_60D0
; ===========================================================================

LevSz_StartLoc:				; XREF: LevelSizeLoad
		move.w	($FFFFFE10).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(StartLocArray).l,a1			; MJ: load location array
		lea	(a1,d0.w),a1				; MJ: load Sonic's start location address

LevSz_SonicPos:
		moveq	#0,d1
		move.w	(a1)+,d1
		move.w	d1,($FFFFD008).w ; set Sonic's position on x-axis
		moveq	#0,d0
		move.w	(a1),d0
		move.w	d0,($FFFFD00C).w ; set Sonic's position on y-axis
		move.b	($FFFFF600).w,d2			; MJ: load game mode
		andi.w	#$00FC,d2				; MJ: keep in range
		cmpi.b	#$04,d2					; MJ: is screen mode at title?
		bne	loc_60D0				; MJ: if not, branch
		move.w	#$0050,d1				; MJ: set positions for title screen
		move.w	#$03B0,d0				; MJ: ''
		move.w	d1,($FFFFD008).w			; MJ: save to object 1 so title screen follows
		move.w	d0,($FFFFD00C).w			; MJ: ''

loc_60D0:				; XREF: LevSz_ChkLamp
		clr.w	($FFFFF7A8).w		; reset Sonic's position tracking index
		lea	($FFFFCB00).w,a2	; load the tracking array into a2
		moveq	#63,d2				; begin a 64-step loop
@looppoint:
		move.w	d1,(a2)+			; fill in X
		move.w	d0,(a2)+			; fill in Y
		dbf	d2,@looppoint		; loop
		subi.w	#$A0,d1
		bcc.s	loc_60D8
		moveq	#0,d1

loc_60D8:
		move.w	($FFFFF72A).w,d2
		cmp.w	d2,d1
		bcs.s	loc_60E2
		move.w	d2,d1

loc_60E2:
		move.w	d1,($FFFFF700).w
		subi.w	#$60,d0
		bcc.s	loc_60EE
		moveq	#0,d0

loc_60EE:
		cmp.w	($FFFFF72E).w,d0
		blt.s	loc_60F8
		move.w	($FFFFF72E).w,d0

loc_60F8:
		move.w	d0,($FFFFF704).w
		bsr.w	BgScrollSpeed
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lsl.b	#2,d0
		bra.w	LevSz_Unk

; ===========================================================================
; ---------------------------------------------------------------------------
; MJ: Sonic start location array
; ---------------------------------------------------------------------------

StartLocArray:	incbin	startpos\ghz1.bin
		incbin	startpos\ghz2.bin
		even

; ===========================================================================

LevSz_Unk:				; XREF: LevelSizeLoad
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lsl.w	#3,d0
		lea	dword_61B4(pc,d0.w),a1
		lea	($FFFFF7F0).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		rts	
; End of function LevelSizeLoad

; ===========================================================================
dword_61B4:	dc.l $700100, $1000100
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $700100, $1000100

; ---------------------------------------------------------------------------
; Subroutine to	set scroll speed of some backgrounds
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BgScrollSpeed:				; XREF: LevelSizeLoad
		tst.b	($FFFFFE30).w
		bne.s	loc_6206
		move.w	d0,($FFFFF70C).w
		move.w	d0,($FFFFF714).w
		move.w	d1,($FFFFF708).w
		move.w	d1,($FFFFF710).w
		move.w	d1,($FFFFF718).w

loc_6206:
		moveq	#0,d2
		move.b	($FFFFFE10).w,d2
		add.w	d2,d2
		move.w	BgScroll_Index(pc,d2.w),d2
		jmp	BgScroll_Index(pc,d2.w)
; End of function BgScrollSpeed

; ===========================================================================
BgScroll_Index:	dc.w BgScroll_GHZ-BgScroll_Index, BgScroll_LZ-BgScroll_Index
		dc.w BgScroll_MZ-BgScroll_Index, BgScroll_SLZ-BgScroll_Index
		dc.w BgScroll_SYZ-BgScroll_Index, BgScroll_SBZ-BgScroll_Index
		dc.w BgScroll_End-BgScroll_Index
; ===========================================================================

BgScroll_GHZ:				; XREF: BgScroll_Index
		bra.w	Deform_GHZ
; ===========================================================================

BgScroll_LZ:				; XREF: BgScroll_Index
		asr.l	#1,d0
		move.w	d0,($FFFFF70C).w
		rts	
; ===========================================================================

BgScroll_MZ:				; XREF: BgScroll_Index
		rts	
; ===========================================================================

BgScroll_SLZ:				; XREF: BgScroll_Index
		asr.l	#1,d0
		addi.w	#$C0,d0
		move.w	d0,($FFFFF70C).w
		rts	
; ===========================================================================

BgScroll_SYZ:				; XREF: BgScroll_Index
		asl.l	#4,d0
		move.l	d0,d2
		asl.l	#1,d0
		add.l	d2,d0
		asr.l	#8,d0
		move.w	d0,($FFFFF70C).w
		move.w	d0,($FFFFF714).w
		rts	
; ===========================================================================

BgScroll_SBZ:				; XREF: BgScroll_Index
		asl.l	#4,d0
		asl.l	#1,d0
		asr.l	#8,d0
		move.w	d0,($FFFFF70C).w
		rts	
; ===========================================================================

BgScroll_End:				; XREF: BgScroll_Index
		move.w	#$1E,($FFFFF70C).w
		move.w	#$1E,($FFFFF714).w
		rts	
; ===========================================================================
		move.w	#$A8,($FFFFF708).w
		move.w	#$1E,($FFFFF70C).w
		move.w	#-$40,($FFFFF710).w
		move.w	#$1E,($FFFFF714).w
		rts

; ---------------------------------------------------------------------------
; Background layer deformation subroutines
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DeformBgLayer:				; XREF: TitleScreen; Level
		tst.b	($FFFFF744).w
		beq.s	loc_628E
		rts	
; ===========================================================================

loc_628E:
		clr.w	($FFFFF754).w
		clr.w	($FFFFF756).w
		clr.w	($FFFFF758).w
		clr.w	($FFFFF75A).w
		bsr.w	ScrollHoriz
		bsr.w	ScrollVertical
		bsr.w	DynScrResizeLoad
		move.w	($FFFFF700).w,($FFFFF61A).w
		move.w	($FFFFF704).w,($FFFFF616).w
		move.w	($FFFFF708).w,($FFFFF61C).w
		move.w	($FFFFF70C).w,($FFFFF618).w
		move.w	($FFFFF718).w,($FFFFF620).w
		move.w	($FFFFF71C).w,($FFFFF61E).w
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		add.w	d0,d0
		move.w	Deform_Index(pc,d0.w),d0
		jmp	Deform_Index(pc,d0.w)
; End of function DeformBgLayer

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for background layer deformation	code
; ---------------------------------------------------------------------------
Deform_Index:	dc.w Deform_GHZ-Deform_Index, Deform_LZ-Deform_Index
		dc.w Deform_MZ-Deform_Index, Deform_SLZ-Deform_Index
		dc.w Deform_SYZ-Deform_Index, Deform_SBZ-Deform_Index
		dc.w Deform_GHZ-Deform_Index
; ---------------------------------------------------------------------------
; Green	Hill Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_GHZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#5,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d5
		bsr.w	ScrollBlock1
		bsr.w	ScrollBlock4
		lea	($FFFFCC00).w,a1
		move.w	($FFFFF704).w,d0
		andi.w	#$7FF,d0
		lsr.w	#5,d0
		neg.w	d0
		addi.w	#$26,d0
		move.w	d0,($FFFFF714).w
		move.w	d0,d4
		bsr.w	ScrollBlock3
		move.w	($FFFFF70C).w,($FFFFF618).w
		move.w	#$6F,d1
		sub.w	d4,d1
		move.w	($FFFFF700).w,d0
		cmpi.b	#ScnID_Title,($FFFFF600).w
		bne.s	loc_633C
		moveq	#0,d0

loc_633C:
		neg.w	d0
		swap	d0
		move.w	($FFFFF708).w,d0
		neg.w	d0

loc_6346:
		move.l	d0,(a1)+
		dbf	d1,loc_6346
		move.w	#$27,d1
		move.w	($FFFFF710).w,d0
		neg.w	d0

loc_6356:
		move.l	d0,(a1)+
		dbf	d1,loc_6356
		move.w	($FFFFF710).w,d0
		addi.w	#0,d0
		move.w	($FFFFF700).w,d2
		addi.w	#-$200,d2
		sub.w	d0,d2
		ext.l	d2
		asl.l	#8,d2
		divs.w	#$68,d2
		ext.l	d2
		asl.l	#8,d2
		moveq	#0,d3
		move.w	d0,d3
		move.w	#$47,d1
		add.w	d4,d1

loc_6384:
		move.w	d3,d0
		neg.w	d0
		move.l	d0,(a1)+
		swap	d3
		add.l	d2,d3
		swap	d3
		dbf	d1,loc_6384
		rts	
; End of function Deform_GHZ

; ---------------------------------------------------------------------------
; Labyrinth Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_LZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#7,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	ScrollBlock1
		move.w	($FFFFF70C).w,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	($FFFFF700).w,d0
		neg.w	d0
		swap	d0
		move.w	($FFFFF708).w,d0
		neg.w	d0

loc_63C6:
		move.l	d0,(a1)+
		dbf	d1,loc_63C6
		move.w	($FFFFF646).w,d0
		sub.w	($FFFFF704).w,d0
		rts	
; End of function Deform_LZ

; ---------------------------------------------------------------------------
; Marble Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_MZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d5
		bsr.w	ScrollBlock1
		move.w	#$200,d0
		move.w	($FFFFF704).w,d1
		subi.w	#$1C8,d1
		bcs.s	loc_6402
		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1
		asr.w	#2,d1
		add.w	d1,d0

loc_6402:
		move.w	d0,($FFFFF714).w
		bsr.w	ScrollBlock3
		move.w	($FFFFF70C).w,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	($FFFFF700).w,d0
		neg.w	d0
		swap	d0
		move.w	($FFFFF708).w,d0
		neg.w	d0

loc_6426:
		move.l	d0,(a1)+
		dbf	d1,loc_6426
		rts	
; End of function Deform_MZ

; ---------------------------------------------------------------------------
; Star Light Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SLZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#7,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	ScrollBlock2
		move.w	($FFFFF70C).w,($FFFFF618).w
		bsr.w	Deform_SLZ_2
		lea	($FFFFA800).w,a2
		move.w	($FFFFF70C).w,d0
		move.w	d0,d2
		subi.w	#$C0,d0
		andi.w	#$3F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
		lea	($FFFFCC00).w,a1
		move.w	#$E,d1
		move.w	($FFFFF700).w,d0
		neg.w	d0
		swap	d0
		andi.w	#$F,d2
		add.w	d2,d2
		move.w	(a2)+,d0
		jmp	loc_6482(pc,d2.w)
; ===========================================================================

loc_6480:				; XREF: Deform_SLZ
		move.w	(a2)+,d0

loc_6482:
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbf	d1,loc_6480
		rts	
; End of function Deform_SLZ


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SLZ_2:				; XREF: Deform_SLZ
		lea	($FFFFA800).w,a1
		move.w	($FFFFF700).w,d2
		neg.w	d2
		move.w	d2,d0
		asr.w	#3,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#4,d0
		divs.w	#$1C,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		move.w	#$1B,d1

loc_64CE:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,loc_64CE
		move.w	d2,d0
		asr.w	#3,d0
		move.w	#4,d1

loc_64E2:
		move.w	d0,(a1)+
		dbf	d1,loc_64E2
		move.w	d2,d0
		asr.w	#2,d0
		move.w	#4,d1

loc_64F0:
		move.w	d0,(a1)+
		dbf	d1,loc_64F0
		move.w	d2,d0
		asr.w	#1,d0
		move.w	#$1D,d1

loc_64FE:
		move.w	d0,(a1)+
		dbf	d1,loc_64FE
		rts	
; End of function Deform_SLZ_2

; ---------------------------------------------------------------------------
; Spring Yard Zone background layer deformation	code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SYZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#4,d5
		move.l	d5,d1
		asl.l	#1,d5
		add.l	d1,d5
		bsr.w	ScrollBlock1
		move.w	($FFFFF70C).w,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	($FFFFF700).w,d0
		neg.w	d0
		swap	d0
		move.w	($FFFFF708).w,d0
		neg.w	d0

loc_653C:
		move.l	d0,(a1)+
		dbf	d1,loc_653C
		rts	
; End of function Deform_SYZ

; ---------------------------------------------------------------------------
; Scrap	Brain Zone background layer deformation	code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SBZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#4,d5
		asl.l	#1,d5
		bsr.w	ScrollBlock1
		move.w	($FFFFF70C).w,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	($FFFFF700).w,d0
		neg.w	d0
		swap	d0
		move.w	($FFFFF708).w,d0
		neg.w	d0

loc_6576:
		move.l	d0,(a1)+
		dbf	d1,loc_6576
		rts	
; End of function Deform_SBZ

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level horizontally as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz:				; XREF: DeformBgLayer
		move.w	($FFFFF700).w,d4
		bsr.s	ScrollHoriz2
		move.w	($FFFFF700).w,d0
		andi.w	#$10,d0
		move.b	($FFFFF74A).w,d1
		eor.b	d1,d0
		bne.s	locret_65B0
		eori.b	#$10,($FFFFF74A).w
		move.w	($FFFFF700).w,d0
		sub.w	d4,d0
		bpl.s	loc_65AA
		bset	#2,($FFFFF754).w
		rts	
; ===========================================================================

loc_65AA:
		bset	#3,($FFFFF754).w

locret_65B0:
		rts	
; End of function ScrollHoriz


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz2:				; XREF: ScrollHoriz
		move.w	($FFFFC904).w,d1
		beq.s	@cont1
		sub.w	#$100,d1
		move.w	d1,($FFFFC904).w
		moveq	#0,d1
		move.b	($FFFFC904).w,d1
		lsl.b	#2,d1
		addq.b	#4,d1
		move.w	($FFFFF7A8).w,d0
		sub.b	d1,d0
		lea	($FFFFCB00).w,a1
		move.w	(a1,d0.w),d0
		and.w	#$3FFF,d0
		bra.s	@cont2
		
@cont1:
		move.w	($FFFFD008).w,d0
		
@cont2:
		sub.w	($FFFFF700).w,d0
		subi.w	#$90,d0
		bmi.s	loc_65F6				; cs to mi (for negative)
		subi.w	#$10,d0
		bpl.s	loc_65CC				; cc to pl (for negative)
		clr.w	($FFFFF73A).w
		rts
; ===========================================================================

loc_65CC:
		cmpi.w	#$10,d0
		bcs.s	loc_65D6
		move.w	#$10,d0

loc_65D6:
		add.w	($FFFFF700).w,d0
		cmp.w	($FFFFF72A).w,d0
		blt.s	loc_65E4
		move.w	($FFFFF72A).w,d0

loc_65E4:
		move.w	d0,d1
		sub.w	($FFFFF700).w,d1
		asl.w	#8,d1
		move.w	d0,($FFFFF700).w
		move.w	d1,($FFFFF73A).w
		rts	
; ===========================================================================

loc_65F6:				; XREF: ScrollHoriz2
		cmpi.w	#-$10,d0
		bgt.s	@cont
		move.w	#-$10,d0	
		
@cont:
		add.w	($FFFFF700).w,d0
		cmp.w	($FFFFF728).w,d0
		bgt.s	loc_65E4
		move.w	($FFFFF728).w,d0
		bra.s	loc_65E4
; End of function ScrollHoriz2

; ===========================================================================
		tst.w	d0
		bpl.s	loc_6610
		move.w	#-2,d0
		bra.s	loc_65F6
; ===========================================================================

loc_6610:
		move.w	#2,d0
		bra.s	loc_65CC

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level vertically as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollVertical:				; XREF: DeformBgLayer
		moveq	#0,d1
		move.w	($FFFFD00C).w,d0
		sub.w	($FFFFF704).w,d0
		btst	#2,($FFFFD022).w
		beq.s	loc_662A
		subq.w	#5,d0

loc_662A:
		btst	#1,($FFFFD022).w
		beq.s	loc_664A
		addi.w	#$20,d0
		sub.w	($FFFFF73E).w,d0
		bcs.s	loc_6696
		subi.w	#$40,d0
		bcc.s	loc_6696
		tst.b	($FFFFF75C).w
		bne.s	loc_66A8
		bra.s	loc_6656
; ===========================================================================

loc_664A:
		sub.w	($FFFFF73E).w,d0
		bne.s	loc_665C
		tst.b	($FFFFF75C).w
		bne.s	loc_66A8

loc_6656:
		clr.w	($FFFFF73C).w
		rts	
; ===========================================================================

loc_665C:
		cmpi.w	#$60,($FFFFF73E).w
		bne.s	loc_6684
		move.w	($FFFFD000+Obj_Inertia).w,d1
		bpl.s	loc_666C
		neg.w	d1

loc_666C:
		cmpi.w	#$800,d1
		bcc.s	loc_6696
		move.w	#$600,d1
		cmpi.w	#6,d0
		bgt.s	loc_66F6
		cmpi.w	#-6,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6684:
		move.w	#$200,d1
		cmpi.w	#2,d0
		bgt.s	loc_66F6
		cmpi.w	#-2,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6696:
		move.w	#$1000,d1
		cmpi.w	#$10,d0
		bgt.s	loc_66F6
		cmpi.w	#-$10,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_66A8:
		moveq	#0,d0
		move.b	d0,($FFFFF75C).w

loc_66AE:
		moveq	#0,d1
		move.w	d0,d1
		add.w	($FFFFF704).w,d1
		tst.w	d0
		bpl.w	loc_6700
		bra.w	loc_66CC
; ===========================================================================

loc_66C0:
		neg.w	d1
		ext.l	d1
		asl.l	#8,d1
		add.l	($FFFFF704).w,d1
		swap	d1

loc_66CC:
		cmp.w	($FFFFF72C).w,d1
		bgt.s	loc_6724
		cmpi.w	#-$100,d1
		bgt.s	loc_66F0
		andi.w	#$7FF,d1
		andi.w	#$7FF,($FFFFD00C).w
		andi.w	#$7FF,($FFFFF704).w
		andi.w	#$3FF,($FFFFF70C).w
		bra.s	loc_6724
; ===========================================================================

loc_66F0:
		move.w	($FFFFF72C).w,d1
		bra.s	loc_6724
; ===========================================================================

loc_66F6:
		ext.l	d1
		asl.l	#8,d1
		add.l	($FFFFF704).w,d1
		swap	d1

loc_6700:
		cmp.w	($FFFFF72E).w,d1
		blt.s	loc_6724
		subi.w	#$800,d1
		bcs.s	loc_6720
		andi.w	#$7FF,($FFFFD00C).w
		subi.w	#$800,($FFFFF704).w
		andi.w	#$3FF,($FFFFF70C).w
		bra.s	loc_6724
; ===========================================================================

loc_6720:
		move.w	($FFFFF72E).w,d1

loc_6724:
		move.w	($FFFFF704).w,d4
		swap	d1
		move.l	d1,d3
		sub.l	($FFFFF704).w,d3
		ror.l	#8,d3
		move.w	d3,($FFFFF73C).w
		move.l	d1,($FFFFF704).w
		move.w	($FFFFF704).w,d0
		andi.w	#$10,d0
		move.b	($FFFFF74B).w,d1
		eor.b	d1,d0
		bne.s	locret_6766
		eori.b	#$10,($FFFFF74B).w
		move.w	($FFFFF704).w,d0
		sub.w	d4,d0
		bpl.s	loc_6760
		bset	#0,($FFFFF754).w
		rts	
; ===========================================================================

loc_6760:
		bset	#1,($FFFFF754).w

locret_6766:
		rts	
; End of function ScrollVertical


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock1:				; XREF: Deform_GHZ; et al
		move.l	($FFFFF708).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,($FFFFF708).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74C).w,d3
		eor.b	d3,d1
		bne.s	loc_679C
		eori.b	#$10,($FFFFF74C).w
		sub.l	d2,d0
		bpl.s	loc_6796
		bset	#2,($FFFFF756).w
		bra.s	loc_679C
; ===========================================================================

loc_6796:
		bset	#3,($FFFFF756).w

loc_679C:
		move.l	($FFFFF70C).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,($FFFFF70C).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	locret_67D0
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.s	loc_67CA
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_67CA:
		bset	#1,($FFFFF756).w

locret_67D0:
		rts	
; End of function ScrollBlock1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock2:				; XREF: Deform_SLZ
		move.l	($FFFFF708).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,($FFFFF708).w
		move.l	($FFFFF70C).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,($FFFFF70C).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	locret_6812
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.s	loc_680C
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_680C:
		bset	#1,($FFFFF756).w

locret_6812:
		rts	
; End of function ScrollBlock2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock3:				; XREF: Deform_GHZ; et al
		move.w	($FFFFF70C).w,d3
		move.w	d0,($FFFFF70C).w
		move.w	d0,d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	locret_6842
		eori.b	#$10,($FFFFF74D).w
		sub.w	d3,d0
		bpl.s	loc_683C
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_683C:
		bset	#1,($FFFFF756).w

locret_6842:
		rts	
; End of function ScrollBlock3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock4:				; XREF: Deform_GHZ
		move.w	($FFFFF710).w,d2
		move.w	($FFFFF714).w,d3
		move.w	($FFFFF73A).w,d0
		ext.l	d0
		asl.l	#7,d0
		add.l	d0,($FFFFF710).w
		move.w	($FFFFF710).w,d0
		andi.w	#$10,d0
		move.b	($FFFFF74E).w,d1
		eor.b	d1,d0
		bne.s	locret_6884
		eori.b	#$10,($FFFFF74E).w
		move.w	($FFFFF710).w,d0
		sub.w	d2,d0
		bpl.s	loc_687E
		bset	#2,($FFFFF758).w
		bra.s	locret_6884
; ===========================================================================

loc_687E:
		bset	#3,($FFFFF758).w

locret_6884:
		rts	
; End of function ScrollBlock4


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6886:				; XREF: loc_C44
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	($FFFFF756).w,a2
		lea	($FFFFF708).w,a3
		movea.l	($FFFFA404).w,a4			; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	sub_6954
		lea	($FFFFF758).w,a2
		lea	($FFFFF710).w,a3
		bra.w	sub_69F4
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to	display	correct	tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesAsYouMove:			; XREF: VInt_UpdateArt
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	($FFFFFF32).w,a2
		lea	($FFFFFF18).w,a3
		movea.l	($FFFFA404).w,a4			; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	sub_6954
		lea	($FFFFFF34).w,a2
		lea	($FFFFFF20).w,a3
		bsr.w	sub_69F4
		lea	($FFFFFF30).w,a2
		lea	($FFFFFF10).w,a3
		movea.l	($FFFFA400).w,a4			; MJ: Load address of layout
		move.w	#$4000,d2
		tst.b	(a2)
		beq.s	locret_6952
		bclr	#0,(a2)
		beq.s	loc_6908
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6AD8

loc_6908:
		bclr	#1,(a2)
		beq.s	loc_6922
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6AD8

loc_6922:
		bclr	#2,(a2)
		beq.s	loc_6938
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6B04

loc_6938:
		bclr	#3,(a2)
		beq.s	locret_6952
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	sub_6B04

locret_6952:
		rts	
; End of function LoadTilesAsYouMove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6954:				; XREF: sub_6886; LoadTilesAsYouMove
		tst.b	(a2)
		beq.w	locret_69F2
		bclr	#0,(a2)
		beq.s	loc_6972
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA

loc_6972:
		bclr	#1,(a2)
		beq.s	loc_698E
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	#$E0,d4
		moveq	#-$10,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA

loc_698E:
		bclr	#2,(a2)
		beq.s	loc_69BE
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.s	loc_69BE
		lsr.w	#4,d6
		cmpi.w	#$F,d6
		bcs.s	loc_69BA
		moveq	#$F,d6

loc_69BA:
		bsr.w	sub_6B06

loc_69BE:
		bclr	#3,(a2)
		beq.s	locret_69F2
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		move.w	#$150,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.s	locret_69F2
		lsr.w	#4,d6
		cmpi.w	#$F,d6
		bcs.s	loc_69EE
		moveq	#$F,d6

loc_69EE:
		bsr.w	sub_6B06

locret_69F2:
		rts	
; End of function sub_6954


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_69F4:				; XREF: sub_6886; LoadTilesAsYouMove
		tst.b	(a2)
		beq.w	locret_6A80
		bclr	#2,(a2)
		beq.s	loc_6A3E
		cmpi.w	#$10,(a3)
		bcs.s	loc_6A3E
		move.w	($FFFFF7F0).w,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	(sp)+,d4
		moveq	#-$10,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.s	loc_6A3E
		lsr.w	#4,d6
		subi.w	#$E,d6
		bcc.s	loc_6A3E
		neg.w	d6
		bsr.w	sub_6B06

loc_6A3E:
		bclr	#3,(a2)
		beq.s	locret_6A80
		move.w	($FFFFF7F0).w,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		move.w	#$150,d5
		bsr.w	sub_6C20
		move.w	(sp)+,d4
		move.w	#$150,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.s	locret_6A80
		lsr.w	#4,d6
		subi.w	#$E,d6
		bcc.s	locret_6A80
		neg.w	d6
		bsr.w	sub_6B06

locret_6A80:
		rts	
; End of function sub_69F4

; ===========================================================================
		tst.b	(a2)
		beq.s	locret_6AD6
		bclr	#2,(a2)
		beq.s	loc_6AAC
		move.w	#$D0,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		moveq	#-$10,d5
		bsr.w	sub_6C3C
		move.w	(sp)+,d4
		moveq	#-$10,d5
		moveq	#2,d6
		bsr.w	sub_6B06

loc_6AAC:
		bclr	#3,(a2)
		beq.s	locret_6AD6
		move.w	#$D0,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		move.w	#$150,d5
		bsr.w	sub_6C3C
		move.w	(sp)+,d4
		move.w	#$150,d5
		moveq	#2,d6
		bsr.w	sub_6B06

locret_6AD6:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6AD8:				; XREF: LoadTilesAsYouMove
		moveq	#$16,d6
; End of function sub_6AD8


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6ADA:				; XREF: sub_6954; LoadTilesFromStart2
		move.l	#$800000,d7
		move.l	d0,d1

loc_6AE2:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_6BD6
		move.l	d1,d0
		bsr.w	sub_6B32
		addq.b	#4,d1
		andi.b	#$7F,d1
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d5
		dbf	d6,loc_6AE2
		rts	
; End of function sub_6ADA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6B04:				; XREF: LoadTilesAsYouMove
		moveq	#$F,d6
; End of function sub_6B04


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; main draw section

sub_6B06:
		move.l	#$800000,d7
		move.l	d0,d1

loc_6B0E:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_6BD6
		move.l	d1,d0
		bsr.w	sub_6B32
		addi.w	#$100,d1
		andi.w	#$FFF,d1
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d4
		dbf	d6,loc_6B0E
		rts	
; End of function sub_6B06


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6B32:				; XREF: sub_6ADA; sub_6B06
		or.w	d2,d0
		swap	d0
		btst	#3,(a0)					; MJ: checking bit 3 not 4 (Flip)
		bne.s	loc_6B6E
		btst	#2,(a0)					; MJ: checking bit 2 not 3 (Mirror)
		bne.s	loc_6B4E
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		rts	
; ===========================================================================

loc_6B4E:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		rts	
; ===========================================================================

loc_6B6E:
		btst	#2,(a0) 				; MJ: checking bit 2 not 3 (Mirror)
		bne.s	loc_6B90
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts	
; ===========================================================================

loc_6B90:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts	
; End of function sub_6B32

; ===========================================================================
		rts	
; ===========================================================================
		move.l	d0,(a5)
		move.w	#$2000,d5
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; Reading from layout

sub_6BD6:
		lea	($FFFFB000).w,a1			; MJ: load Block's location
		add.w	4(a3),d4				; MJ: load Y position to d4
		add.w	(a3),d5					; MJ: load X position to d5
		move.w	d4,d3					; MJ: copy Y position to d3
		andi.w	#$780,d3				; MJ: get within 780 (Not 380) (E00 pixels (not 700)) in multiples of 80
		lsr.w	#3,d5					; MJ: divide X position by 8
		move.w	d5,d0					; MJ: copy to d0
		lsr.w	#4,d0					; MJ: divide by 10 (Not 20)
		andi.w	#$7F,d0					; MJ: get within 7F
		lsl.w	#$01,d3					; MJ: multiply by 2 (So it skips the BG)
		add.w	d3,d0					; MJ: add calc'd Y pos
		moveq	#-1,d3					; MJ: prepare FFFF in d3
		move.b	(a4,d0.w),d3				; MJ: collect correct chunk ID from layout
		andi.w	#$FF,d3					; MJ: keep within 7F
		lsl.w	#$07,d3					; MJ: multiply by 80
		andi.w	#$0070,d4				; MJ: keep Y pos within 80 pixels
		andi.w	#$000E,d5				; MJ: keep X pos within 10
		add.w	d4,d3					; MJ: add calc'd Y pos to ror'd d3
		add.w	d5,d3					; MJ: add calc'd X pos to ror'd d3
		movea.l	d3,a0					; MJ: set address (Chunk to read)
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_6C1E:
		rts	
; End of function sub_6BD6

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; getting VRam location

sub_6C20:
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0
		swap	d0
		move.w	d4,d0
		rts	
; End of function sub_6C20


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; not used


sub_6C3C:
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts	
; End of function sub_6C3C

; ---------------------------------------------------------------------------
; Subroutine to	load tiles as soon as the level	appears
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart:			; XREF: Level
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	($FFFFF700).w,a3
		movea.l	($FFFFA400).w,a4			; MJ: Load address of layout
		move.w	#$4000,d2
		bsr.s	LoadTilesFromStart2
		lea	($FFFFF708).w,a3
		movea.l	($FFFFA404).w,a4			; MJ: Load address of layout BG
		move.w	#$6000,d2
; End of function LoadTilesFromStart


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart2:			; XREF: LoadTilesFromStart
		moveq	#-$10,d4
		moveq	#$F,d6

loc_6C82:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	sub_6C20
		move.w	d1,d4
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_6C82
		rts	
; End of function LoadTilesFromStart2

LoadZoneTiles:
		moveq	#0,d0			; Clear d0
		move.b	($FFFFFE10).w,d0		; Load number of current zone to d0
		lsl.w	#4,d0			; Multiply by $10, converting the zone ID into an offset
		lea	(MainLoadBlocks).l,a2	; Load LevelHeaders's address into a2
		lea	(a2,d0.w),a2		; Offset LevelHeaders by the zone-offset, and load the resultant address to a2
		move.l	(a2)+,d0		; Move the first longword of data that a2 points to to d0, this contains the zone's first PLC ID and its art's address.
						; The auto increment is pointless as a2 is overwritten later, and nothing reads from a2 before then
		andi.l	#$FFFFFF,d0    		; Filter out the first byte, which contains the first PLC ID, leaving the address of the zone's art in d0
		movea.l	d0,a0			; Load the address of the zone's art into a0 (source)
		lea	($FF0000).l,a1		; Load v_256x256/StartOfRAM (in this context, an art buffer) into a1 (destination)
		bsr.w	KosDec			; Decompress a0 to a1 (Kosinski compression)

		move.w	a1,d3			; Move a word of a1 to d3, note that a1 doesn't exactly contain the address of v_256x256/StartOfRAM anymore, after KosDec, a1 now contains v_256x256/StartOfRAM + the size of the file decompressed to it, d3 now contains the length of the file that was decompressed
		move.w	d3,d7			; Move d3 to d7, for use in seperate calculations

		andi.w	#$FFF,d3		; Remove the high nibble of the high byte of the length of decompressed file, this nibble is how many $1000 bytes the decompressed art is
		lsr.w	#1,d3			; Half the value of 'length of decompressed file', d3 becomes the 'DMA transfer length'

		rol.w	#4,d7			; Rotate (left) length of decompressed file by one nibble
		andi.w	#$F,d7			; Only keep the low nibble of low byte (the same one filtered out of d3 above), this nibble is how many $1000 bytes the decompressed art is

@loop:		move.w	d7,d2			; Move d7 to d2, note that the ahead dbf removes 1 byte from d7 each time it loops, meaning that the following calculations will have different results each time
		lsl.w	#7,d2
		lsl.w	#5,d2			; Shift (left) d2 by $C, making it high nibble of the high byte, d2 is now the size of the decompressed file rounded down to the nearest $1000 bytes, d2 becomes the 'destination address'

		move.l	#$FFFFFF,d1		; Fill d1 with $FF
		move.w	d2,d1			; Move d2 to d1, overwriting the last word of $FF's with d2, this turns d1 into 'StartOfRAM'+'However many $1000 bytes the decompressed art is', d1 becomes the 'source address'

		jsr	(QueueDMATransfer).l	; Use d1, d2, and d3 to locate the decompressed art and ready for transfer to VRAM
		move.w	d7,-(sp)		; Store d7 in the Stack
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	RunPLC_RAM
		move.w	(sp)+,d7		; Restore d7 from the Stack
		move.w	#$800,d3		; Force the DMA transfer length to be $1000/2 (the first cycle is dynamic because the art's DMA'd backwards)
		dbf	d7,@loop		; Loop for each $1000 bytes the decompressed art is

		rts
; End of function LoadZoneTiles

; ---------------------------------------------------------------------------
; Main Load Block loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MainLoadBlockLoad:			; XREF: Level
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		lea	($FFFFB000).w,a1 ; RAM address for 16x16 mappings
		move.w	#0,d0
		bsr.w	EniDec
		movea.l	(a2)+,a0
		lea	($FF0000).l,a1	; RAM address for 256x256 mappings
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		bsr.w	PalLoad1	; load pallet (based on	d0)
		movea.l	(sp)+,a2
		addq.w	#PLCID_GHZ1,a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	locret_6D10
		bsr.w	LoadPLC		; load pattern load cues

locret_6D10:
		rts	
; End of function MainLoadBlockLoad

; ---------------------------------------------------------------------------
; Level	layout loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; This method now releases free ram space from A408 - A7FF

LevelLayoutLoad:
		move.w	($FFFFFE10).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		lea	(Level_Index).l,a1
		movea.l	(a1,d0.w),a1				; MJ: moving the address strait to a1 rather than adding a word to an address
		move.l	a1,($FFFFA400).w			; MJ: save location of layout to $FFFFA400
		adda.w	#$0080,a1				; MJ: add 80 (As the BG line is always after the FG line)
		move.l	a1,($FFFFA404).w			; MJ: save location of layout to $FFFFA404
		rts						; MJ: Return

; End of function LevelLayoutLoad2

; ---------------------------------------------------------------------------
; Dynamic screen resize	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DynScrResizeLoad:			; XREF: DeformBgLayer
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		add.w	d0,d0
		move.w	Resize_Index(pc,d0.w),d0
		jsr	Resize_Index(pc,d0.w)
		moveq	#2,d1
		move.w	($FFFFF726).w,d0
		sub.w	($FFFFF72E).w,d0
		beq.s	locret_6DAA
		bcc.s	loc_6DAC
		neg.w	d1
		move.w	($FFFFF704).w,d0
		cmp.w	($FFFFF726).w,d0
		bls.s	loc_6DA0
		move.w	d0,($FFFFF72E).w
		andi.w	#-2,($FFFFF72E).w

loc_6DA0:
		add.w	d1,($FFFFF72E).w
		move.b	#1,($FFFFF75C).w

locret_6DAA:
		rts	
; ===========================================================================

loc_6DAC:				; XREF: DynScrResizeLoad
		move.w	($FFFFF704).w,d0
		addq.w	#8,d0
		cmp.w	($FFFFF72E).w,d0
		bcs.s	loc_6DC4
		btst	#1,($FFFFD022).w
		beq.s	loc_6DC4
		add.w	d1,d1
		add.w	d1,d1

loc_6DC4:
		add.w	d1,($FFFFF72E).w
		move.b	#1,($FFFFF75C).w
		rts	
; End of function DynScrResizeLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for dynamic screen resizing
; ---------------------------------------------------------------------------
Resize_Index:	dc.w Resize_GHZ-Resize_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Green	Hill Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_GHZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	($FFFFFE11).w,d0
		add.w	d0,d0
		move.w	Resize_GHZx(pc,d0.w),d0
		jmp	Resize_GHZx(pc,d0.w)
; ===========================================================================
Resize_GHZx:	dc.w Resize_GHZ1-Resize_GHZx
		dc.w Resize_GHZ2-Resize_GHZx
; ===========================================================================

Resize_GHZ1:
		move.w	#$300,($FFFFF726).w ; set lower	y-boundary
		cmpi.w	#$1780,($FFFFF700).w ; has the camera reached $1780 on x-axis?
		bcs.s	locret_6E08	; if not, branch
		move.w	#$400,($FFFFF726).w ; set lower	y-boundary

locret_6E08:
		rts	
; ===========================================================================

Resize_GHZ2:
		move.w	#$300,($FFFFF726).w
		cmpi.w	#$ED0,($FFFFF700).w
		bcs.s	locret_6E3A
		move.w	#$200,($FFFFF726).w
		cmpi.w	#$1600,($FFFFF700).w
		bcs.s	locret_6E3A
		move.w	#$400,($FFFFF726).w
		cmpi.w	#$1D60,($FFFFF700).w
		bcs.s	locret_6E3A
		move.w	#$300,($FFFFF726).w

locret_6E3A:
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge
; ---------------------------------------------------------------------------

Obj11:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj11_Index(pc,d0.w),d1
		jmp	Obj11_Index(pc,d1.w)
; ===========================================================================
Obj11_Index:	dc.w Obj11_Main-Obj11_Index, Obj11_Action-Obj11_Index
		dc.w Obj11_Action2-Obj11_Index,	Obj11_Delete2-Obj11_Index
		dc.w Obj11_Delete2-Obj11_Index,	Obj11_Display2-Obj11_Index
; ===========================================================================

Obj11_Main:				; XREF: Obj11_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj11,4(a0)
		move.w	#$438E,2(a0)
		move.b	#4,1(a0)
		move.w	#$180,Obj_Priority(a0)
		move.b	#$80,Obj_SprWidth(a0)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		move.b	0(a0),d4	; copy object number ($11) to d4
		lea	$28(a0),a2	; copy bridge subtype to a2
		moveq	#0,d1
		move.b	(a2),d1		; copy a2 to d1
		move.b	#0,(a2)+
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3
		subq.b	#2,d1
		bcs.s	Obj11_Action

Obj11_MakeBdg:
		bsr.w	SingleObjLoad
		bne.s	Obj11_Action
		addq.b	#1,$28(a0)
		cmp.w	8(a0),d3
		bne.s	loc_73B8
		addi.w	#$10,d3
		move.w	d2,$C(a0)
		move.w	d2,$3C(a0)
		move.w	a0,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		addq.b	#1,$28(a0)

loc_73B8:				; XREF: ROM:00007398j
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,$24(a1)
		move.b	d4,0(a1)	; load bridge object (d4 = $11)
		move.w	d2,$C(a1)
		move.w	d2,$3C(a1)
		move.w	d3,8(a1)
		move.l	#Map_obj11,4(a1)
		move.w	#$438E,2(a1)
		move.b	#4,1(a1)
		move.w	#$180,Obj_Priority(a1)
		move.b	#8,Obj_SprWidth(a1)
		addi.w	#$10,d3
		dbf	d1,Obj11_MakeBdg ; repeat d1 times (length of bridge)

Obj11_Action:				; XREF: Obj11_Index
		bsr.s	Obj11_Solid
		tst.b	$3E(a0)
		beq.s	Obj11_Display
		subq.b	#4,$3E(a0)
		bsr.w	Obj11_Bend

Obj11_Display:
		bsr.w	DisplaySprite
		bra.w	Obj11_ChkDel

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj11_Solid:				; XREF: Obj11_Action
		moveq	#0,d1
		move.b	$28(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		add.w	d2,d2
		lea	($FFFFD000).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		cmp.w	d2,d0
		bcc.w	locret_751E
		bra.s	Platform2
; End of function Obj11_Solid

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PlatformObject:
		lea	($FFFFD000).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_751E

Platform2:
		move.w	$C(a0),d0
		subq.w	#8,d0

Platform3:
		move.w	$C(a1),d2
		move.b	$16(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	locret_751E
		cmpi.w	#-$10,d0
		bcs.w	locret_751E
		tst.b	($FFFFF7C8).w
		bmi.w	locret_751E
		cmpi.b	#6,$24(a1)
		bcc.w	locret_751E
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,$C(a1)
		addq.b	#2,$24(a0)

loc_74AE:
		btst	#3,$22(a1)
		beq.s	loc_74DC
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,$22(a2)
		clr.b	$25(a2)
		cmpi.b	#4,$24(a2)
		bne.s	loc_74DC
		subq.b	#2,$24(a2)

loc_74DC:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,$26(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),Obj_Inertia(a1)
		btst	#1,$22(a1)
		beq.s	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	Sonic_ResetOnFloor
		movea.l	(sp)+,a0

loc_7512:
		bset	#3,$22(a1)
		bset	#3,$22(a0)

locret_751E:
		rts	
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	SLZ seesaws)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject:				; XREF: Obj1A_Slope; Obj5E_Slope
		lea	($FFFFD000).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.s	locret_751E
		btst	#0,1(a0)
		beq.s	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj15_Solid:				; XREF: Obj15_SetSolid
		lea	($FFFFD000).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_751E
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function Obj15_Solid

; ===========================================================================

Obj11_Action2:				; XREF: Obj11_Index
		bsr.s	Obj11_WalkOff
		bsr.w	DisplaySprite
		bra.w	Obj11_ChkDel

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk off a bridge
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj11_WalkOff:				; XREF: Obj11_Action2
		moveq	#0,d1
		move.b	$28(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		bsr.s	ExitPlatform2
		bcc.s	locret_75BE
		lsr.w	#4,d0
		move.b	d0,$3F(a0)
		move.b	$3E(a0),d0
		cmpi.b	#$40,d0
		beq.s	loc_75B6
		addq.b	#4,$3E(a0)

loc_75B6:
		bsr.w	Obj11_Bend
		bsr.w	Obj11_MoveSonic

locret_75BE:
		rts	
; End of function Obj11_WalkOff

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off	a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea	($FFFFD000).w,a1
		btst	#1,$22(a1)
		bne.s	loc_75E0
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_75E0
		cmp.w	d2,d0
		bcs.s	locret_75F2

loc_75E0:
		bclr	#3,$22(a1)
		move.b	#2,$24(a0)
		bclr	#3,$22(a0)

locret_75F2:
		rts	
; End of function ExitPlatform


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj11_MoveSonic:			; XREF: Obj11_WalkOff
		moveq	#0,d0
		move.b	$3F(a0),d0
		move.b	$29(a0,d0.w),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		lea	($FFFFD000).w,a1
		move.w	$C(a2),d0
		subq.w	#8,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)	; change Sonic's position on y-axis
		rts	
; End of function Obj11_MoveSonic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj11_Bend:				; XREF: Obj11_Action; Obj11_WalkOff
		move.b	$3E(a0),d0
		bsr.w	CalcSine
		move.w	d0,d4
		lea	(Obj11_BendData2).l,a4
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#4,d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		move.w	d3,d2
		add.w	d0,d3
		moveq	#0,d5
		lea	(Obj11_BendData).l,a5
		move.b	(a5,d3.w),d5
		andi.w	#$F,d3
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		lea	$29(a0),a2

loc_765C:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	(a3)+,d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,$C(a1)
		dbf	d2,loc_765C
		moveq	#0,d0
		move.b	$28(a0),d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		addq.b	#1,d3
		sub.b	d0,d3
		neg.b	d3
		bmi.s	locret_76CA
		move.w	d3,d2
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		adda.w	d2,a3
		subq.w	#1,d2
		bcs.s	locret_76CA

loc_76A4:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	-(a3),d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,$C(a1)
		dbf	d2,loc_76A4

locret_76CA:
		rts	
; End of function Obj11_Bend

; ===========================================================================
; ---------------------------------------------------------------------------
; GHZ bridge-bending data
; (Defines how the bridge bends	when Sonic walks across	it)
; ---------------------------------------------------------------------------
Obj11_BendData:	incbin	misc\ghzbend1.bin
		even
Obj11_BendData2:incbin	misc\ghzbend2.bin
		even

; ===========================================================================

Obj11_ChkDel:				; XREF: Obj11_Display; Obj11_Action2
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj11_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj11_DelAll		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj11_DelAll	; and delete object

Obj11_NoDel:
		rts	
; ===========================================================================

Obj11_DelAll:				; XREF: Obj11_ChkDel
		moveq	#0,d2
		lea	$28(a0),a2	; load bridge length
		move.b	(a2)+,d2	; move bridge length to	d2
		subq.b	#1,d2		; subtract 1
		bcs.s	Obj11_Delete

Obj11_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		cmp.w	a0,d0
		beq.s	loc_791E
		bsr.w	DeleteObject2

loc_791E:
		dbf	d2,Obj11_DelLoop ; repeat d2 times (bridge length)

Obj11_Delete:
		bsr.w	DeleteObject
		rts	
; ===========================================================================

Obj11_Delete2:				; XREF: Obj11_Index
		bsr.w	DeleteObject
		rts	
; ===========================================================================

Obj11_Display2:				; XREF: Obj11_Index
		bsr.w	DisplaySprite
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	bridge
; ---------------------------------------------------------------------------
Map_obj11:
	include "_maps\obj11.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;	    - spiked ball on a chain (SBZ)
; ---------------------------------------------------------------------------

Obj15:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj15_Index(pc,d0.w),d1
		jmp	Obj15_Index(pc,d1.w)
; ===========================================================================
Obj15_Index:	dc.w Obj15_Main-Obj15_Index, Obj15_SetSolid-Obj15_Index
		dc.w Obj15_Action2-Obj15_Index,	Obj15_Delete-Obj15_Index
		dc.w Obj15_Delete-Obj15_Index, Obj15_Display-Obj15_Index
		dc.w Obj15_Action-Obj15_Index
; ===========================================================================

Obj15_Main:				; XREF: Obj15_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj15,4(a0) ; GHZ and MZ specific code
		move.w	#$4380,2(a0)
		move.b	#4,1(a0)
		move.w	#$180,Obj_Priority(a0)
		move.b	#$18,Obj_SprWidth(a0)
		move.b	#8,$16(a0)
		move.w	$C(a0),$38(a0)
		move.w	8(a0),$3A(a0)
		move.b	0(a0),d4
		moveq	#0,d1
		lea	$28(a0),a2	; move chain length to a2
		move.b	(a2),d1		; move a2 to d1
		move.w	d1,-(sp)
		andi.w	#$F,d1
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		addq.b	#8,d3
		move.b	d3,$3C(a0)
		subq.b	#8,d3
		tst.b	$1A(a0)
		beq.s	Obj15_MakeChain
		addq.b	#8,d3
		subq.w	#1,d1

Obj15_MakeChain:
		bsr.w	SingleObjLoad
		bne.s	loc_7A92
		addq.b	#1,$28(a0)
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,$24(a1)
		move.b	d4,0(a1)	; load swinging	object
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		bclr	#6,2(a1)
		move.b	#4,1(a1)
		move.w	#$200,Obj_Priority(a1)
		move.b	#8,Obj_SprWidth(a1)
		move.b	#1,$1A(a1)
		move.b	d3,$3C(a1)
		subi.b	#$10,d3
		bcc.s	loc_7A8E
		move.b	#2,$1A(a1)
		move.w	#$180,Obj_Priority(a1)
		bset	#6,2(a1)

loc_7A8E:
		dbf	d1,Obj15_MakeChain ; repeat d1 times (chain length)

loc_7A92:
		move.w	a0,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.w	#$4080,$26(a0)
		move.w	#-$200,$3E(a0)
		move.w	(sp)+,d1

Obj15_SetSolid:				; XREF: Obj15_Index
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		moveq	#0,d3
		move.b	$16(a0),d3
		bsr.w	Obj15_Solid

Obj15_Action:				; XREF: Obj15_Index
		bsr.w	Obj15_Move
		bsr.w	DisplaySprite
		bra.w	Obj15_ChkDel
; ===========================================================================

Obj15_Action2:				; XREF: Obj15_Index
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		bsr.w	ExitPlatform
		move.w	8(a0),-(sp)
		bsr.w	Obj15_Move
		move.w	(sp)+,d2
		moveq	#0,d3
		move.b	$16(a0),d3
		addq.b	#1,d3
		bsr.w	MvSonicOnPtfm
		bsr.w	DisplaySprite
		bra.w	Obj15_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm:
		lea	($FFFFD000).w,a1
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.s	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm2:
		lea	($FFFFD000).w,a1
		move.w	$C(a0),d0
		subi.w	#9,d0

MvSonic2:
		tst.b	($FFFFF7C8).w
		bmi.s	locret_7B62
		cmpi.b	#6,($FFFFD024).w
		bcc.s	locret_7B62
		tst.w	($FFFFFE08).w
		bne.s	locret_7B62
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_7B62:
		rts	
; End of function MvSonicOnPtfm2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj15_Move:				; XREF: Obj15_Action; Obj15_Action2
		move.b	($FFFFFE78).w,d0
		move.w	#$80,d1
		btst	#0,$22(a0)
		beq.s	Obj15_Move2
		neg.w	d0
		add.w	d1,d0
; End of function Obj15_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj15_Move2:				; XREF: Obj15_Move; Obj48_Display
		bsr.w	CalcSine
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		lea	$28(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_7BCE:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#$FFD000,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	$3C(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a1)
		move.w	d5,8(a1)
		dbf	d6,loc_7BCE
		rts	
; End of function Obj15_Move2

; ===========================================================================

Obj15_ChkDel:				; XREF: Obj15_Action; Obj15_Action2
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj15_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj15_DelAll		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj15_DelAll	; and delete object

Obj15_NoDel:
		rts	
; ===========================================================================

Obj15_DelAll:				; XREF: Obj15_ChkDel
		moveq	#0,d2
		lea	$28(a0),a2
		move.b	(a2)+,d2

Obj15_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		bsr.w	DeleteObject2
		dbf	d2,Obj15_DelLoop ; repeat for length of	chain
		rts	
; ===========================================================================

Obj15_Delete:				; XREF: Obj15_Index
		bsr.w	DeleteObject
		rts	
; ===========================================================================

Obj15_Display:				; XREF: Obj15_Index
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	and MZ swinging	platforms
; ---------------------------------------------------------------------------
Map_obj15:
	include "_maps\obj15ghz.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Object 18 - platforms	(GHZ, SYZ, SLZ)
; ---------------------------------------------------------------------------

Obj18:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj18_Index(pc,d0.w),d1
		jmp	Obj18_Index(pc,d1.w)
; ===========================================================================
Obj18_Index:	dc.w Obj18_Main-Obj18_Index
		dc.w Obj18_Solid-Obj18_Index
		dc.w Obj18_Action2-Obj18_Index
		dc.w Obj18_Delete-Obj18_Index
		dc.w Obj18_Action-Obj18_Index
; ===========================================================================

Obj18_Main:				; XREF: Obj18_Index
		addq.b	#2,$24(a0)
		move.w	#$4000,2(a0)
		move.l	#Map_obj18,4(a0)
		move.b	#$20,Obj_SprWidth(a0)
		move.b	#4,1(a0)
		move.w	#$200,Obj_Priority(a0)
		move.w	$C(a0),$2C(a0)
		move.w	$C(a0),$34(a0)
		move.w	8(a0),$32(a0)
		move.w	#$80,$26(a0)
		moveq	#0,d1
		move.b	$28(a0),d0
		cmpi.b	#$A,d0		; is object type $A (large platform)?
		bne.s	Obj18_SetFrame	; if not, branch
		addq.b	#1,d1		; use frame #1
		move.b	#$20,Obj_SprWidth(a0)	; set width

Obj18_SetFrame:
		move.b	d1,$1A(a0)	; set frame to d1

Obj18_Solid:				; XREF: Obj18_Index
		tst.b	$38(a0)
		beq.s	loc_7EE0
		subq.b	#4,$38(a0)

loc_7EE0:
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		bsr.w	PlatformObject

Obj18_Action:				; XREF: Obj18_Index
		bsr.w	Obj18_Move
		bsr.w	Obj18_Nudge
		bsr.w	DisplaySprite
		bra.w	Obj18_ChkDel
; ===========================================================================

Obj18_Action2:				; XREF: Obj18_Index
		cmpi.b	#$40,$38(a0)
		beq.s	loc_7F06
		addq.b	#4,$38(a0)

loc_7F06:
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		bsr.w	ExitPlatform
		move.w	8(a0),-(sp)
		bsr.w	Obj18_Move
		bsr.w	Obj18_Nudge
		move.w	(sp)+,d2
		bsr.w	MvSonicOnPtfm2
		bsr.w	DisplaySprite
		bra.w	Obj18_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to	move platform slightly when you	stand on it
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj18_Nudge:				; XREF: Obj18_Action; Obj18_Action2
		move.b	$38(a0),d0
		bsr.w	CalcSine
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	$2C(a0),d0
		move.w	d0,$C(a0)
		rts	
; End of function Obj18_Nudge

; ---------------------------------------------------------------------------
; Subroutine to	move platforms
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj18_Move:				; XREF: Obj18_Action; Obj18_Action2
		moveq	#0,d0
		move.b	$28(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	Obj18_TypeIndex(pc,d0.w),d1
		jmp	Obj18_TypeIndex(pc,d1.w)
; End of function Obj18_Move

; ===========================================================================
Obj18_TypeIndex:dc.w Obj18_Type00-Obj18_TypeIndex, Obj18_Type01-Obj18_TypeIndex
		dc.w Obj18_Type02-Obj18_TypeIndex, Obj18_Type03-Obj18_TypeIndex
		dc.w Obj18_Type04-Obj18_TypeIndex, Obj18_Type05-Obj18_TypeIndex
		dc.w Obj18_Type06-Obj18_TypeIndex, Obj18_Type07-Obj18_TypeIndex
		dc.w Obj18_Type08-Obj18_TypeIndex, Obj18_Type00-Obj18_TypeIndex
		dc.w Obj18_Type0A-Obj18_TypeIndex, Obj18_Type0B-Obj18_TypeIndex
		dc.w Obj18_Type0C-Obj18_TypeIndex
; ===========================================================================

Obj18_Type00:
		rts			; platform 00 doesn't move
; ===========================================================================

Obj18_Type05:
		move.w	$32(a0),d0
		move.b	$26(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.s	Obj18_01_Move
; ===========================================================================

Obj18_Type01:
		move.w	$32(a0),d0
		move.b	$26(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

Obj18_01_Move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,8(a0)	; change position on x-axis
		bra.w	Obj18_ChgMotion
; ===========================================================================

Obj18_Type0C:
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1 ; load	platform-motion	variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$30,d1
		bra.s	Obj18_02_Move
; ===========================================================================

Obj18_Type0B:
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1 ; load	platform-motion	variable
		subi.b	#$30,d1
		bra.s	Obj18_02_Move
; ===========================================================================

Obj18_Type06:
		move.w	$34(a0),d0
		move.b	$26(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.s	Obj18_02_Move
; ===========================================================================

Obj18_Type02:
		move.w	$34(a0),d0
		move.b	$26(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

Obj18_02_Move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,$2C(a0)	; change position on y-axis
		bra.w	Obj18_ChgMotion
; ===========================================================================

Obj18_Type03:
		tst.w	$3A(a0)		; is time delay	set?
		bne.s	Obj18_03_Wait	; if yes, branch
		btst	#3,$22(a0)	; is Sonic standing on the platform?
		beq.s	Obj18_03_NoMove	; if not, branch
		move.w	#30,$3A(a0)	; set time delay to 0.5	seconds

Obj18_03_NoMove:
		rts	
; ===========================================================================

Obj18_03_Wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time
		bne.s	Obj18_03_NoMove	; if time is > 0, branch
		move.w	#32,$3A(a0)
		addq.b	#1,$28(a0)	; change to type 04 (falling)
		rts	
; ===========================================================================

Obj18_Type04:
		tst.w	$3A(a0)
		beq.s	loc_8048
		subq.w	#1,$3A(a0)
		bne.s	loc_8048
		btst	#3,$22(a0)
		beq.s	loc_8042
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	$12(a0),$12(a1)

loc_8042:
		move.b	#8,$24(a0)

loc_8048:
		move.l	$2C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d3,$2C(a0)
		addi.w	#$38,$12(a0)
		move.w	($FFFFF72E).w,d0
		addi.w	#$E0,d0
		cmp.w	$2C(a0),d0
		bcc.s	locret_8074
		move.b	#6,$24(a0)

locret_8074:
		rts	
; ===========================================================================

Obj18_Type07:
		tst.w	$3A(a0)		; is time delay	set?
		bne.s	Obj18_07_Wait	; if yes, branch
		lea	($FFFFF7E0).w,a2 ; load	switch statuses
		moveq	#0,d0
		move.b	$28(a0),d0	; move object type ($x7) to d0
		lsr.w	#4,d0		; divide d0 by 8, round	down
		tst.b	(a2,d0.w)	; has switch no. d0 been pressed?
		beq.s	Obj18_07_NoMove	; if not, branch
		move.w	#60,$3A(a0)	; set time delay to 1 second

Obj18_07_NoMove:
		rts	
; ===========================================================================

Obj18_07_Wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.s	Obj18_07_NoMove	; if time is > 0, branch
		addq.b	#1,$28(a0)	; change to type 08
		rts	
; ===========================================================================

Obj18_Type08:
		subq.w	#2,$2C(a0)	; move platform	up
		move.w	$34(a0),d0
		subi.w	#$200,d0
		cmp.w	$2C(a0),d0	; has platform moved $200 pixels?
		bne.s	Obj18_08_NoStop	; if not, branch
		clr.b	$28(a0)		; change to type 00 (stop moving)

Obj18_08_NoStop:
		rts	
; ===========================================================================

Obj18_Type0A:
		move.w	$34(a0),d0
		move.b	$26(a0),d1	; load platform-motion variable
		subi.b	#$40,d1
		ext.w	d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	d0,$2C(a0)	; change position on y-axis

Obj18_ChgMotion:
		move.b	($FFFFFE78).w,$26(a0) ;	update platform-movement variable
		rts	
; ===========================================================================

Obj18_ChkDel:				; XREF: Obj18_Action; Obj18_Action2
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj18_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj18_Delete		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj18_Delete	; and delete object

Obj18_NoDel:
		rts	
; ===========================================================================

Obj18_Delete:				; XREF: Obj18_Index
		bra.w	DeleteObject
; ===========================================================================

; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	platforms
; ---------------------------------------------------------------------------
Map_obj18:
	include "_maps\obj18ghz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 53 - collapsing floors	(MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------

Obj53:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj53_Index(pc,d0.w),d1
		jmp	Obj53_Index(pc,d1.w)
; ===========================================================================
Obj53_Index:	dc.w Obj53_Main-Obj53_Index, Obj53_ChkTouch-Obj53_Index
		dc.w Obj53_Touch-Obj53_Index, Obj53_Display-Obj53_Index
		dc.w Obj53_Delete-Obj53_Index, Obj53_WalkOff-Obj53_Index
; ===========================================================================

Obj53_Main:				; XREF: Obj53_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj53,4(a0)
		move.w	#$42B8,2(a0)
		cmpi.b	#3,($FFFFFE10).w ; check if level is SLZ
		bne.s	Obj53_NotSLZ
		move.w	#$44E0,2(a0)	; SLZ specific code
		addq.b	#2,$1A(a0)

Obj53_NotSLZ:
		cmpi.b	#5,($FFFFFE10).w ; check if level is SBZ
		bne.s	Obj53_NotSBZ
		move.w	#$43F5,2(a0)	; SBZ specific code

Obj53_NotSBZ:
		ori.b	#4,1(a0)
		move.w	#$200,Obj_Priority(a0)
		move.b	#7,$38(a0)
		move.b	#$44,Obj_SprWidth(a0)

Obj53_ChkTouch:				; XREF: Obj53_Index
		tst.b	$3A(a0)		; has Sonic touched the	object?
		beq.s	Obj53_Solid	; if not, branch
		tst.b	$38(a0)		; has time delay reached zero?
		beq.w	Obj53_Collapse	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time

Obj53_Solid:
		move.w	#$20,d1
		bsr.w	PlatformObject
		tst.b	$28(a0)
		bpl.s	Obj53_MarkAsGone
		btst	#3,$22(a1)
		beq.s	Obj53_MarkAsGone
		bclr	#0,1(a0)
		move.w	8(a1),d0
		sub.w	8(a0),d0
		bcc.s	Obj53_MarkAsGone
		bset	#0,1(a0)

Obj53_MarkAsGone:
		bra.w	MarkObjGone
; ===========================================================================

Obj53_Touch:				; XREF: Obj53_Index
		tst.b	$38(a0)
		beq.w	loc_8458
		move.b	#1,$3A(a0)	; set object as	"touched"
		subq.b	#1,$38(a0)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj53_WalkOff:				; XREF: Obj53_Index
		move.w	#$20,d1
		bsr.w	ExitPlatform
		move.w	8(a0),d2
		bsr.w	MvSonicOnPtfm2
		bra.w	MarkObjGone
; End of function Obj53_WalkOff

; ===========================================================================

Obj53_Display:				; XREF: Obj53_Index
		tst.b	$38(a0)		; has time delay reached zero?
		beq.s	Obj53_TimeZero	; if yes, branch
		tst.b	$3A(a0)		; has Sonic touched the	object?
		bne.w	loc_8402	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time
		bra.w	DisplaySprite
; ===========================================================================

loc_8402:
		subq.b	#1,$38(a0)
		bsr.w	Obj53_WalkOff
		lea	($FFFFD000).w,a1
		btst	#3,$22(a1)
		beq.s	loc_842E
		tst.b	$38(a0)
		bne.s	locret_843A
		bclr	#3,$22(a1)
		bclr	#5,$22(a1)
		move.b	#1,$1D(a1)

loc_842E:
		move.b	#0,$3A(a0)
		move.b	#6,$24(a0)	; run "Obj53_Display" routine

locret_843A:
		rts	
; ===========================================================================

Obj53_TimeZero:				; XREF: Obj53_Display
		bsr.w	ObjectFall
		bsr.w	DisplaySprite
		tst.b	1(a0)
		bpl.s	Obj53_Delete
		rts	
; ===========================================================================

Obj53_Delete:				; XREF: Obj53_Index
		bsr.w	DeleteObject
		rts	
; ===========================================================================

Obj53_Collapse:				; XREF: Obj53_ChkTouch
		move.b	#0,$3A(a0)

loc_8458:				; XREF: Obj53_Touch
		lea	(Obj53_Data2).l,a4
		btst	#0,$28(a0)
		beq.s	loc_846C
		lea	(Obj53_Data3).l,a4

loc_846C:
		moveq	#7,d1
		addq.b	#1,$1A(a0)
		bra.s	loc_8486
; ===========================================================================

Obj1A_Collapse:
		move.b	#0,$3A(a0)

loc_847A:
		lea	(Obj53_Data1).l,a4
		moveq	#$18,d1
		addq.b	#2,$1A(a0)

loc_8486:
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		move.b	#6,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.w	Obj_Priority(a0),Obj_Priority(a1)
		move.b	Obj_SprWidth(a0),Obj_SprWidth(a1)
		move.b	(a4)+,$38(a1)
		subq.w	#1,d1
		lea	($FFFFD800).w,a1
		move.w	#$5F,d0

loc_84AA:
@loop:
		tst.b	(a1)
		beq.s	@cont
		lea	$40(a1),a1
		dbf	d0,@loop
		bne.s	loc_84F2

@cont:
		addq.w	#5,a3

loc_84B2:
		move.b	#6,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.w	Obj_Priority(a0),Obj_Priority(a1)
		move.b	Obj_SprWidth(a0),Obj_SprWidth(a1)
		move.b	(a4)+,$38(a1)
		bsr.w	DisplaySprite2

loc_84EE:
		dbf	d1,loc_84AA

loc_84F2:
		bsr.w	DisplaySprite
		move.w	#$B9,d0
		jmp	(PlaySound_Special).l ;	play collapsing	sound
; ===========================================================================
; ---------------------------------------------------------------------------
; Disintegration data for collapsing ledges (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------
Obj53_Data1:	dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C, 0
Obj53_Data2:	dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2
Obj53_Data3:	dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	MZ platforms)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject2:				; XREF: Obj1A_WalkOff; et al
		lea	($FFFFD000).w,a1
		btst	#3,$22(a1)
		beq.s	locret_856E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,1(a0)
		beq.s	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	$C(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_856E:
		rts	
; End of function SlopeObject2

; ===========================================================================

; ---------------------------------------------------------------------------
; Sprite mappings - collapsing floors (MZ, SLZ,	SBZ)
; ---------------------------------------------------------------------------
Map_obj53:
	include "_maps\obj53.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Object 27 - explosion	from a destroyed enemy
; ---------------------------------------------------------------------------

Obj27:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj27_Index(pc,d0.w),d1
		jmp	Obj27_Index(pc,d1.w)
; ===========================================================================
Obj27_Index:	dc.w Obj27_LoadAnimal-Obj27_Index
		dc.w Obj27_Main-Obj27_Index
		dc.w Obj27_Animate-Obj27_Index
; ===========================================================================

Obj27_LoadAnimal:			; XREF: Obj27_Index
		addq.b	#2,$24(a0)
		bsr.w	SingleObjLoad
		bne.s	Obj27_Main
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),$3E(a1)

Obj27_Main:				; XREF: Obj27_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj27,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#0,$20(a0)
		move.b	#$C,Obj_SprWidth(a0)
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		move.b	#0,$1A(a0)
		move.w	#$C1,d0
		jsr	(PlaySound_Special).l ;	play breaking enemy sound

Obj27_Animate:				; XREF: Obj27_Index
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	Obj27_Display
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		addq.b	#1,$1A(a0)	; next frame
		cmpi.b	#5,$1A(a0)	; is the final frame (05) displayed?
		beq.w	DeleteObject	; if yes, branch

Obj27_Display:
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3F - explosion	from a destroyed boss, bomb or cannonball
; ---------------------------------------------------------------------------

Obj3F:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3F_Index(pc,d0.w),d1
		jmp	Obj3F_Index(pc,d1.w)
; ===========================================================================
Obj3F_Index:	dc.w Obj3F_Main-Obj3F_Index
		dc.w Obj27_Animate-Obj3F_Index
; ===========================================================================

Obj3F_Main:				; XREF: Obj3F_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj3F,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#0,$20(a0)
		move.b	#$C,Obj_SprWidth(a0)
		move.b	#7,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#$C4,d0
		jmp	(PlaySound_Special).l ;	play exploding bomb sound
; ===========================================================================

; ---------------------------------------------------------------------------
; Sprite mappings - explosion
; ---------------------------------------------------------------------------
Map_obj27:	dc.w byte_8ED0-Map_obj27, byte_8ED6-Map_obj27
		dc.w byte_8EDC-Map_obj27, byte_8EE2-Map_obj27
		dc.w byte_8EF7-Map_obj27
byte_8ED0:	dc.b 1
		dc.b $F8, 9, 0,	0, $F4
byte_8ED6:	dc.b 1
		dc.b $F0, $F, 0, 6, $F0
byte_8EDC:	dc.b 1
		dc.b $F0, $F, 0, $16, $F0
byte_8EE2:	dc.b 4
		dc.b $EC, $A, 0, $26, $EC
		dc.b $EC, 5, 0,	$2F, 4
		dc.b 4,	5, $18,	$2F, $EC
		dc.b $FC, $A, $18, $26,	$FC
byte_8EF7:	dc.b 4
		dc.b $EC, $A, 0, $33, $EC
		dc.b $EC, 5, 0,	$3C, 4
		dc.b 4,	5, $18,	$3C, $EC
		dc.b $FC, $A, $18, $33,	$FC
		even
; ---------------------------------------------------------------------------
; Sprite mappings - explosion from when	a boss is destroyed
; ---------------------------------------------------------------------------
Map_obj3F:	dc.w byte_8ED0-Map_obj3F
		dc.w byte_8F16-Map_obj3F
		dc.w byte_8F1C-Map_obj3F
		dc.w byte_8EE2-Map_obj3F
		dc.w byte_8EF7-Map_obj3F
byte_8F16:	dc.b 1
		dc.b $F0, $F, 0, $40, $F0
byte_8F1C:	dc.b 1
		dc.b $F0, $F, 0, $50, $F0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 28 - animals
; ---------------------------------------------------------------------------

Obj28:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj28_Index(pc,d0.w),d1
		jmp	Obj28_Index(pc,d1.w)
; ===========================================================================
Obj28_Index:	dc.w Obj28_Ending-Obj28_Index, loc_912A-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_91C0-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_9184-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_91C0-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_9240-Obj28_Index
		dc.w loc_9260-Obj28_Index, loc_9260-Obj28_Index
		dc.w loc_9280-Obj28_Index, loc_92BA-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9332-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9332-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9370-Obj28_Index
		dc.w loc_92D6-Obj28_Index

Obj28_VarIndex:	dc.b 0,	5, 2, 3, 6, 3, 4, 5, 4,	1, 0, 1

Obj28_Variables:dc.w $FE00, $FC00
		dc.l Map_obj28
		dc.w $FE00, $FD00	; horizontal speed, vertical speed
		dc.l Map_obj28a		; mappings address
		dc.w $FE80, $FD00
		dc.l Map_obj28
		dc.w $FEC0, $FE80
		dc.l Map_obj28a
		dc.w $FE40, $FD00
		dc.l Map_obj28b
		dc.w $FD00, $FC00
		dc.l Map_obj28a
		dc.w $FD80, $FC80
		dc.l Map_obj28b

Obj28_EndSpeed:	dc.w $FBC0, $FC00, $FBC0, $FC00, $FBC0,	$FC00, $FD00, $FC00
		dc.w $FD00, $FC00, $FE80, $FD00, $FE80,	$FD00, $FEC0, $FE80
		dc.w $FE40, $FD00, $FE00, $FD00, $FD80,	$FC80

Obj28_EndMap:	dc.l Map_obj28a, Map_obj28a, Map_obj28a, Map_obj28, Map_obj28
		dc.l Map_obj28,	Map_obj28, Map_obj28a, Map_obj28b, Map_obj28a
		dc.l Map_obj28b

Obj28_EndVram:	dc.w $5A5, $5A5, $5A5, $553, $553, $573, $573, $585, $593
		dc.w $565, $5B3
; ===========================================================================

Obj28_Ending:				; XREF: Obj28_Index
		tst.b	$28(a0)		; did animal come from a destroyed enemy?
		beq.w	Obj28_FromEnemy	; if yes, branch
		moveq	#0,d0
		move.b	$28(a0),d0	; move object type to d0
		add.w	d0,d0		; multiply d0 by 2
		move.b	d0,$24(a0)	; move d0 to routine counter
		subi.w	#$14,d0
		move.w	Obj28_EndVram(pc,d0.w),2(a0)
		add.w	d0,d0
		move.l	Obj28_EndMap(pc,d0.w),4(a0)
		lea	Obj28_EndSpeed(pc),a1
		move.w	(a1,d0.w),$32(a0) ; load horizontal speed
		move.w	(a1,d0.w),$10(a0)
		move.w	2(a1,d0.w),$34(a0) ; load vertical speed
		move.w	2(a1,d0.w),$12(a0)
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.w	#$300,Obj_Priority(a0)
		move.b	#8,Obj_SprWidth(a0)
		move.b	#7,$1E(a0)
		bra.w	DisplaySprite
; ===========================================================================

Obj28_FromEnemy:			; XREF: Obj28_Ending
		addq.b	#2,$24(a0)
		bsr.w	RandomNumber
		andi.w	#1,d0
		moveq	#0,d1
		move.b	($FFFFFE10).w,d1
		add.w	d1,d1
		add.w	d0,d1
		lea	Obj28_VarIndex(pc),a1
		move.b	(a1,d1.w),d0
		move.b	d0,$30(a0)
		lsl.w	#3,d0
		lea	Obj28_Variables(pc),a1
		adda.w	d0,a1
		move.w	(a1)+,$32(a0)	; load horizontal speed
		move.w	(a1)+,$34(a0)	; load vertical	speed
		move.l	(a1)+,4(a0)	; load mappings
		move.w	#$580,2(a0)	; VRAM setting for 1st animal
		btst	#0,$30(a0)	; is 1st animal	used?
		beq.s	loc_90C0	; if yes, branch
		move.w	#$592,2(a0)	; VRAM setting for 2nd animal

loc_90C0:
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.w	#$300,Obj_Priority(a0)
		move.b	#8,Obj_SprWidth(a0)
		move.b	#7,$1E(a0)
		move.b	#2,$1A(a0)
		move.w	#-$400,$12(a0)
		tst.b	($FFFFF7A7).w
		bne.s	loc_911C
		bsr.w	SingleObjLoad
		bne.s	Obj28_Display
		move.b	#$29,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),d0
		lsr.w	#1,d0
		move.b	d0,$1A(a1)

Obj28_Display:
		bra.w	DisplaySprite
; ===========================================================================

loc_911C:
		move.b	#$12,$24(a0)
		clr.w	$10(a0)
		bra.w	DisplaySprite
; ===========================================================================

loc_912A:				; XREF: Obj28_Index
		tst.b	1(a0)
		bpl.w	DeleteObject
		bsr.w	ObjectFall
		tst.w	$12(a0)
		bmi.s	loc_9180
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_9180
		add.w	d1,$C(a0)
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#1,$1A(a0)
		move.b	$30(a0),d0
		add.b	d0,d0
		addq.b	#4,d0
		move.b	d0,$24(a0)
		tst.b	($FFFFF7A7).w
		beq.s	loc_9180
		btst	#4,($FFFFFE0F).w
		beq.s	loc_9180
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9180:
		bra.w	DisplaySprite
; ===========================================================================

loc_9184:				; XREF: Obj28_Index
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_91AE
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_91AE
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_91AE:
		tst.b	$28(a0)
		bne.s	loc_9224
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

loc_91C0:				; XREF: Obj28_Index
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_91FC
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_91FC
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)
		tst.b	$28(a0)
		beq.s	loc_91FC
		cmpi.b	#$A,$28(a0)
		beq.s	loc_91FC
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_91FC:
		subq.b	#1,$1E(a0)
		bpl.s	loc_9212
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9212:
		tst.b	$28(a0)
		bne.s	loc_9224
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

loc_9224:				; XREF: Obj28_Index
		move.w	8(a0),d0
		sub.w	($FFFFD008).w,d0
		bcs.s	loc_923C
		subi.w	#$180,d0
		bpl.s	loc_923C
		tst.b	1(a0)
		bpl.w	DeleteObject

loc_923C:
		bra.w	DisplaySprite
; ===========================================================================

loc_9240:				; XREF: Obj28_Index
		tst.b	1(a0)
		bpl.w	DeleteObject
		subq.w	#1,$36(a0)
		bne.w	loc_925C
		move.b	#2,$24(a0)
		move.w	#$180,Obj_Priority(a0)

loc_925C:
		bra.w	DisplaySprite
; ===========================================================================

loc_9260:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bcc.s	loc_927C
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#$E,$24(a0)
		bra.w	loc_91C0
; ===========================================================================

loc_927C:
		bra.w	loc_9224
; ===========================================================================

loc_9280:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_92B6
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bsr.w	loc_93C4
		bsr.w	loc_93EC
		subq.b	#1,$1E(a0)
		bpl.s	loc_92B6
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_92B6:
		bra.w	loc_9224
; ===========================================================================

loc_92BA:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_9310
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#4,$24(a0)
		bra.w	loc_9184
; ===========================================================================

loc_92D6:				; XREF: Obj28_Index
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_9310
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_9310
		not.b	$29(a0)
		bne.s	loc_9306
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9306:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9310:
		bra.w	loc_9224
; ===========================================================================

loc_9314:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_932E
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	ObjectFall
		bsr.w	loc_93C4
		bsr.w	loc_93EC

loc_932E:
		bra.w	loc_9224
; ===========================================================================

loc_9332:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_936C
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_936C
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_936C
		neg.w	$10(a0)
		bchg	#0,1(a0)
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_936C:
		bra.w	loc_9224
; ===========================================================================

loc_9370:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_93C0
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_93AA
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_93AA
		not.b	$29(a0)
		bne.s	loc_93A0
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_93A0:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_93AA:
		subq.b	#1,$1E(a0)
		bpl.s	loc_93C0
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_93C0:
		bra.w	loc_9224
; ===========================================================================

loc_93C4:
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	locret_93EA
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	locret_93EA
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

locret_93EA:
		rts	
; ===========================================================================

loc_93EC:
		bset	#0,1(a0)
		move.w	8(a0),d0
		sub.w	($FFFFD008).w,d0
		bcc.s	locret_9402
		bclr	#0,1(a0)

locret_9402:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_9404:
		move.w	($FFFFD008).w,d0
		sub.w	8(a0),d0
		subi.w	#$B8,d0
		rts	
; End of function sub_9404

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 29 - points that appear when you destroy something
; ---------------------------------------------------------------------------

Obj29:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj29_Index(pc,d0.w),d1
		jsr	Obj29_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Obj29_Index:	dc.w Obj29_Main-Obj29_Index
		dc.w Obj29_Slower-Obj29_Index
; ===========================================================================

Obj29_Main:				; XREF: Obj29_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj29,4(a0)
		move.w	#$2797,2(a0)
		move.b	#4,1(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#8,Obj_SprWidth(a0)
		move.w	#-$300,$12(a0)	; move object upwards

Obj29_Slower:				; XREF: Obj29_Index
		tst.w	$12(a0)		; is object moving?
		bpl.w	DeleteObject	; if not, branch
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)	; reduce object	speed
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - animals
; ---------------------------------------------------------------------------
Map_obj28:
	include "_maps\obj28.asm"

Map_obj28a:
	include "_maps\obj28a.asm"

Map_obj28b:
	include "_maps\obj28b.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - points that	appear when you	destroy	something
; ---------------------------------------------------------------------------
Map_obj29:
	include "_maps\obj29.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 25 - rings
; ---------------------------------------------------------------------------

Obj25:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj25_Index(pc,d0.w),d1
		jmp	Obj25_Index(pc,d1.w)
; ===========================================================================
Obj25_Index:	dc.w Obj25_Main-Obj25_Index
		dc.w Obj25_Animate-Obj25_Index
		dc.w Obj25_Collect-Obj25_Index
		dc.w Obj25_Sparkle-Obj25_Index
		dc.w Obj25_Delete-Obj25_Index
; ===========================================================================

Obj25_Main:				; XREF: Obj25_Index
		addq.b	#2,$24(a0)
		move.w	8(a0),$32(a0)
		move.l	#Map_obj25,4(a0)
		move.w	#$27B2,2(a0)
		move.b	#4,1(a0)
		move.w	#$100,Obj_Priority(a0)
		move.b	#$47,$20(a0)
		move.b	#8,Obj_SprWidth(a0)

Obj25_Animate:				; XREF: Obj25_Index
		move.b	($FFFFFEC3).w,$1A(a0)
		move.w	$32(a0),d0
		bra.w	MarkObjGone
; ===========================================================================

Obj25_Collect:				; XREF: Obj25_Index
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.w	#$80,Obj_Priority(a0)
		bsr.w	CollectRing

Obj25_Sparkle:				; XREF: Obj25_Index
		lea	(Ani_obj25).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Obj25_Delete:				; XREF: Obj25_Index
		bra.w	DeleteObject

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


CollectRing:				; XREF: Obj25_Collect
		addq.w	#1,($FFFFFE20).w ; add 1 to rings
		ori.b	#1,($FFFFFE1D).w ; update the rings counter
		move.w	#$B5,d0		; play ring sound
		cmpi.w	#100,($FFFFFE20).w ; do	you have < 100 rings?
		bcs.s	Obj25_PlaySnd	; if yes, branch
		bset	#1,($FFFFFE1B).w ; update lives	counter
		beq.s	loc_9CA4
		cmpi.w	#200,($FFFFFE20).w ; do	you have < 200 rings?
		bcs.s	Obj25_PlaySnd	; if yes, branch
		bset	#2,($FFFFFE1B).w ; update lives	counter
		bne.s	Obj25_PlaySnd

loc_9CA4:
		addq.b	#1,($FFFFFE12).w ; add 1 to the	number of lives	you have
		addq.b	#1,($FFFFFE1C).w ; add 1 to the	lives counter
		move.w	#$88,d0		; play extra life music

Obj25_PlaySnd:
		jmp	(PlaySound_Special).l
; End of function CollectRing

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 37 - rings flying out of Sonic	when he's hit
; ---------------------------------------------------------------------------

Obj37:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj37_Index(pc,d0.w),d1
		jmp	Obj37_Index(pc,d1.w)
; ===========================================================================
Obj37_Index:	dc.w Obj37_CountRings-Obj37_Index
		dc.w Obj37_Bounce-Obj37_Index
		dc.w Obj37_Collect-Obj37_Index
		dc.w Obj37_Sparkle-Obj37_Index
		dc.w Obj37_Delete-Obj37_Index
; ===========================================================================

Obj37_CountRings:			; XREF: Obj37_Index
		movea.l	a0,a1
		moveq	#0,d5
		move.w	($FFFFFE20).w,d5 ; check number	of rings you have
		moveq	#32,d0
		cmp.w	d0,d5		; do you have 32 or more?
		bcs.s	loc_9CDE	; if not, branch
		move.w	d0,d5		; if yes, set d5 to 32

loc_9CDE:
		subq.w	#1,d5
		move.w	#$288,d4
		bra.s	Obj37_MakeRings
; ===========================================================================

Obj37_Loop:
		bsr.w	SingleObjLoad
		bne.w	Obj37_ResetCounter

Obj37_MakeRings:			; XREF: Obj37_CountRings
		move.b	#$37,0(a1)	; load bouncing	ring object
		addq.b	#2,$24(a1)
		move.b	#8,$16(a1)
		move.b	#8,$17(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_obj25,4(a1)
		move.w	#$27B2,2(a1)
		move.b	#4,1(a1)
		move.w	#$180,Obj_Priority(a1)
		move.b	#$47,$20(a1)
		move.b	#8,Obj_SprWidth(a1)
		tst.w	d4
		bmi.s	loc_9D62
		move.w	d4,d0
		bsr.w	CalcSine
		move.w	d4,d2
		lsr.w	#8,d2
		tst.b	($FFFFF64C).w		; Does the level have water?
		beq.s	@skiphalvingvel		; If not, branch and skip underwater checks
		move.w	($FFFFF646).w,d6	; Move water level to d6
		cmp.w	$C(a0),d6		; Is the ring object underneath the water level?
		bgt.s	@skiphalvingvel		; If not, branch and skip underwater commands
		asr.w	d0			; Half d0. Makes the ring's x_vel bounce to the left/right slower
		asr.w	d1			; Half d1. Makes the ring's y_vel bounce up/down slower

@skiphalvingvel:
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bcc.s	loc_9D62
		subi.w	#$80,d4
		bcc.s	loc_9D62
		move.w	#$288,d4

loc_9D62:
		move.w	d2,$10(a1)
		move.w	d3,$12(a1)
		neg.w	d2
		neg.w	d4
		dbf	d5,Obj37_Loop	; repeat for number of rings (max 31)

Obj37_ResetCounter:			; XREF: Obj37_Loop
		move.w	#0,($FFFFFE20).w ; reset number	of rings to zero
		move.b	#$80,($FFFFFE1D).w ; update ring counter
		move.b	#0,($FFFFFE1B).w
		moveq	#-1,d0			; Move #-1 to d0
		move.b	d0,$1F(a0)	; Move d0 to new timer
		move.b	d0,($FFFFFEC6).w	; Move d0 to old timer (for animated purposes)
		move.w	#$C6,d0
		jsr	(PlaySound_Special).l ;	play ring loss sound

Obj37_Bounce:				; XREF: Obj37_Index
		move.b	($FFFFFEC7).w,$1A(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.b	($FFFFF64C).w		; Does the level have water?
		beq.s	@skipbounceslow		; If not, branch and skip underwater checks
		move.w	($FFFFF646).w,d6	; Move water level to d6
		cmp.w	$C(a0),d6		; Is the ring object underneath the water level?
		bgt.s	@skipbounceslow		; If not, branch and skip underwater commands
		subi.w	#$E,$12(a0)		; Reduce gravity by $E ($18-$E=$A), giving the underwater effect

@skipbounceslow:
		bmi.s	Obj37_ChkDel
		move.b	($FFFFFE0F).w,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.s	Obj37_ChkDel
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	Obj37_ChkDel
		add.w	d1,$C(a0)
		move.w	$12(a0),d0
		asr.w	#2,d0
		sub.w	d0,$12(a0)
		neg.w	$12(a0)

Obj37_ChkDel:
		subq.b  #1,$1F(a0)  ; Subtract 1
        beq.w   DeleteObject       ; If 0, delete
		cmpi.w	#$FF00,($FFFFF72C).w		; is vertical wrapping enabled?
		beq.w	DisplaySprite			; if so, branch
		move.w	($FFFFF72E).w,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	   ; has object moved below level boundary?
		bcs.s	Obj37_Delete	   ; if yes, branch	
		btst	#0, $1F(a0) ; Test the first bit of the timer, so rings flash every other frame.
		beq.w	DisplaySprite      ; If the bit is 0, the ring will appear.
		cmpi.b	#80,$1F(a0) ; Rings will flash during last 80 steps of their life.
		bhi.w	DisplaySprite      ; If the timer is higher than 80, obviously the rings will STAY visible.
		rts
; ===========================================================================

Obj37_Collect:				; XREF: Obj37_Index
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.w	#$80,Obj_Priority(a0)
		bsr.w	CollectRing

Obj37_Sparkle:				; XREF: Obj37_Index
		lea	(Ani_obj25).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Obj37_Delete:				; XREF: Obj37_Index
		bra.w	DeleteObject
; ===========================================================================

; ----------------------------------------------------------------------------
; Object 07 - Attracted ring (ported from Sonic and Knuckles)
; ----------------------------------------------------------------------------
Obj07:
	moveq	#0,d0
	move.b	$24(a0),d0
	move.w	Obj07_subtbl(pc,d0.w),d1
	jmp	Obj07_subtbl(pc,d1.w)
; ===========================================================================
Obj07_subtbl:
	dc.w	Obj07_sub_0-Obj07_subtbl; 0
	dc.w	Obj07_sub_2-Obj07_subtbl; 2
	dc.w	Obj07_sub_4-Obj07_subtbl; 4
	dc.w	Obj07_sub_6-Obj07_subtbl; 6
	dc.w	Obj07_sub_8-Obj07_subtbl; 8
; ===========================================================================

Obj07_sub_0:
	addq.b	#2,$24(a0)
	move.w	8(a0),$32(a0)
	move.l	#Map_Obj25,4(a0)
	move.w	#$27B2,2(a0)
	move.b	#4,1(a0)
	move.w	#$100,Obj_Priority(a0)
	move.b	#$47,$20(a0)
	move.b	#8,Obj_SprWidth(a0)

Obj07_sub_2:
	bsr.w	Obj07_Move
	movea.w	$34(a0),a1
	btst	#0,($FFFFFE2C).w
	bne.s	Obj07_sub_3
	move.b	#$37,(a0)	; Load object 37 (scattered rings)
	move.b	#2,$24(a0)
	move.b	#-1,($FFFFFEC6).w

Obj07_sub_3:
	move.b	($FFFFFEC3).w,$1A(a0)
	move.w	$32(a0),d0
	bra.w	DisplaySprite
; ===========================================================================

Obj07_sub_4:
	addq.b	#2,$24(a0)
	move.b	#0,$20(a0)
	move.w	#$80,Obj_Priority(a0)
	subq.w	#1,(Perfect_rings_left).w
	bsr.w	CollectRing

Obj07_sub_6:
	lea	(Ani_obj25).l,a1
	bsr.w	AnimateSprite
	bra.w	DisplaySprite
; ===========================================================================

Obj07_sub_8:
	bra.w	DeleteObject

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj07_Move:
	movea.w	$34(a0),a1
	move.w	#$30,d1
	move.w	8(a1),d0
	cmp.w	8(a0),d0
	bcc.s	loc_1A956
	neg.w	d1
	tst.w	$10(a0)
	bmi.s	loc_1A960
	add.w	d1,d1
	add.w	d1,d1
	bra.s	loc_1A960
; ===========================================================================

loc_1A956:
	tst.w	$10(a0)
	bpl.s	loc_1A960
	add.w	d1,d1
	add.w	d1,d1

loc_1A960:
	add.w	d1,$10(a0)
	move.w	#$30,d1
	move.w	$C(a1),d0
	cmp.w	$C(a0),d0
	bcc.s	loc_1A980
	neg.w	d1
	tst.w	$12(a0)
	bmi.s	loc_1A988
	add.w	d1,d1
	add.w	d1,d1
	bra.s	loc_1A988
; ===========================================================================

loc_1A980:
	tst.w	$12(a0)
	bpl.s	loc_1A988
	add.w	d1,d1
	add.w	d1,d1

loc_1A988:
	add.w	d1,$12(a0)
	jmp	(SpeedtoPos).l
; ===========================================================================
Ani_obj25:
	include "_anim\obj25.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - rings
; ---------------------------------------------------------------------------
Map_obj25:
	include "_maps\obj25.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 26 - monitors
; ---------------------------------------------------------------------------

Obj26:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj26_Index(pc,d0.w),d1
		jmp	Obj26_Index(pc,d1.w)
; ===========================================================================
Obj26_Index:	dc.w Obj26_Main-Obj26_Index
		dc.w Obj26_Solid-Obj26_Index
		dc.w Obj26_BreakOpen-Obj26_Index
		dc.w Obj26_Animate-Obj26_Index
		dc.w Obj26_Display-Obj26_Index
; ===========================================================================

Obj26_Main:				; XREF: Obj26_Index
		addq.b	#2,$24(a0)
		move.b	#$E,$16(a0)
		move.b	#$E,$17(a0)
		move.l	#Map_obj26,4(a0)
		move.w	#$680,2(a0)
		move.b	#4,1(a0)
		move.w	#$180,Obj_Priority(a0)
		move.b	#$F,Obj_SprWidth(a0)
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		movea.w	d0,a2	; load address into a2
		btst	#0,(a2)	; has monitor been broken?
		beq.s	Obj26_NotBroken	; if not, branch
		move.b	#8,$24(a0)	; run "Obj26_Display" routine
		move.b	#$B,$1A(a0)	; use broken monitor frame
		rts	
; ===========================================================================

Obj26_NotBroken:			; XREF: Obj26_Main
		move.b	#$46,$20(a0)
		move.b	$28(a0),$1C(a0)

Obj26_Solid:				; XREF: Obj26_Index
		move.b	$25(a0),d0	; is monitor set to fall?
		beq.s	loc_A1EC	; if not, branch
		subq.b	#2,d0
		bne.s	Obj26_Fall
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,$22(a1)
		bne.w	loc_A1BC
		clr.b	$25(a0)
		bra.w	Obj26_Animate
; ===========================================================================

loc_A1BC:				; XREF: Obj26_Solid
		move.w	#$10,d3
		move.w	8(a0),d2
		bsr.w	MvSonicOnPtfm
		bra.w	Obj26_Animate
; ===========================================================================

Obj26_Fall:				; XREF: Obj26_Solid
		bsr.w	ObjectFall
		jsr	ObjHitFloor
		tst.w	d1
		bpl.w	Obj26_Animate
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	$25(a0)
		bra.w	Obj26_Animate
; ===========================================================================

loc_A1EC:				; XREF: Obj26_Solid
		move.w	#$1A,d1
		move.w	#$F,d2
		bsr.w	Obj26_SolidSides
		beq.w	loc_A25C
		tst.w	$12(a1)
		bmi.s	loc_A20A
		cmpi.b	#2,$1C(a1)	; is Sonic rolling?
		beq.s	loc_A25C	; if yes, branch
		cmpi.b	#$1F,$1C(a1)	; is Sonic spin-dashing?
		beq.s	loc_A25C	; if yes, branch

loc_A20A:
		tst.w	d1
		bpl.s	loc_A220
		sub.w	d3,$C(a1)
		bsr.w	loc_74AE
		move.b	#2,$25(a0)
		bra.w	Obj26_Animate
; ===========================================================================

loc_A220:
		tst.w	d0
		beq.w	loc_A246
		bmi.s	loc_A230
		tst.w	$10(a1)
		bmi.s	loc_A246
		bra.s	loc_A236
; ===========================================================================

loc_A230:
		tst.w	$10(a1)
		bpl.s	loc_A246

loc_A236:
		sub.w	d0,8(a1)
		move.w	#0,Obj_Inertia(a1)
		move.w	#0,$10(a1)

loc_A246:
		btst	#1,$22(a1)
		bne.s	loc_A26A
		bset	#5,$22(a1)
		bset	#5,$22(a0)
		bra.s	Obj26_Animate
; ===========================================================================

loc_A25C:
		btst	#5,$22(a0)
		beq.s	Obj26_Animate
		cmp.b	#2,$1C(a1)	; check if in jumping/rolling animation
		beq.s	loc_A26A
		cmp.b	#$17,$1C(a1)	; check if in drowning animation
		beq.s	loc_A26A
		move.w	#1,$1C(a1)

loc_A26A:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)

Obj26_Animate:				; XREF: Obj26_Index
		lea	(Ani_obj26).l,a1
		bsr.w	AnimateSprite

Obj26_Display:				; XREF: Obj26_Index
		bra.w	MarkObjGone
; ===========================================================================

Obj26_BreakOpen:			; XREF: Obj26_Index
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		bsr.w	SingleObjLoad
		bne.s	Obj26_Explode
		move.b	#$2E,0(a1)	; load monitor contents	object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$1C(a0),$1C(a1)

Obj26_Explode:
		bsr.w	SingleObjLoad
		bne.s	Obj26_SetBroken
		move.b	#$27,0(a1)	; load explosion object
		addq.b	#2,$24(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Obj26_SetBroken:
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		movea.w	d0,a2	; load address into a2
		bset	#0,(a2)
		move.b	#9,$1C(a0)	; set monitor type to broken
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2E - contents of monitors
; ---------------------------------------------------------------------------

Obj2E:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2E_Index(pc,d0.w),d1
		jsr	Obj2E_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Obj2E_Index:	dc.w Obj2E_Main-Obj2E_Index
		dc.w Obj2E_Move-Obj2E_Index
		dc.w Obj2E_Delete-Obj2E_Index
; ===========================================================================

Obj2E_Main:				; XREF: Obj2E_Index
		addq.b	#2,$24(a0)
		move.w	#$680,2(a0)
		move.b	#$24,1(a0)
		move.w	#$180,Obj_Priority(a0)
		move.b	#8,Obj_SprWidth(a0)
		move.w	#-$300,$12(a0)
		moveq	#0,d0
		move.b	$1C(a0),d0
		addq.b	#2,d0
		move.b	d0,$1A(a0)
		movea.l	#Map_obj26,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#1,a1
		move.l	a1,4(a0)

Obj2E_Move:				; XREF: Obj2E_Index
		tst.w	$12(a0)		; is object moving?
		bpl.w	Obj2E_ChkEggman	; if not, branch
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)	; reduce object	speed
		rts	
; ===========================================================================

Obj2E_ChkEggman:    ; XREF: Obj2E_Move
        addq.b    #2,$24(a0)
        move.w    #29,$1E(a0)
        move.b    $1C(a0),d0
        cmpi.b    #1,d0; does monitor contain Eggman?
        bne.s    Obj2E_ChkSonic ; if not, go and check for the next monitor type (1-up icon)
        move.l    a0,a1 ; move a0 to a1, because Touch_ChkHurt wants the damaging object to be in a1
        move.l    a0,-(sp)
        lea    ($FFFFD000).w,a0 ; put Sonic's ram address in a0, because Touch_ChkHurt wants the damaged object to be in a0
        jsr    Touch_ChkHurt ; run the Touch_ChkHurt routine
        move.l    (sp)+,a0
        rts
; ===========================================================================

Obj2E_ChkSonic:
		cmpi.b	#2,d0		; does monitor contain Sonic?
		bne.s	Obj2E_ChkShoes

ExtraLife:
		addq.b	#1,($FFFFFE12).w ; add 1 to the	number of lives	you have
		addq.b	#1,($FFFFFE1C).w ; add 1 to the	lives counter
		move.w	#$88,d0
		jmp	(PlaySound).l	; play extra life music
; ===========================================================================

Obj2E_ChkShoes:
		cmpi.b	#3,d0		; does monitor contain speed shoes?
		bne.s	Obj2E_ChkShield
		move.b	#1,($FFFFFE2E).w ; speed up the	BG music
		move.w	#$4B0,($FFFFD034).w ; time limit for the power-up
		move.w	#$C00,($FFFFF760).w ; change Sonic's top speed
		move.w	#$18,($FFFFF762).w
		move.w	#$80,($FFFFF764).w
		move.w	#$E2,d0
		jmp	(PlaySound).l	; Speed	up the music
; ===========================================================================

Obj2E_ChkShield:
		cmpi.b	#4,d0		; does monitor contain a shield?
		bne.s	Obj2E_ChkInvinc
		move.b	#1,($FFFFFE2C).w ; give	Sonic a	shield
		move.b	#$38,($FFFFD180).w ; load shield object	($38)
		move.w	#$AF,d0
		jmp	(PlaySound).l	; play shield sound
; ===========================================================================

Obj2E_ChkInvinc:
		cmpi.b	#5,d0		; does monitor contain invincibility?
		bne.s	Obj2E_ChkRings
		move.b	#1,($FFFFFE2D).w ; make	Sonic invincible
		move.w	#$4B0,($FFFFD032).w ; time limit for the power-up
		move.b	#$38,($FFFFD200).w ; load stars	object ($3801)
		move.b	#1,($FFFFD21C).w
		move.b	#$38,($FFFFD240).w ; load stars	object ($3802)
		move.b	#2,($FFFFD25C).w
		move.b	#$38,($FFFFD280).w ; load stars	object ($3803)
		move.b	#3,($FFFFD29C).w
		move.b	#$38,($FFFFD2C0).w ; load stars	object ($3804)
		move.b	#4,($FFFFD2DC).w
		tst.b	($FFFFF7AA).w	; is boss mode on?
		bne.s	Obj2E_NoMusic	; if yes, branch
		move.w	#$87,d0
		jmp	(PlaySound).l	; play invincibility music
; ===========================================================================

Obj2E_NoMusic:
		rts	
; ===========================================================================

Obj2E_ChkRings:
		cmpi.b	#6,d0		; does monitor contain 10 rings?
		bne.s	Obj2E_ChkS
		addi.w	#$A,($FFFFFE20).w ; add	10 rings to the	number of rings	you have
		ori.b	#1,($FFFFFE1D).w ; update the ring counter
		cmpi.w	#100,($FFFFFE20).w ; check if you have 100 rings
		bcs.s	Obj2E_RingSound
		bset	#1,($FFFFFE1B).w
		beq.w	ExtraLife
		cmpi.w	#200,($FFFFFE20).w ; check if you have 200 rings
		bcs.s	Obj2E_RingSound
		bset	#2,($FFFFFE1B).w
		beq.w	ExtraLife

Obj2E_RingSound:
		move.w	#$B5,d0
		jmp	(PlaySound).l	; play ring sound
; ===========================================================================

Obj2E_ChkS:
		cmpi.b	#7,d0		; does monitor contain 'S'
		bne.s	Obj2E_ChkEnd
		nop	

Obj2E_ChkEnd:
		rts			; 'S' and goggles monitors do nothing
; ===========================================================================

Obj2E_Delete:				; XREF: Obj2E_Index
		subq.w	#1,$1E(a0)
		bmi.w	DeleteObject
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	make the sides of a monitor solid
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj26_SolidSides:			; XREF: loc_A1EC
		lea	($FFFFD000).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_A4E6
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_A4E6
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		add.w	d2,d3
		bmi.s	loc_A4E6
		add.w	d2,d2
		cmp.w	d2,d3
		bcc.s	loc_A4E6
		tst.b	($FFFFF7C8).w
		bmi.s	loc_A4E6
		cmpi.b	#6,($FFFFD024).w
		bcc.s	loc_A4E6
		tst.w	($FFFFFE08).w
		bne.s	loc_A4E6
		cmp.w	d0,d1
		bcc.s	loc_A4DC
		add.w	d1,d1
		sub.w	d1,d0

loc_A4DC:
		cmpi.w	#$10,d3
		bcs.s	loc_A4EA

loc_A4E2:
		moveq	#1,d1
		rts	
; ===========================================================================

loc_A4E6:
		moveq	#0,d1
		rts	
; ===========================================================================

loc_A4EA:
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addq.w	#4,d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.s	loc_A4E2
		cmp.w	d2,d1
		bcc.s	loc_A4E2
		moveq	#-1,d1
		rts	
; End of function Obj26_SolidSides

; ===========================================================================
Ani_obj26:
	include "_anim\obj26.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - monitors
; ---------------------------------------------------------------------------
Map_obj26:
	include "_maps\obj26.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	animate	a sprite using an animation script
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AnimateSprite:
		moveq	#0,d0
		move.b	$1C(a0),d0	; move animation number	to d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.s	Anim_Run	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

Anim_Run:
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	Anim_Wait	; if time remains, branch
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),$1E(a0)	; load frame duration
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		cmp.b	#$FA,d0					; MJ: is it a flag from FA to FF?
		bhs	Anim_End_FF				; MJ: if so, branch to flag routines

Anim_Next:
		move.b	d0,d1
		andi.b	#$1F,d0
		move.b	d0,$1A(a0)	; load sprite number
		move.b	$22(a0),d0
		rol.b	#3,d1
		eor.b	d0,d1
		andi.b	#3,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		addq.b	#1,$1B(a0)	; next frame number

Anim_Wait:
		rts	
; ===========================================================================

Anim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.s	Anim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.s	Anim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.s	Anim_End_FC	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

Anim_End_FC:
		addq.b	#1,d0		; is the end flag = $FC	?
		bne.s	Anim_End_FB	; if not, branch
		addq.b	#2,$24(a0)	; jump to next routine

Anim_End_FB:
		addq.b	#1,d0		; is the end flag = $FB	?
		bne.s	Anim_End_FA	; if not, branch
		move.b	#0,$1B(a0)	; reset	animation
		clr.b	$25(a0)		; reset	2nd routine counter

Anim_End_FA:
		addq.b	#1,d0		; is the end flag = $FA	?
		bne.s	Anim_End	; if not, branch
		addq.b	#2,$25(a0)	; jump to next routine

Anim_End:
		rts	
; End of function AnimateSprite

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 32 - switches (MZ, SYZ, LZ, SBZ)
; ---------------------------------------------------------------------------

Obj32:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj32_Index(pc,d0.w),d1
		jmp	Obj32_Index(pc,d1.w)
; ===========================================================================
Obj32_Index:	dc.w Obj32_Main-Obj32_Index
		dc.w Obj32_Pressed-Obj32_Index
; ===========================================================================

Obj32_Main:				; XREF: Obj32_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj32,4(a0)
		move.w	#$4513,2(a0)	; MZ specific code
		cmpi.b	#2,($FFFFFE10).w
		beq.s	loc_BD60
		move.w	#$513,2(a0)	; SYZ, LZ and SBZ specific code

loc_BD60:
		move.b	#4,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$200,Obj_Priority(a0)
		addq.w	#3,$C(a0)

Obj32_Pressed:				; XREF: Obj32_Index
		tst.b	1(a0)
		bpl.s	Obj32_Display
		move.w	#$1B,d1
		move.w	#5,d2
		move.w	#5,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		bclr	#0,$1A(a0)	; use "unpressed" frame
		move.b	$28(a0),d0
		andi.w	#$F,d0
		lea	($FFFFF7E0).w,a3
		lea	(a3,d0.w),a3
		moveq	#0,d3
		btst	#6,$28(a0)
		beq.s	loc_BDB2
		moveq	#7,d3

loc_BDB2:
		tst.b	$28(a0)
		bpl.s	loc_BDBE
		bsr.w	Obj32_MZBlock
		bne.s	loc_BDC8

loc_BDBE:
		tst.b	$25(a0)
		bne.s	loc_BDC8
		bclr	d3,(a3)
		bra.s	loc_BDDE
; ===========================================================================

loc_BDC8:
		tst.b	(a3)
		bne.s	loc_BDD6
		move.w	#$CD,d0
		jsr	(PlaySound_Special).l ;	play switch sound

loc_BDD6:
		bset	d3,(a3)
		bset	#0,$1A(a0)	; use "pressed"	frame

loc_BDDE:
		btst	#5,$28(a0)
		beq.s	Obj32_Display
		subq.b	#1,$1E(a0)
		bpl.s	Obj32_Display
		move.b	#7,$1E(a0)
		bchg	#1,$1A(a0)

Obj32_Display:
		bsr.w	DisplaySprite
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj32_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj32_Delete		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj32_Delete	; and delete object

Obj32_NoDel:
		rts	
; ===========================================================================

Obj32_Delete:
		bsr.w	DeleteObject
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj32_MZBlock:				; XREF: Obj32_Pressed
		move.w	d3,-(sp)
		move.w	8(a0),d2
		move.w	$C(a0),d3
		subi.w	#$10,d2
		subq.w	#8,d3
		move.w	#$20,d4
		move.w	#$10,d5
		lea	($FFFFD800).w,a1 ; begin checking object RAM
		move.w	#$5F,d6

Obj32_MZLoop:
		tst.b	1(a1)
		bpl.s	loc_BE4E
		cmpi.b	#$33,(a1)	; is the object	a green	MZ block?
		beq.s	loc_BE5E	; if yes, branch

loc_BE4E:
		lea	$40(a1),a1	; check	next object
		dbf	d6,Obj32_MZLoop	; repeat $5F times

		move.w	(sp)+,d3
		moveq	#0,d0

locret_BE5A:
		rts	
; ===========================================================================
Obj32_MZData:	dc.b $10, $10
; ===========================================================================

loc_BE5E:				; XREF: Obj32_MZBlock
		moveq	#1,d0
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	Obj32_MZData-2(pc,d0.w),a2
		move.b	(a2)+,d1
		ext.w	d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_BE80
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_BE84
		bra.s	loc_BE4E
; ===========================================================================

loc_BE80:
		cmp.w	d4,d0
		bhi.s	loc_BE4E

loc_BE84:
		move.b	(a2)+,d1
		ext.w	d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.s	loc_BE9A
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	loc_BE9E
		bra.s	loc_BE4E
; ===========================================================================

loc_BE9A:
		cmp.w	d5,d0
		bhi.s	loc_BE4E

loc_BE9E:
		move.w	(sp)+,d3
		moveq	#1,d0
		rts	
; End of function Obj32_MZBlock

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - switches (MZ, SYZ, LZ, SBZ)
; ---------------------------------------------------------------------------
Map_obj32:
	include "_maps\obj32.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 33 - pushable blocks (MZ, LZ)
; ---------------------------------------------------------------------------

Obj33:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj33_Index(pc,d0.w),d1
		jmp	Obj33_Index(pc,d1.w)
; ===========================================================================
Obj33_Index:	dc.w Obj33_Main-Obj33_Index
		dc.w loc_BF6E-Obj33_Index
		dc.w loc_C02C-Obj33_Index

Obj33_Var:	dc.b $10, 0	; object width,	frame number
		dc.b $40, 1
; ===========================================================================

Obj33_Main:				; XREF: Obj33_Index
		addq.b	#2,$24(a0)
		move.b	#$F,$16(a0)
		move.b	#$F,$17(a0)
		move.l	#Map_obj33,4(a0)
		move.w	#$42B8,2(a0)	; MZ specific code
		cmpi.b	#1,($FFFFFE10).w
		bne.s	loc_BF16
		move.w	#$43DE,2(a0)	; LZ specific code

loc_BF16:
		move.b	#4,1(a0)
		move.w	#$180,Obj_Priority(a0)
		move.w	8(a0),$34(a0)
		move.w	$C(a0),$36(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		andi.w	#$E,d0
		lea	Obj33_Var(pc,d0.w),a2
		move.b	(a2)+,Obj_SprWidth(a0)
		move.b	(a2)+,$1A(a0)
		tst.b	$28(a0)
		beq.s	Obj33_ChkGone
		move.w	#$C2B8,2(a0)

Obj33_ChkGone:
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	loc_BF6E		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bset	#0,(a2)
		bne.w	DeleteObject

loc_BF6E:				; XREF: Obj33_Index
		tst.b	$32(a0)
		bne.w	loc_C046
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	loc_C186
		cmpi.w	#$200,($FFFFFE10).w ; is the level MZ act 1?
		bne.s	loc_BFC6	; if not, branch
		bclr	#7,$28(a0)
		move.w	8(a0),d0
		cmpi.w	#$A20,d0
		bcs.s	loc_BFC6
		cmpi.w	#$AA1,d0
		bcc.s	loc_BFC6
		move.w	($FFFFF7A4).w,d0
		subi.w	#$1C,d0
		move.w	d0,$C(a0)
		bset	#7,($FFFFF7A4).w
		bset	#7,$28(a0)

loc_BFC6:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.w	DisplaySprite
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	loc_BFE6	; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
; ===========================================================================

loc_BFE6:
		move.w	$34(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	loc_C016
		move.w	$34(a0),8(a0)
		move.w	$36(a0),$C(a0)
		move.b	#4,$24(a0)
		bra.s	loc_C02C
; ===========================================================================

loc_C016:
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	loc_C028		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#0,(a2)

loc_C028:
		bra.w	DeleteObject
; ===========================================================================

loc_C02C:				; XREF: Obj33_Index
		bsr.w	ChkObjOnScreen2
		beq.s	locret_C044
		move.b	#2,$24(a0)
		clr.b	$32(a0)
		clr.w	$10(a0)
		clr.w	$12(a0)

locret_C044:
		rts	
; ===========================================================================

loc_C046:				; XREF: loc_BF6E
		move.w	8(a0),-(sp)
		cmpi.b	#4,$25(a0)
		bcc.s	loc_C056
		bsr.w	SpeedToPos

loc_C056:
		btst	#1,$22(a0)
		beq.s	loc_C0A0
		addi.w	#$18,$12(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.w	loc_C09E
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		bclr	#1,$22(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		bcs.s	loc_C09E
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,$10(a0)
		move.b	#1,$32(a0)
		clr.w	$E(a0)

loc_C09E:
		bra.s	loc_C0E6
; ===========================================================================

loc_C0A0:
		tst.w	$10(a0)
		beq.w	loc_C0D6
		bmi.s	loc_C0BC
		moveq	#0,d3
		move.b	Obj_SprWidth(a0),d3
		jsr	ObjHitWallRight
		tst.w	d1		; has block touched a wall?
		bmi.s	Obj33_StopPush	; if yes, branch
		bra.s	loc_C0E6
; ===========================================================================

loc_C0BC:
		moveq	#0,d3
		move.b	Obj_SprWidth(a0),d3
		not.w	d3
		jsr	ObjHitWallLeft
		tst.w	d1		; has block touched a wall?
		bmi.s	Obj33_StopPush	; if yes, branch
		bra.s	loc_C0E6
; ===========================================================================

Obj33_StopPush:
		clr.w	$10(a0)		; stop block moving
		bra.s	loc_C0E6
; ===========================================================================

loc_C0D6:
		addi.l	#$2001,$C(a0)
		cmpi.b	#-$60,$F(a0)
		bcc.s	loc_C104

loc_C0E6:
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	(sp)+,d4
		bsr.w	loc_C186
		bsr.s	Obj33_ChkLava
		bra.w	loc_BFC6
; ===========================================================================

loc_C104:
		move.w	(sp)+,d4
		lea	($FFFFD000).w,a1
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)
		bra.w	loc_BFE6
; ===========================================================================

Obj33_ChkLava:
		cmpi.w	#$201,($FFFFFE10).w ; is the level MZ act 2?
		bne.s	Obj33_ChkLava2	; if not, branch
		move.w	#-$20,d2
		cmpi.w	#$DD0,8(a0)
		beq.s	Obj33_LoadLava
		cmpi.w	#$CC0,8(a0)
		beq.s	Obj33_LoadLava
		cmpi.w	#$BA0,8(a0)
		beq.s	Obj33_LoadLava
		rts	
; ===========================================================================

Obj33_ChkLava2:
		cmpi.w	#$202,($FFFFFE10).w ; is the level MZ act 3?
		bne.s	Obj33_NoLava	; if not, branch
		move.w	#$20,d2
		cmpi.w	#$560,8(a0)
		beq.s	Obj33_LoadLava
		cmpi.w	#$5C0,8(a0)
		beq.s	Obj33_LoadLava

Obj33_NoLava:
		rts	
; ===========================================================================

Obj33_LoadLava:
		bsr.w	SingleObjLoad
		bne.s	locret_C184
		move.b	#$4C,0(a1)	; load lava geyser object
		move.w	8(a0),8(a1)
		add.w	d2,8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$10,$C(a1)
		move.l	a0,$3C(a1)

locret_C184:
		rts	
; ===========================================================================

loc_C186:				; XREF: loc_BF6E
		move.b	$25(a0),d0
		beq.w	loc_C218
		subq.b	#2,d0
		bne.s	loc_C1AA
		bsr.w	ExitPlatform
		btst	#3,$22(a1)
		bne.s	loc_C1A4
		clr.b	$25(a0)
		rts	
; ===========================================================================

loc_C1A4:
		move.w	d4,d2
		bra.w	MvSonicOnPtfm
; ===========================================================================

loc_C1AA:
		subq.b	#2,d0
		bne.s	loc_C1F2
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.w	locret_C1F0
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	$25(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		bcs.s	locret_C1F0
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,$10(a0)
		move.b	#1,$32(a0)
		clr.w	$E(a0)

locret_C1F0:
		rts	
; ===========================================================================

loc_C1F2:
		bsr.w	SpeedToPos
		move.w	8(a0),d0
		andi.w	#$C,d0
		bne.w	locret_C2E4
		andi.w	#-$10,8(a0)
		move.w	$10(a0),$30(a0)
		clr.w	$10(a0)
		subq.b	#2,$25(a0)
		rts	
; ===========================================================================

loc_C218:
		bsr.w	loc_FAC8
		tst.w	d4
		beq.w	locret_C2E4
		bmi.w	locret_C2E4
		tst.b	$32(a0)
		beq.s	loc_C230
		bra.w	locret_C2E4
; ===========================================================================

loc_C230:
		tst.w	d0
		beq.w	locret_C2E4
		bmi.s	loc_C268
		btst	#0,$22(a1)
		bne.w	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	Obj_SprWidth(a0),d3
		jsr	ObjHitWallRight
		move.w	(sp)+,d0
		tst.w	d1
		bmi.w	locret_C2E4
		addi.l	#$10000,8(a0)
		moveq	#1,d0
		move.w	#$40,d1
		bra.s	loc_C294
; ===========================================================================

loc_C268:
		btst	#0,$22(a1)
		beq.s	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	Obj_SprWidth(a0),d3
		not.w	d3
		jsr	ObjHitWallLeft
		move.w	(sp)+,d0
		tst.w	d1
		bmi.s	locret_C2E4
		subi.l	#$10000,8(a0)
		moveq	#-1,d0
		move.w	#-$40,d1

loc_C294:
		lea	($FFFFD000).w,a1
		add.w	d0,8(a1)
		move.w	d1,Obj_Inertia(a1)
		move.w	#0,$10(a1)
		move.w	d0,-(sp)
		move.w	#$A7,d0
		jsr	(PlaySound_Special).l ;	play pushing sound
		move.w	(sp)+,d0
		tst.b	$28(a0)
		bmi.s	locret_C2E4
		move.w	d0,-(sp)
		jsr	ObjHitFloor
		move.w	(sp)+,d0
		cmpi.w	#4,d1
		ble.s	loc_C2E0
		move.w	#$400,$10(a0)
		tst.w	d0
		bpl.s	loc_C2D8
		neg.w	$10(a0)

loc_C2D8:
		move.b	#6,$25(a0)
		bra.s	locret_C2E4
; ===========================================================================

loc_C2E0:
		add.w	d1,$C(a0)

locret_C2E4:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - pushable blocks (MZ, LZ)
; ---------------------------------------------------------------------------
Map_obj33:
	include "_maps\obj33.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 34 - zone title cards
; ---------------------------------------------------------------------------

Obj34:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj34_Index(pc,d0.w),d1
		jmp	Obj34_Index(pc,d1.w)
; ===========================================================================
Obj34_Index:	dc.w Obj34_CheckSBZ3-Obj34_Index
		dc.w Obj34_ChkPos-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
; ===========================================================================

Obj34_CheckSBZ3:			; XREF: Obj34_Index
		movea.l	a0,a1
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		cmpi.w	#$103,($FFFFFE10).w ; check if level is	SBZ 3
		bne.s	Obj34_CheckFZ
		moveq	#5,d0		; load title card number 5 (SBZ)

Obj34_CheckFZ:
		move.w	d0,d2
		cmpi.w	#$502,($FFFFFE10).w ; check if level is	FZ
		bne.s	Obj34_LoadConfig
		moveq	#6,d0		; load title card number 6 (FZ)
		moveq	#$B,d2		; use "FINAL" mappings

Obj34_LoadConfig:
		lea	(Obj34_ConData).l,a3
		lsl.w	#4,d0
		adda.w	d0,a3
		lea	(Obj34_ItemData).l,a2
		moveq	#3,d1

Obj34_Loop:
		move.b	#$34,0(a1)
		move.w	(a3),8(a1)	; load start x-position
		move.w	(a3)+,$32(a1)	; load finish x-position (same as start)
		move.w	(a3)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,d0
		bne.s	Obj34_ActNumber
		move.b	d2,d0

Obj34_ActNumber:
		cmpi.b	#7,d0
		bne.s	Obj34_MakeSprite
		add.b	($FFFFFE11).w,d0
		cmpi.b	#3,($FFFFFE11).w
		bne.s	Obj34_MakeSprite
		subq.b	#1,d0

Obj34_MakeSprite:
		move.b	d0,$1A(a1)	; display frame	number d0
		move.l	#Map_obj34,4(a1)
		move.w	#$8580,2(a1)
		move.b	#$78,Obj_SprWidth(a1)
		move.b	#0,1(a1)
		move.w	#0,Obj_Priority(a1)
		move.w	#60,$1E(a1)	; set time delay to 1 second
		lea	$40(a1),a1	; next object
		dbf	d1,Obj34_Loop	; repeat sequence another 3 times

Obj34_ChkPos:				; XREF: Obj34_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached the target position?
		beq.s	loc_C3C8	; if yes, branch
		bge.s	Obj34_Move
		neg.w	d1

Obj34_Move:
		add.w	d1,8(a0)	; change item's position

loc_C3C8:
		move.w	8(a0),d0
		bmi.s	locret_C3D8
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C3D8	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C3D8:
		rts	
; ===========================================================================

Obj34_Wait:				; XREF: Obj34_Index
		tst.w	$1E(a0)		; is time remaining zero?
		beq.s	Obj34_ChkPos2	; if yes, branch
		subq.w	#1,$1E(a0)	; subtract 1 from time
		bra.w	DisplaySprite
; ===========================================================================

Obj34_ChkPos2:				; XREF: Obj34_Wait
		tst.b	1(a0)
		bpl.s	Obj34_ChangeArt
		moveq	#$20,d1
		move.w	$32(a0),d0
		cmp.w	8(a0),d0	; has item reached the finish position?
		beq.s	Obj34_ChangeArt	; if yes, branch
		bge.s	Obj34_Move2
		neg.w	d1

Obj34_Move2:
		add.w	d1,8(a0)	; change item's position
		move.w	8(a0),d0
		bmi.s	locret_C412
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C412	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C412:
		rts	
; ===========================================================================

Obj34_ChangeArt:			; XREF: Obj34_ChkPos2
		cmpi.b	#4,$24(a0)
		bne.s	Obj34_Delete
		moveq	#PLCID_Explode,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		addi.w	#PLCID_GHZAnimals,d0
		jsr	(LoadPLC).l	; load animal patterns

Obj34_Delete:
		bra.w	DeleteObject
; ===========================================================================
Obj34_ItemData:	dc.w $D0	; y-axis position
		dc.b 2,	0	; routine number, frame	number (changes)
		dc.w $E4
		dc.b 2,	6
		dc.w $EA
		dc.b 2,	7
		dc.w $E0
		dc.b 2,	$A
; ---------------------------------------------------------------------------
; Title	card configuration data
; Format:
; 4 bytes per item (YYYY XXXX)
; 4 items per level (GREEN HILL, ZONE, ACT X, oval)
; ---------------------------------------------------------------------------
Obj34_ConData:	dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; GHZ
		dc.w 0,	$120, $FEF4, $134, $40C, $14C, $20C, $14C ; LZ
		dc.w 0,	$120, $FEE0, $120, $3F8, $138, $1F8, $138 ; MZ
		dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; SLZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SYZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SBZ
		dc.w 0,	$120, $FEE4, $124, $3EC, $3EC, $1EC, $12C ; FZ
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 39 - "GAME OVER" and "TIME OVER"
; ---------------------------------------------------------------------------

Obj39:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj39_Index(pc,d0.w),d1
		jmp	Obj39_Index(pc,d1.w)
; ===========================================================================
Obj39_Index:	dc.w Obj39_ChkPLC-Obj39_Index
		dc.w loc_C50C-Obj39_Index
		dc.w Obj39_Wait-Obj39_Index
; ===========================================================================

Obj39_ChkPLC:				; XREF: Obj39_Index
		tst.l	($FFFFF680).w	; are the pattern load cues empty?
		beq.s	Obj39_Main	; if yes, branch
		rts	
; ===========================================================================

Obj39_Main:
		addq.b	#2,$24(a0)
		move.w	#$50,8(a0)	; set x-position
		btst	#0,$1A(a0)	; is the object	"OVER"?
		beq.s	loc_C4EC	; if not, branch
		move.w	#$1F0,8(a0)	; set x-position for "OVER"

loc_C4EC:
		move.w	#$F0,$A(a0)
		move.l	#Map_obj39,4(a0)
		move.w	#$855E,2(a0)
		move.b	#0,1(a0)
		move.w	#0,Obj_Priority(a0)

loc_C50C:				; XREF: Obj39_Index
		moveq	#$10,d1		; set horizontal speed
		cmpi.w	#$120,8(a0)	; has item reached its target position?
		beq.s	Obj39_SetWait	; if yes, branch
		bcs.s	Obj39_Move
		neg.w	d1

Obj39_Move:
		add.w	d1,8(a0)	; change item's position
		bra.w	DisplaySprite
; ===========================================================================

Obj39_SetWait:				; XREF: Obj39_Main
		move.w	#720,$1E(a0)	; set time delay to 12 seconds
		addq.b	#2,$24(a0)
		rts	
; ===========================================================================

Obj39_Wait:				; XREF: Obj39_Index
		move.b	($FFFFF605).w,d0
		andi.b	#$70,d0		; is button A, B or C pressed?
		bne.s	Obj39_ChgMode	; if yes, branch
		btst	#0,$1A(a0)
		bne.s	Obj39_Display
		tst.w	$1E(a0)		; has time delay reached zero?
		beq.s	Obj39_ChgMode	; if yes, branch
		subq.w	#1,$1E(a0)	; subtract 1 from time delay
		bra.w	DisplaySprite
; ===========================================================================

Obj39_ChgMode:				; XREF: Obj39_Wait
		tst.b	($FFFFFE1A).w	; is time over flag set?
		bne.s	Obj39_ResetLvl	; if yes, branch
		move.b	#ScnID_SEGA,($FFFFF600).w ; set mode to 0 (Sega screen)
		bra.s	Obj39_Display
; ===========================================================================

Obj39_ResetLvl:				; XREF: Obj39_ChgMode
		move.w	#1,($FFFFFE02).w ; restart level

Obj39_Display:				; XREF: Obj39_ChgMode
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3A - "SONIC GOT THROUGH" title	card
; ---------------------------------------------------------------------------

Obj3A:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3A_Index(pc,d0.w),d1
		jmp	Obj3A_Index(pc,d1.w)
; ===========================================================================
Obj3A_Index:	dc.w Obj3A_ChkPLC-Obj3A_Index
		dc.w Obj3A_ChkPos-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_TimeBonus-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_NextLevel-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_ChkPos2-Obj3A_Index
		dc.w loc_C766-Obj3A_Index
; ===========================================================================

Obj3A_ChkPLC:				; XREF: Obj3A_Index
		tst.l	($FFFFF680).w	; are the pattern load cues empty?
		beq.s	Obj3A_Main	; if yes, branch
		rts	
; ===========================================================================

Obj3A_Main:
        move.w    #$E0,d0
        jsr    (PlaySound_Special).l ;    fade out music
		movea.l	a0,a1
		lea	(Obj3A_Config).l,a2
		moveq	#6,d1

Obj3A_Loop:
		move.b	#$3A,0(a1)
		move.w	(a2),8(a1)	; load start x-position
		move.w	(a2)+,$32(a1)	; load finish x-position (same as start)
		move.w	(a2)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)	; load y-position
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,d0
		cmpi.b	#6,d0
		bne.s	loc_C5CA
		add.b	($FFFFFE11).w,d0 ; add act number to frame number

loc_C5CA:
		move.b	d0,$1A(a1)
		move.l	#Map_obj3A,4(a1)
		move.w	#$8580,2(a1)
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbf	d1,Obj3A_Loop	; repeat 6 times

Obj3A_ChkPos:				; XREF: Obj3A_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached its target position?
		beq.s	loc_C61A	; if yes, branch
		bge.s	Obj3A_Move
		neg.w	d1

Obj3A_Move:
		add.w	d1,8(a0)	; change item's position

loc_C5FE:				; XREF: loc_C61A
		move.w	8(a0),d0
		bmi.s	locret_C60E
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C60E	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C60E:
		rts	
; ===========================================================================

loc_C610:				; XREF: loc_C61A
		move.b	#$E,$24(a0)
		bra.w	Obj3A_ChkPos2
; ===========================================================================

loc_C61A:				; XREF: Obj3A_ChkPos
		cmpi.b	#$E,($FFFFD724).w
		beq.s	loc_C610
		cmpi.b	#4,$1A(a0)
		bne.s	loc_C5FE
        move.w    #$8E,d0
        jsr    (PlaySound_Special).l ;    play Got-Through Act music
		addq.b	#2,$24(a0)
		move.w	#180,$1E(a0)	; set time delay to 3 seconds

Obj3A_Wait:				; XREF: Obj3A_Index
		subq.w	#1,$1E(a0)	; subtract 1 from time delay
		bne.s	Obj3A_Display
		addq.b	#2,$24(a0)

Obj3A_Display:
		bra.w	DisplaySprite
; ===========================================================================

Obj3A_TimeBonus:            ; XREF: Obj3A_Index
        bsr.w    DisplaySprite
        move.b    #1,($FFFFF7D6).w ; set time/ring bonus update flag
        moveq    #0,d0
        btst    #6,($FFFFF605).w ; GIO: is the A button pressed?
        bne.s   Obj3A_SkipTally    ; GIO: if yes, branch
        tst.w    ($FFFFF7D2).w    ; is time bonus    = zero?
        beq.s    Obj3A_RingBonus    ; if yes, branch
        addi.w    #10,d0        ; add 10 to score
        subi.w    #10,($FFFFF7D2).w ; subtract 10    from time bonus

Obj3A_RingBonus:
        tst.w    ($FFFFF7D4).w    ; is ring bonus    = zero?
        beq.s    Obj3A_ChkBonus    ; if yes, branch
        addi.w    #10,d0        ; add 10 to score
        subi.w    #10,($FFFFF7D4).w ; subtract 10    from ring bonus

Obj3A_ChkBonus:
        tst.w    d0        ; is there any bonus?
        bne.s    Obj3A_AddBonus    ; if yes, branch
        bra.s   Obj3A_Common
 
    Obj3A_SkipTally:
        add.w    ($FFFFF7D2),d0     ; GIO: add the entire bonus to data register 0
        clr.w    ($FFFFF7D2).w         ; GIO: clear the time bonus
        add.w    ($FFFFF7D4).w,d0   ; GIO: add the entire bonus to d0
        clr.w    ($FFFFF7D4).w         ; GIO: clear the ring bonus
        jsr    AddPoints            ; GIO: add up the points stored in d0
 
    Obj3A_Common:
        move.w    #$C5,d0
        jsr    (PlaySound_Special).l ;    play "ker-ching" sound
        addq.b    #2,$24(a0)
        cmpi.w    #$501,($FFFFFE10).w
        bne.s    Obj3A_SetDelay
        addq.b    #4,$24(a0)

Obj3A_SetDelay:
        move.w    #180,$1E(a0)    ; set time delay to 3 seconds

locret_C692:
        rts
; ===========================================================================

Obj3A_AddBonus:				; XREF: Obj3A_ChkBonus
		jsr	AddPoints
		move.b	($FFFFFE0F).w,d0
		andi.b	#3,d0
		bne.s	locret_C692
		move.w	#$CD,d0
		jmp	(PlaySound_Special).l ;	play "blip" sound
; ===========================================================================

Obj3A_NextLevel:			; XREF: Obj3A_Index
		move.b	($FFFFFE10).w,d0
		andi.w	#7,d0
		lsl.w	#3,d0
		move.b	($FFFFFE11).w,d1
		andi.w	#3,d1
		add.w	d1,d1
		add.w	d1,d0
		move.w	LevelOrder(pc,d0.w),d0 ; load level from level order array
		move.w	d0,($FFFFFE10).w ; set level number
		tst.w	d0
		bne.s	Obj3A_RestartLevel
		move.b	#0,($FFFFF600).w ; set game mode to level (00)
		bra.s	Obj3A_Display2
; ===========================================================================

Obj3A_RestartLevel:				; XREF: Obj3A_NextLevel
		clr.b	($FFFFFE30).w	; clear	lamppost counter
		move.w	#1,($FFFFFE02).w ; restart level

Obj3A_Display2:				; XREF: Obj3A_NextLevel, Obj3A_RestartLevel
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Level	order array
; ---------------------------------------------------------------------------
LevelOrder:
	dc.w	$0001, $0000
; ===========================================================================

Obj3A_ChkPos2:				; XREF: Obj3A_Index
		moveq	#$20,d1		; set horizontal speed
		move.w	$32(a0),d0
		cmp.w	8(a0),d0	; has item reached its finish position?
		beq.s	Obj3A_SBZ2	; if yes, branch
		bge.s	Obj3A_Move2
		neg.w	d1

Obj3A_Move2:
		add.w	d1,8(a0)	; change item's position
		move.w	8(a0),d0
		bmi.s	locret_C748
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C748	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C748:
		rts	
; ===========================================================================

Obj3A_SBZ2:				; XREF: Obj3A_ChkPos2
		cmpi.b	#4,$1A(a0)
		bne.w	DeleteObject
		addq.b	#2,$24(a0)
		clr.b	($FFFFF7CC).w	; unlock controls
		move.w	#$8D,d0
		jmp	(PlaySound).l	; play FZ music
; ===========================================================================

loc_C766:				; XREF: Obj3A_Index
		addq.w	#2,($FFFFF72A).w
		cmpi.w	#$2100,($FFFFF72A).w
		beq.w	DeleteObject
		rts	
; ===========================================================================
Obj3A_Config:	dc.w 4,	$124, $BC	; x-start, x-main, y-main
		dc.b 2,	0		; routine number, frame	number (changes)
		dc.w $FEE0, $120, $D0
		dc.b 2,	1
		dc.w $40C, $14C, $D6
		dc.b 2,	6
		dc.w $520, $120, $EC
		dc.b 2,	2
		dc.w $540, $120, $FC
		dc.b 2,	3
		dc.w $560, $120, $10C
		dc.b 2,	4
		dc.w $20C, $14C, $CC
		dc.b 2,	5
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - zone title cards
; ---------------------------------------------------------------------------
Map_obj34:	dc.w byte_C9FE-Map_obj34
		dc.w byte_CA2C-Map_obj34
		dc.w byte_CA5A-Map_obj34
		dc.w byte_CA7A-Map_obj34
		dc.w byte_CAA8-Map_obj34
		dc.w byte_CADC-Map_obj34
		dc.w byte_CB10-Map_obj34
		dc.w byte_CB26-Map_obj34
		dc.w byte_CB31-Map_obj34
		dc.w byte_CB3C-Map_obj34
		dc.w byte_CB47-Map_obj34
		dc.w byte_CB8A-Map_obj34
byte_C9FE:	dc.b 9 			; GREEN HILL
		dc.b $F8, 5, 0,	$18, $B4
		dc.b $F8, 5, 0,	$3A, $C4
		dc.b $F8, 5, 0,	$10, $D4
		dc.b $F8, 5, 0,	$10, $E4
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	$1C, $14
		dc.b $F8, 1, 0,	$20, $24
		dc.b $F8, 5, 0,	$26, $2C
		dc.b $F8, 5, 0,	$26, $3C
byte_CA2C:	dc.b 9			; LABYRINTH
		dc.b $F8, 5, 0,	$26, $BC
		dc.b $F8, 5, 0,	0, $CC
		dc.b $F8, 5, 0,	4, $DC
		dc.b $F8, 5, 0,	$4A, $EC
		dc.b $F8, 5, 0,	$3A, $FC
		dc.b $F8, 1, 0,	$20, $C
		dc.b $F8, 5, 0,	$2E, $14
		dc.b $F8, 5, 0,	$42, $24
		dc.b $F8, 5, 0,	$1C, $34
byte_CA5A:	dc.b 6			; MARBLE
		dc.b $F8, 5, 0,	$2A, $CF
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3A, $F0
		dc.b $F8, 5, 0,	4, 0
		dc.b $F8, 5, 0,	$26, $10
		dc.b $F8, 5, 0,	$10, $20
		dc.b 0
byte_CA7A:	dc.b 9			; STAR	LIGHT
		dc.b $F8, 5, 0,	$3E, $B4
		dc.b $F8, 5, 0,	$42, $C4
		dc.b $F8, 5, 0,	0, $D4
		dc.b $F8, 5, 0,	$3A, $E4
		dc.b $F8, 5, 0,	$26, 4
		dc.b $F8, 1, 0,	$20, $14
		dc.b $F8, 5, 0,	$18, $1C
		dc.b $F8, 5, 0,	$1C, $2C
		dc.b $F8, 5, 0,	$42, $3C
byte_CAA8:	dc.b $A			; SPRING YARD
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	$36, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 1, 0,	$20, $DC
		dc.b $F8, 5, 0,	$2E, $E4
		dc.b $F8, 5, 0,	$18, $F4
		dc.b $F8, 5, 0,	$4A, $14
		dc.b $F8, 5, 0,	0, $24
		dc.b $F8, 5, 0,	$3A, $34
		dc.b $F8, 5, 0,	$C, $44
		dc.b 0
byte_CADC:	dc.b $A			; SCRAP BRAIN
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	8, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 5, 0,	0, $DC
		dc.b $F8, 5, 0,	$36, $EC
		dc.b $F8, 5, 0,	4, $C
		dc.b $F8, 5, 0,	$3A, $1C
		dc.b $F8, 5, 0,	0, $2C
		dc.b $F8, 1, 0,	$20, $3C
		dc.b $F8, 5, 0,	$2E, $44
		dc.b 0
byte_CB10:	dc.b 4			; ZONE
		dc.b $F8, 5, 0,	$4E, $E0
		dc.b $F8, 5, 0,	$32, $F0
		dc.b $F8, 5, 0,	$2E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b 0
byte_CB26:	dc.b 2			; ACT 1
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 2, 0,	$57, $C
byte_CB31:	dc.b 2			; ACT 2
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$5A, 8
byte_CB3C:	dc.b 2			; ACT 3
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$60, 8
byte_CB47:	dc.b $D			; Oval
		dc.b $E4, $C, 0, $70, $F4
		dc.b $E4, 2, 0,	$74, $14
		dc.b $EC, 4, 0,	$77, $EC
		dc.b $F4, 5, 0,	$79, $E4
		dc.b $14, $C, $18, $70,	$EC
		dc.b 4,	2, $18,	$74, $E4
		dc.b $C, 4, $18, $77, 4
		dc.b $FC, 5, $18, $79, $C
		dc.b $EC, 8, 0,	$7D, $FC
		dc.b $F4, $C, 0, $7C, $F4
		dc.b $FC, 8, 0,	$7C, $F4
		dc.b 4,	$C, 0, $7C, $EC
		dc.b $C, 8, 0, $7C, $EC
		dc.b 0
byte_CB8A:	dc.b 5			; FINAL
		dc.b $F8, 5, 0,	$14, $DC
		dc.b $F8, 1, 0,	$20, $EC
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	0, 4
		dc.b $F8, 5, 0,	$26, $14
		even
; ---------------------------------------------------------------------------
; Sprite mappings - "GAME OVER"	and "TIME OVER"
; ---------------------------------------------------------------------------
Map_obj39:
	include "_maps\obj39.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - "SONIC HAS PASSED" title card
; ---------------------------------------------------------------------------
Map_obj3A:	dc.w byte_CBEA-Map_obj3A
		dc.w byte_CC13-Map_obj3A
		dc.w byte_CC32-Map_obj3A
		dc.w byte_CC51-Map_obj3A
		dc.w byte_CC75-Map_obj3A
		dc.w byte_CB47-Map_obj3A
		dc.w byte_CB26-Map_obj3A
		dc.w byte_CB31-Map_obj3A
		dc.w byte_CB3C-Map_obj3A
byte_CBEA:	dc.b 8			; SONIC HAS
		dc.b $F8, 5, 0,	$3E, $B8
		dc.b $F8, 5, 0,	$32, $C8
		dc.b $F8, 5, 0,	$2E, $D8
		dc.b $F8, 1, 0,	$20, $E8
		dc.b $F8, 5, 0,	8, $F0
		dc.b $F8, 5, 0,	$1C, $10
		dc.b $F8, 5, 0,	0, $20
		dc.b $F8, 5, 0,	$3E, $30
byte_CC13:	dc.b 6			; PASSED
		dc.b $F8, 5, 0,	$36, $D0
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3E, $F0
		dc.b $F8, 5, 0,	$3E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b $F8, 5, 0,	$C, $20
byte_CC32:	dc.b 6			; SCORE
		dc.b $F8, $D, 1, $4A, $B0
		dc.b $F8, 1, 1,	$62, $D0
		dc.b $F8, 9, 1,	$64, $18
		dc.b $F8, $D, 1, $6A, $30
		dc.b $F7, 4, 0,	$6E, $CD
		dc.b $FF, 4, $18, $6E, $CD
byte_CC51:	dc.b 7			; TIME BONUS
		dc.b $F8, $D, 1, $5A, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F0,	$28
		dc.b $F8, 1, 1,	$70, $48
byte_CC75:	dc.b 7			; RING BONUS
		dc.b $F8, $D, 1, $52, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F8,	$28
		dc.b $F8, 1, 1,	$70, $48
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 36 - spikes
; ---------------------------------------------------------------------------

Obj36:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj36_Index(pc,d0.w),d1
		jmp	Obj36_Index(pc,d1.w)
; ===========================================================================
Obj36_Index:	dc.w Obj36_Main-Obj36_Index
		dc.w Obj36_Solid-Obj36_Index

Obj36_Var:	dc.b 0,	$14		; frame	number,	object width
		dc.b 1,	$10
		dc.b 2,	4
		dc.b 3,	$1C
		dc.b 4,	$40
		dc.b 5,	$10
; ===========================================================================

Obj36_Main:				; XREF: Obj36_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj36,4(a0)
		move.w	#$51B,2(a0)
		ori.b	#4,1(a0)
		move.w	#$200,Obj_Priority(a0)
		move.b	$28(a0),d0
		andi.b	#$F,$28(a0)
		andi.w	#$F0,d0
		lea	(Obj36_Var).l,a1
		lsr.w	#3,d0
		adda.w	d0,a1
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,Obj_SprWidth(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)

Obj36_Solid:				; XREF: Obj36_Index
		bsr.w	Obj36_Type0x	; make the object move
		move.w	#4,d2
		cmpi.b	#5,$1A(a0)	; is object type $5x ?
		beq.s	Obj36_SideWays	; if yes, branch
		cmpi.b	#1,$1A(a0)	; is object type $1x ?
		bne.s	Obj36_Upright	; if not, branch
		move.w	#$14,d2

; Spikes types $1x and $5x face	sideways

Obj36_SideWays:				; XREF: Obj36_Solid
		move.w	#$1B,d1
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	Obj36_Display
		cmpi.w	#1,d4
		beq.s	Obj36_Hurt
		bra.s	Obj36_Display
; ===========================================================================

; Spikes types $0x, $2x, $3x and $4x face up or	down

Obj36_Upright:				; XREF: Obj36_Solid
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	Obj36_Hurt
		tst.w	d4
		bpl.s	Obj36_Display

Obj36_Hurt:				; XREF: Obj36_SideWays; Obj36_Upright
		tst.b	($FFFFFE2D).w	; is Sonic invincible?
		bne.s	Obj36_Display	; if yes, branch
		tst.w	($FFFFD030).w	; is Sonic invulnerable?
		bne.s	Obj36_Display	; if yes, branch
		move.l	a0,-(sp)
		movea.l	a0,a2
		lea	($FFFFD000).w,a0
		cmpi.b	#4,$24(a0)
		bcc.s	loc_CF20
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		jsr	HurtSonic

loc_CF20:
		movea.l	(sp)+,a0

Obj36_Display:
		bsr.w	DisplaySprite
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj36_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject	; and delete object

Obj36_NoDel:
		rts	
; ===========================================================================

Obj36_Type0x:				; XREF: Obj36_Solid
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		move.w	Obj36_TypeIndex(pc,d0.w),d1
		jmp	Obj36_TypeIndex(pc,d1.w)
; ===========================================================================
Obj36_TypeIndex:dc.w Obj36_Type00-Obj36_TypeIndex
		dc.w Obj36_Type01-Obj36_TypeIndex
		dc.w Obj36_Type02-Obj36_TypeIndex
; ===========================================================================

Obj36_Type00:				; XREF: Obj36_TypeIndex
		rts			; don't move the object
; ===========================================================================

Obj36_Type01:				; XREF: Obj36_TypeIndex
		bsr.w	Obj36_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)	; move the object vertically
		rts	
; ===========================================================================

Obj36_Type02:				; XREF: Obj36_TypeIndex
		bsr.w	Obj36_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; move the object horizontally
		rts	
; ===========================================================================

Obj36_Wait:
		tst.w	$38(a0)		; is time delay	= zero?
		beq.s	loc_CFA4	; if yes, branch
		subq.w	#1,$38(a0)	; subtract 1 from time delay
		bne.s	locret_CFE6
		tst.b	1(a0)
		bpl.s	locret_CFE6
		move.w	#$B6,d0
		jsr	(PlaySound_Special).l ;	play "spikes moving" sound
		bra.s	locret_CFE6
; ===========================================================================

loc_CFA4:
		tst.w	$36(a0)
		beq.s	loc_CFC6
		subi.w	#$800,$34(a0)
		bcc.s	locret_CFE6
		move.w	#0,$34(a0)
		move.w	#0,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second
		bra.s	locret_CFE6
; ===========================================================================

loc_CFC6:
		addi.w	#$800,$34(a0)
		cmpi.w	#$2000,$34(a0)
		bcs.s	locret_CFE6
		move.w	#$2000,$34(a0)
		move.w	#1,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second

locret_CFE6:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - spikes
; ---------------------------------------------------------------------------
Map_obj36:
	include "_maps\obj36.asm"

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3C - smashable	wall (GHZ, SLZ)
; ---------------------------------------------------------------------------

Obj3C:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3C_Index(pc,d0.w),d1
		jsr	Obj3C_Index(pc,d1.w)
		bra.w	MarkObjGone
; ===========================================================================
Obj3C_Index:	dc.w Obj3C_Main-Obj3C_Index
		dc.w Obj3C_Solid-Obj3C_Index
		dc.w Obj3C_FragMove-Obj3C_Index
; ===========================================================================

Obj3C_Main:				; XREF: Obj3C_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj3C,4(a0)
		move.w	#$450F,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$200,Obj_Priority(a0)
		move.b	$28(a0),$1A(a0)

Obj3C_Solid:				; XREF: Obj3C_Index
		move.w	($FFFFD010).w,$30(a0) ;	load Sonic's horizontal speed
		move.w	#$1B,d1
		move.w	#$20,d2
		move.w	#$20,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#5,$22(a0)
		bne.s	Obj3C_ChkRoll

locret_D180:
		rts	
; ===========================================================================

Obj3C_ChkRoll:				; XREF: Obj3C_Solid
		cmpi.b	#2,$1C(a1)	; is Sonic rolling?
		bne.s	locret_D180	; if not, branch
		move.w	$30(a0),d0
		bpl.s	Obj3C_ChkSpeed
		neg.w	d0

Obj3C_ChkSpeed:
		cmpi.w	#$480,d0	; is Sonic's speed $480 or higher?
		bcs.s	locret_D180	; if not, branch
		move.w	$30(a0),$10(a1)
		addq.w	#4,8(a1)
		lea	(Obj3C_FragSpd1).l,a4 ;	use fragments that move	right
		move.w	8(a0),d0
		cmp.w	8(a1),d0	; is Sonic to the right	of the block?
		bcs.s	Obj3C_Smash	; if yes, branch
		subq.w	#8,8(a1)
		lea	(Obj3C_FragSpd2).l,a4 ;	use fragments that move	left

Obj3C_Smash:
		move.w	$10(a1),Obj_Inertia(a1)
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)
		moveq	#7,d1		; load 8 fragments
		move.w	#$70,d2
		bsr.s	SmashObject

Obj3C_FragMove:				; XREF: Obj3C_Index
		bsr.w	SpeedToPos
		addi.w	#$70,$12(a0)	; make fragment	fall faster
		bsr.w	DisplaySprite
		tst.b	1(a0)
		bpl.w	DeleteObject
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	smash a	block (GHZ walls and MZ	blocks)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SmashObject:				; XREF: Obj3C_Smash
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.s	Smash_LoadFrag
; ===========================================================================

Smash_Loop:
		bsr.w	SingleObjLoad
		bne.s	Smash_PlaySnd
		addq.w	#5,a3

Smash_LoadFrag:				; XREF: SmashObject
		move.b	#4,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.w	Obj_Priority(a0),Obj_Priority(a1)
		move.b	Obj_SprWidth(a0),Obj_SprWidth(a1)
		move.w	(a4)+,$10(a1)
		move.w	(a4)+,$12(a1)
		cmpa.l	a0,a1
		bcc.s	loc_D268
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos
		add.w	d2,$12(a0)
		movea.l	(sp)+,a0
		bsr.w	DisplaySprite2

loc_D268:
		dbf	d1,Smash_Loop

Smash_PlaySnd:
		move.w	#$CB,d0
		jmp	(PlaySound_Special).l ;	play smashing sound
; End of function SmashObject

; ===========================================================================
; Smashed block	fragment speeds
;
Obj3C_FragSpd1:	dc.w $400, $FB00	; x-move speed,	y-move speed
		dc.w $600, $FF00
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, $FA00
		dc.w $800, $FE00
		dc.w $800, $200
		dc.w $600, $600

Obj3C_FragSpd2:	dc.w $FA00, $FA00
		dc.w $F800, $FE00
		dc.w $F800, $200
		dc.w $FA00, $600
		dc.w $FC00, $FB00
		dc.w $FA00, $FF00
		dc.w $FA00, $100
		dc.w $FC00, $500
; ---------------------------------------------------------------------------
; Sprite mappings - smashable walls (GHZ, SLZ)
; ---------------------------------------------------------------------------
Map_obj3C:
	include "_maps\obj3C.asm"

; ---------------------------------------------------------------------------
; Object code loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjectsLoad:				; XREF: TitleScreen; et al
		lea	($FFFFD000).w,a0	; set address for object RAM
		moveq	#$7F,d7
		moveq	#0,d0
		cmpi.b	#6,($FFFFD000+Obj_Routine).w
		bcc.s	loc_D362

loc_D348:
		move.b	(a0),d0	; load object number from RAM
		beq.s	loc_D358
		add.w	d0,d0
		add.w	d0,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr	(a1)	; run the object's code
		moveq	#0,d0

loc_D358:
		lea	$40(a0),a0	; next object
		dbf	d7,loc_D348
		rts
; ===========================================================================

loc_D362:
		cmpi.b	#$A,($FFFFD000+Obj_Routine).w	; Has Sonic drowned?
		beq.s	loc_D348	; If so, run objects a little longer
		moveq	#$1F,d7
		bsr.s	loc_D348
		moveq	#$5F,d7

loc_D368:
		moveq	#0,d0	; Clear d0 quickly
		move.b	(a0),d0	; get the object's ID
		beq.s	loc_D37C	; if it's obj00, skip it
		tst.b	Obj_Render(a0)	; should we render it?
		bpl.s	loc_D37C	; if not, skip it
		move.w	Obj_Priority(a0),d0	; move object's priority to d0
		btst	#6,Obj_Render(a0)	; is the compound sprites flag set?
		beq.s	loc_D378	; if not, branch
		move.w	#$200,d0	; move $200 to d0

loc_D378:
		bsr.w	DisplaySprite3

loc_D37C:
		lea $40(a0),a0
		dbf d7,loc_D368
		rts
; End of function ObjectsLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Object pointers
; ---------------------------------------------------------------------------
Obj_Index:
	include "Objects/Object Pointers.asm"

; ---------------------------------------------------------------------------
; Subroutine to	make an	object fall downwards, increasingly fast
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjectFall:
		move.w	$10(a0),d0
		ext.l	d0
		lsl.l	#8,d0
		add.l	d0,8(a0)
		move.w	$12(a0),d0
		addi.w	#$38,$12(a0)	; increase vertical speed
        cmp.w   #$FC8,$12(a0)   ; check if Sonic's Y speed is lower than this value
        ble.s   @DontCapSpeed      ; if yes, branch
        move.w  #$FC8,$12(a0)    ; alter Sonic's Y speed
@DontCapSpeed:
		ext.l	d0
		lsl.l	#8,d0
		add.l	d0,$C(a0)
		rts	

; End of function ObjectFall

; ---------------------------------------------------------------------------
; Subroutine translating object	speed to update	object position
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SpeedToPos:
		move.w	$10(a0),d0	; load horizontal speed
		ext.l	d0
		lsl.l	#8,d0		; multiply speed by $100
		add.l	d0,8(a0)	; add to x-axis	position
		move.w	$12(a0),d0	; load vertical	speed
		ext.l	d0
		lsl.l	#8,d0		; multiply by $100
		add.l	d0,$C(a0)	; add to y-axis	position
		rts	

; End of function SpeedToPos

; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a0 is the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B    R O U T    I N E |||||||||||||||||||||||||||||||||||||||


DisplaySprite:
        lea	($FFFFAC00).w,a1
        adda.w	Obj_Priority(a0),a1	; get sprite priority
        cmpi.w	#$7E,(a1)	; is this part of the queue full?
        bcc.s	@QueueIsFull	; if yes, branch
        addq.w	#2,(a1)	; increment sprite count
        adda.w	(a1),a1	; jump to empty position
        move.w	a0,(a1)	; insert RAM address for object

@QueueIsFull:
        rts    

; End of function DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to display a 2nd sprite/object, when a1 is the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B R O U T I N E |||||||||||||||||||||||||||||||||||||||

DisplaySprite2:
        lea	($FFFFAC00).w,a2
        adda.w	Obj_Priority(a1),a2
        cmpi.w	#$7E,(a2)
        bcc.s	@QueueIsFull
        addq.w	#2,(a2)
        adda.w	(a2),a2
        move.w	a1,(a2)

@QueueIsFull:
        rts    

; End of function DisplaySprite2

; ---------------------------------------------------------------------------
; Subroutine to display a sprite/object, when a0 is the object RAM
; and d0 is already (priority/2)&$380
; ---------------------------------------------------------------------------

DisplaySprite3:
    	lea	($FFFFAC00).w,a1
    	adda.w	d0,a1
    	cmpi.w	#$7E,(a1)
    	bhs.s	@QueueIsFull
    	addq.w	#2,(a1)
    	adda.w	(a1),a1
    	move.w	a0,(a1)

@QueueIsFull:
    	rts

; ---------------------------------------------------------------------------
; Subroutine to	delete an object
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DeleteObject:
		movea.l	a0,a1

DeleteObject2:
		moveq	#0,d1
		moveq	#$F,d0

loc_D646:
		move.l	d1,(a1)+	; clear	the object RAM
		dbf	d0,loc_D646	; repeat $F times (length of object RAM)
		rts	
; End of function DeleteObject

; ===========================================================================
BldSpr_ScrPos:	dc.l 0			; blank
		dc.l $FFF700		; main screen x-position
		dc.l $FFF708		; background x-position	1
		dc.l $FFF718		; background x-position	2
; ---------------------------------------------------------------------------
; Subroutine to	convert	mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BuildSprites:                ; XREF: TitleScreen; et al
        lea    ($FFFFF800).w,a2 ; set address for sprite table
        moveq    #0,d5
        moveq    #0,d4
        tst.b    ($FFFFFFD0).w ; this was level_started_flag
        beq.s    BuildSprites_2
        jsr    loc_40804
BuildSprites_2:
        lea    ($FFFFAC00).w,a4
        moveq    #7,d7

loc_D66A:
		cmpi.w	#$07-$02,d7
		bne.s	BuildSpritesCont
		tst.b	($FFFFFFD0).w
		beq.s	BuildSpritesCont
		movem.l	d7/a4,-(sp)
		bsr.w	BuildRings
		movem.l	(sp)+,d7/a4

BuildSpritesCont:
		tst.w	(a4)
		beq.w	loc_D72E
		moveq	#2,d6

loc_D672:
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D726
		bclr	#7,1(a0)
		move.b	1(a0),d0
		move.b	d0,d4
    	btst	#6,d0    ; is the multi-draw flag set?
    	bne.w	BuildSprites_MultiDraw    ; if it is, branch
		andi.w	#$C,d0
		beq.s	loc_D6DE
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
		moveq	#0,d0
		move.b	Obj_SprWidth(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D726
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D726
		addi.w	#$80,d3
		btst	#4,d4
		beq.s	loc_D6E8
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	loc_D726
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1
		bge.s	loc_D726
		addi.w	#$80,d2
		bra.s	loc_D700
; ===========================================================================

loc_D6DE:
		move.w	$A(a0),d2
		move.w	8(a0),d3
		bra.s	loc_D700
; ===========================================================================

loc_D6E8:
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.s	loc_D726
		cmpi.w	#$180,d2
		bcc.s	loc_D726

loc_D700:
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.s	loc_D71C
		move.b	$1A(a0),d1
		add.w	d1,d1					; MJ: changed from byte to word (we want more than 7F sprites)
		adda.w	(a1,d1.w),a1
		moveq	#$00,d1					; MJ: clear d1 (because of our byte to word change)
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.s	loc_D720

loc_D71C:
		bsr.w	sub_D750

loc_D720:
		bset	#7,1(a0)

loc_D726:
		addq.w	#2,d6
		subq.w	#2,(a4)
		bne.w	loc_D672

loc_D72E:
		lea	$80(a4),a4
		dbf	d7,loc_D66A
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5
		beq.s	loc_D748
		move.l	#0,(a2)
		rts	
; ===========================================================================

loc_D748:
		move.b	#0,-5(a2)
		rts	
; End of function BuildSprites


BuildSprites_MultiDraw:
		move.l	a4,-(sp)
		lea	($FFFFF700).w,a4
    	movea.w	2(a0),a3
    	movea.l	4(a0),a5
    	moveq	#0,d0
    	; check if object is within X bounds
    	move.b	Obj_MainFrame(a0),d0	; load pixel width
    	move.w	8(a0),d3
    	sub.w	(a4),d3
    	move.w	d3,d1
    	add.w	d0,d1
    	bmi.w	BuildSprites_MultiDraw_NextObj
    	move.w	d3,d1
    	sub.w	d0,d1
    	cmpi.w	#320,d1
    	bge.w	BuildSprites_MultiDraw_NextObj
    	addi.w	#128,d3
    	; check if object is within Y bounds
    	btst	#4,d4
    	beq.s	@IgnoreHeight
    	moveq	#0,d0
    	move.b	Obj_MainHeight(a0),d0    ; load pixel height
    	move.w	$C(a0),d2
    	sub.w	4(a4),d2
    	move.w	d2,d1
    	add.w	d0,d1
    	bmi.w	BuildSprites_MultiDraw_NextObj
    	move.w	d2,d1
    	sub.w	d0,d1
    	cmpi.w	#224,d1
    	bge.w	BuildSprites_MultiDraw_NextObj
    	addi.w	#128,d2
    	bra.s	@Skip

@IgnoreHeight:
	    move.w	$C(a0),d2
	    sub.w	4(a4),d2
	    addi.w	#128,d2
	    cmpi.w	#-32+128,d2
	    blo.s	BuildSprites_MultiDraw_NextObj
	    cmpi.w	#32+128+224,d2
	    bhs.s	BuildSprites_MultiDraw_NextObj

@Skip:
    	moveq	#0,d1
    	move.b	Obj_MainFrame(a0),d1	; get current frame
    	beq.s	@DontDraw
    	add.b	d1,d1
    	movea.l	a5,a1
    	adda.w	(a1,d1.w),a1
    	move.b	(a1)+,d1
    	subq.b	#1,d1
    	bmi.s	@DontDraw
    	move.w	d4,-(sp)
    	bsr.w	ChkDrawSprite	; draw the sprite
    	move.w	(sp)+,d4

@DontDraw:
    	ori.b	#$80,1(a0)	; set onscreen flag
    	lea	Obj_Sub1XPos(a0),a6
    	moveq	#0,d0
    	move.b	Obj_ChildCount(a0),d0	; get child sprite count
    	subq.w	#1,d0	; if there are 0, go to next object
    	bcs.s	BuildSprites_MultiDraw_NextObj

@DrawSprites:
		swap	d0
    	move.w	(a6)+,d3	; get X pos
    	sub.w	(a4),d3
    	addi.w	#128,d3
    	move.w	(a6)+,d2	; get Y pos
    	sub.w	4(a4),d2
    	addi.w	#128,d2
    	addq.w	#1,a6
    	moveq	#0,d1
    	move.b	(a6)+,d1	; get mapping frame
    	add.b	d1,d1
    	movea.l	a5,a1
    	adda.w	(a1,d1.w),a1
    	move.b	(a1)+,d1
    	subq.b	#1,d1
    	bmi.s	@SkipSprite
    	move.w	d4,-(sp)
    	bsr.w	ChkDrawSprite
    	move.w	(sp)+,d4

@SkipSprite:
    	swap	d0
    	dbf	d0,@DrawSprites	; repeat for number of child sprites

BuildSprites_MultiDraw_NextObj:
    	movea.l	(sp)+,a4
    	bra.w	loc_D726

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D750:				; XREF: BuildSprites
		movea.w	2(a0),a3

ChkDrawSprite:
		btst	#0,d4
		bne.s	loc_D796
		btst	#1,d4
		bne.w	loc_D7E4
; End of function sub_D750


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D762:				; XREF: sub_D762
		cmpi.b	#$50,d5
		beq.s	locret_D794
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D78E
		addq.w	#1,d0

loc_D78E:
		move.w	d0,(a2)+
		dbf	d1,sub_D762

locret_D794:
		rts	
; End of function sub_D762

; ===========================================================================

loc_D796:
		btst	#1,d4
		bne.w	loc_D82A

loc_D79E:
		cmpi.b	#$50,d5
		beq.s	locret_D7E2
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D7DC
		addq.w	#1,d0

loc_D7DC:
		move.w	d0,(a2)+
		dbf	d1,loc_D79E

locret_D7E2:
		rts	
; ===========================================================================

loc_D7E4:				; XREF: sub_D750
		cmpi.b	#$50,d5
		beq.s	locret_D828
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D822
		addq.w	#1,d0

loc_D822:
		move.w	d0,(a2)+
		dbf	d1,loc_D7E4

locret_D828:
		rts	
; ===========================================================================

loc_D82A:
		cmpi.b	#$50,d5
		beq.s	locret_D87C
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D876
		addq.w	#1,d0

loc_D876:
		move.w	d0,(a2)+
		dbf	d1,loc_D82A

locret_D87C:
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	check if an object is on the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen:
		move.w	8(a0),d0	; get object x-position
		sub.w	($FFFFF700).w,d0 ; subtract screen x-position
		bmi.s	NotOnScreen
		cmpi.w	#320,d0		; is object on the screen?
		bge.s	NotOnScreen	; if not, branch

		move.w	$C(a0),d1	; get object y-position
		sub.w	($FFFFF704).w,d1 ; subtract screen y-position
		bmi.s	NotOnScreen
		cmpi.w	#224,d1		; is object on the screen?
		bge.s	NotOnScreen	; if not, branch

		moveq	#0,d0		; set flag to 0
		rts	
; ===========================================================================

NotOnScreen:				; XREF: ChkObjOnScreen
		moveq	#1,d0		; set flag to 1
		rts	
; End of function ChkObjOnScreen


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen2:
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		move.w	8(a0),d0
		sub.w	($FFFFF700).w,d0
		add.w	d1,d0
		bmi.s	NotOnScreen2
		add.w	d1,d1
		sub.w	d1,d0
		cmpi.w	#320,d0
		bge.s	NotOnScreen2

		move.w	$C(a0),d1
		sub.w	($FFFFF704).w,d1
		bmi.s	NotOnScreen2
		cmpi.w	#224,d1
		bge.s	NotOnScreen2

		moveq	#0,d0
		rts	
; ===========================================================================

NotOnScreen2:				; XREF: ChkObjOnScreen2
		moveq	#1,d0
		rts	
; End of function ChkObjOnScreen2

; ---------------------------------------------------------------------------
; Subroutine to	load a level's objects
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


; ---------------------------------------------------------------------------
; Objects Manager
; Subroutine to load objects whenever they are close to the screen. Unlike in
; normal s2, in this version every object gets an entry in the respawn table.
; This is necessary to get the additional y-range checks to work.
;
; input variables:
;  -none-
;
; writes:
;  d0, d1, d2
;  d3 = upper boundary to load object
;  d4 = lower boundary to load object
;  d5 = #$FFF, used to filter out object's y position
;  d6 = camera position
;
;  a0 = address in object placement list
;  a3 = address in object respawn table
;  a6 = object loading routine
; ---------------------------------------------------------------------------
 
; loc_17AA4
ObjPosLoad:
	moveq	#0,d0
	move.b	($FFFFF76C).w,d0
	jmp	ObjPosLoad_States(pc,d0.w)
 
; ============== JUMP TABLE	=============================================
ObjPosLoad_States:
	bra.w	ObjPosLoad_Init		; 0
	bra.w	ObjPosLoad_Main		; 2
; ============== END JUMP TABLE	=============================================
 
ObjPosLoad_Init:
	addq.b	#4,($FFFFF76C).w
 
	lea     (Object_Respawn_Table).w,a0
	moveq   #0,d0
	move.w  #$BF,d1 ; set loop counter
OPLBack1:
	move.l  d0,(a0)+
	dbf     d1,OPLBack1
 
	move.w	($FFFFFE10).w,d0
;
;	ror.b	#1,d0			; this is from s3k
;	lsr.w	#5,d0
;	lea	(Off_Objects).l,a0
;	movea.l	(a0,d0.w),a0
;
	lsl.b	#6,d0
	lsr.w	#4,d0
	lea	(ObjPos_Index).l,a0	; load the first pointer in the object layout list pointer index,
	adda.w	(a0,d0.w),a0		; load the pointer to the current object layout
 
	; initialize each object load address with the first object in the layout
	move.l	a0,($FFFFF770).w
	move.l	a0,($FFFFF774).w
	lea	(Object_Respawn_Table).w,a3
 
	move.w	($FFFFF700).w,d6
	subi.w	#$80,d6	; look one chunk to the left
	bcc.s	OPL1	; if the result was negative,
	moveq	#0,d6	; cap at zero
	OPL1:	
	andi.w	#$FF80,d6	; limit to increments of $80 (width of a chunk)
 
	movea.l	($FFFFF770).w,a0	; get first object in layout
 
OPLBack2:	; at the beginning of a level this gives respawn table entries to any object that is one chunk
	; behind the left edge of the screen that needs to remember its state (Monitors, Badniks, etc.)
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	OPL2		; if yes, branch
	addq.w	#6,a0	; next object
	addq.w	#1,a3	; respawn index of next object going right
	bra.s	OPLBack2
; ---------------------------------------------------------------------------
 
OPL2:	
	move.l	a0,($FFFFF770).w	; remember rightmost object that has been processed, so far (we still need to look forward)
	move.w	a3,($FFFFF778).w	; and its respawn table index
 
	lea	(Object_Respawn_Table).w,a3	; reset a3
	movea.l	($FFFFF774).w,a0	; reset a0
	subi.w	#$80,d6		; look even farther left (any object behind this is out of range)
	bcs.s	OPL3		; branch, if camera position would be behind level's left boundary
 
 OPLBack3:	; count how many objects are behind the screen that are not in range and need to remember their state
	cmp.w	(a0),d6		; is object's x position >= d6?
	bls.s	OPL3		; if yes, branch
	addq.w	#6,a0
	addq.w	#1,a3	; respawn index of next object going left
	bra.s	OPLBack3	; continue with next object
; ---------------------------------------------------------------------------
 
OPL3:	
	move.l	a0,($FFFFF774).w	; remember current object from the left
	move.w	a3,($FFFFF77C).w	; and its respawn table index
 
	move.w	#-1,(Camera_X_Pos_last).w	; make sure ObjPosLoad_GoingForward is run
 
	move.w	($FFFFF704).w,d0
	andi.w	#$FF80,d0
	move.w	d0,(Camera_Y_pos_last).w	; make sure the Y check isn't run unnecessarily during initialization
; ---------------------------------------------------------------------------
 
ObjPosLoad_Main:
	; get coarse camera position
;	move.w	($FFFFF704).w,d1
;	subi.w	#$80,d1
;	andi.w	#$FF80,d1
;	move.w	d1,(Camera_Y_pos_coarse).w
 
;	move.w	($FFFFF700).w,d1
;	subi.w	#$80,d1
;	andi.w	#$FF80,d1
;	move.w	d1,(Camera_X_pos_coarse).w
 
	tst.w	($FFFFF726).w	; does this level y-wrap?
	bpl.s	ObjMan_Main_NoYWrap	; if not, branch
	lea	(ChkLoadObj_YWrap).l,a6	; set object loading routine
	move.w	($FFFFF704).w,d3
	andi.w	#$FF80,d3	; get coarse value
	move.w	d3,d4
	addi.w	#$200,d4	; set lower boundary
	subi.w	#$80,d3		; set upper boundary
	bpl.s	OPL4		; branch, if upper boundary > 0
	andi.w	#$7FF,d3	; wrap value
	bra.s	ObjMan_Main_Cont
; ---------------------------------------------------------------------------
 
OPL4:	
	move.w	#$7FF,d0
	addq.w	#1,d0
	cmp.w	d0,d4
	bls.s	OPL5		; branch, if lower boundary < $7FF
	andi.w	#$7FF,d4	; wrap value
	bra.s	ObjMan_Main_Cont
; ---------------------------------------------------------------------------
 
ObjMan_Main_NoYWrap:
	move.w	($FFFFF704).w,d3
	andi.w	#$FF80,d3	; get coarse value
	move.w	d3,d4
	addi.w	#$200,d4	; set lower boundary
	subi.w	#$80,d3		; set upper boundary
	bpl.s	OPL5
	moveq	#0,d3	; no negative values allowed
 
OPL5:	
	lea	(ChkLoadObj).l,a6	; set object loading routine
 
ObjMan_Main_Cont:
	move.w	#$FFF,d5	; this will be used later when we load objects
	move.w	($FFFFF700).w,d6
	andi.w	#$FF80,d6
	cmp.w	(Camera_X_Pos_last).w,d6	; is the X range the same as last time?
	beq.w	ObjPosLoad_SameXRange	; if yes, branch
	bge.s	ObjPosLoad_GoingForward	; if new pos is greater than old pos, branch
 
	; if the player is moving back
	move.w	d6,(Camera_X_Pos_last).w	; remember current position for next time
 
	movea.l	($FFFFF774).w,a0	; get current object going left
	movea.w	($FFFFF77C).w,a3	; and its respawn table index
 
	subi.w	#$80,d6			; look one chunk to the left
	bcs.s	ObjMan_GoingBack_Part2	; branch, if camera position would be behind level's left boundary
 
	jsr	(SingleObjLoad).l		; find an empty object slot
	bne.s	ObjMan_GoingBack_Part2		; branch, if there are none
OPLBack4:	; load all objects left of the screen that are now in range
	cmp.w	-6(a0),d6		; is the previous object's X pos less than d6?
	bge.s	ObjMan_GoingBack_Part2	; if it is, branch
	subq.w	#6,a0		; get object's address
	subq.w	#1,a3		; and respawn table index
	jsr	(a6)		; load object
	bne.s	OPL6		; branch, if SST is full
	subq.w	#6,a0
	bra.s	OPLBack4	; continue with previous object
; ---------------------------------------------------------------------------
 
OPL6:	
	; undo a few things, if the object couldn't load
	addq.w	#6,a0	; go back to last object
	addq.w	#1,a3	; since we didn't load the object, undo last change
 
ObjMan_GoingBack_Part2:
	move.l	a0,($FFFFF774).w	; remember current object going left
	move.w	a3,($FFFFF77C).w	; and its respawn table index
	movea.l	($FFFFF770).w,a0	; get next object going right
	movea.w	($FFFFF778).w,a3	; and its respawn table index
	addi.w	#$300,d6	; look two chunks beyond the right edge of the screen
 
OPLBack5:	; subtract number of objects that have been moved out of range (from the right side)
	cmp.w	-6(a0),d6	; is the previous object's X pos less than d6?
	bgt.s	OPL7		; if it is, branch
	subq.w	#6,a0		; get object's address
	subq.w	#1,a3		; and respawn table index
	bra.s	OPLBack5	; continue with previous object
; ---------------------------------------------------------------------------
 
OPL7:	
	move.l	a0,($FFFFF770).w	; remember next object going right
	move.w	a3,($FFFFF778).w	; and its respawn table index
	bra.s	ObjPosLoad_SameXRange
; ---------------------------------------------------------------------------
 
ObjPosLoad_GoingForward:
	move.w	d6,(Camera_X_Pos_last).w
 
	movea.l	($FFFFF770).w,a0	; get next object from the right
	movea.w ($FFFFF778).w,a3	; and its respawn table index
	addi.w	#$280,d6	; look two chunks forward
	jsr	(SingleObjLoad).l		; find an empty object slot
	bne.s	ObjMan_GoingForward_Part2	; branch, if there are none
 
OPLBack6:	; load all objects right of the screen that are now in range
	cmp.w	(a0),d6				; is object's x position >= d6?
	bls.s	ObjMan_GoingForward_Part2	; if yes, branch
	jsr	(a6)		; load object (and get address of next object)
	addq.w	#1,a3		; respawn index of next object to the right
	beq.s	OPLBack6	; continue loading objects, if the SST isn't full
 
ObjMan_GoingForward_Part2:
	move.l	a0,($FFFFF770).w	; remember next object from the right
	move.w	a3,($FFFFF778).w	; and its respawn table index
	movea.l	($FFFFF774).w,a0	; get current object from the left
	movea.w	($FFFFF77C).w,a3	; and its respawn table index
	subi.w	#$300,d6		; look one chunk behind the left edge of the screen
	bcs.s	ObjMan_GoingForward_End	; branch, if camera position would be behind level's left boundary
 
OPLBack7:	; subtract number of objects that have been moved out of range (from the left)
	cmp.w	(a0),d6			; is object's x position >= d6?
	bls.s	ObjMan_GoingForward_End	; if yes, branch
	addq.w	#6,a0	; next object
	addq.w	#1,a3	; respawn index of next object to the left
	bra.s	OPLBack7	; continue with next object
; ---------------------------------------------------------------------------
 
ObjMan_GoingForward_End:
	move.l	a0,($FFFFF774).w	; remember current object from the left
	move.w	a3,($FFFFF77C).w	; and its respawn table index
 
ObjPosLoad_SameXRange:
	move.w	($FFFFF704).w,d6
	andi.w	#$FF80,d6
	move.w	d6,d3
	cmp.w	(Camera_Y_pos_last).w,d6	; is the y range the same as last time?
	beq.w	ObjPosLoad_SameYRange	; if yes, branch
	bge.s	ObjPosLoad_GoingDown	; if the player is moving down
 
	; if the player is moving up
	tst.w	($FFFFF72C).w	; does the level y-wrap?
	bpl.s	ObjMan_GoingUp_NoYWrap	; if not, branch
	tst.w	d6
	bne.s	ObjMan_GoingUp_YWrap
	cmpi.w	#$80,(Camera_Y_pos_last).w
	bne.s	ObjMan_GoingDown_YWrap
 
ObjMan_GoingUp_YWrap:
	subi.w	#$80,d3			; look one chunk up
	bpl.s	ObjPosLoad_YCheck	; go to y check, if camera y position >= $80
	andi.w	#$7FF,d3		; else, wrap value
	bra.s	ObjPosLoad_YCheck
 
; ---------------------------------------------------------------------------
 
ObjMan_GoingUp_NoYWrap:
	subi.w	#$80,d3				; look one chunk up
	bmi.w	ObjPosLoad_SameYRange	; don't do anything if camera y position is < $80
	bra.s	ObjPosLoad_YCheck
; ---------------------------------------------------------------------------
 
ObjPosLoad_GoingDown:
	tst.w	($FFFFF72C).w		; does the level y-wrap?
	bpl.s	ObjMan_GoingDown_NoYWrap	; if not, branch
	tst.w	(Camera_Y_pos_last).w
	bne.s	ObjMan_GoingDown_YWrap
	cmpi.w	#$80,d6
	bne.s	ObjMan_GoingUp_YWrap
 
ObjMan_GoingDown_YWrap:
	addi.w	#$180,d3		; look one chunk down
	cmpi.w	#$7FF,d3
	bcs.s	ObjPosLoad_YCheck	; go to  check, if camera y position < $7FF
	andi.w	#$7FF,d3		; else, wrap value
	bra.s	ObjPosLoad_YCheck
; ---------------------------------------------------------------------------
 
ObjMan_GoingDown_NoYWrap:
	addi.w	#$180,d3			; look one chunk down
	cmpi.w	#$7FF,d3
	bhi.s	ObjPosLoad_SameYRange	; don't do anything, if camera is too close to bottom
 
ObjPosLoad_YCheck:
	jsr	(SingleObjLoad).l		; get an empty object slot
	bne.s	ObjPosLoad_SameYRange	; branch, if there are none
	move.w	d3,d4
	addi.w	#$80,d4
	move.w	#$FFF,d5	; this will be used later when we load objects
	movea.l	($FFFFF774).w,a0	; get next object going left
	movea.w	($FFFFF77C).w,a3	; and its respawn table index
	move.l	($FFFFF770).w,d7	; get next object going right
	sub.l	a0,d7	; d7 = number of objects between the left and right boundaries * 6
	beq.s	ObjPosLoad_SameYRange	; branch if there are no objects inbetween
	addq.w	#2,a0	; align to object's y position
 
OPLBack8:	; check, if current object needs to be loaded
	tst.b	(a3)	; is object already loaded?
	bmi.s	OPL8	; if yes, branch
	move.w	(a0),d1
	and.w	d5,d1	; get object's y position
	cmp.w	d3,d1
	bcs.s	OPL8	; branch, if object is out of range from the top
	cmp.w	d4,d1
	bhi.s	OPL8	; branch, if object is out of range from the bottom
	bset	#7,(a3)	; mark object as loaded
	; load object
	move.w	-2(a0),8(a1)
	move.w	(a0),d1
	move.w	d1,d2
	and.w	d5,d1	; get object's y position
	move.w	d1,$C(a1)
	rol.w	#3,d2
	andi.w	#3,d2	; get object's render flags and status
	move.b	d2,1(a1)
	move.b	d2,$22(a1)
    moveq	#0,d0
	move.b	2(a0),d0
	andi.b	#$7F,d0
	move.b	d0,0(a1)
	move.b	3(a0),$28(a1)
	move.w	a3,Obj_RespawnIdx(a1)
	jsr	(SingleObjLoad).l	; find new object slot
	bne.s	ObjPosLoad_SameYRange	; brach, if there are none left
OPL8:
	addq.w	#6,a0	; address of next object
	addq.w	#1,a3	; and its respawn index
	subq.w	#6,d7	; subtract from size of remaining objects
	bne.s	OPLBack8	; branch, if there are more
 
ObjPosLoad_SameYRange:
	move.w	d6,(Camera_Y_pos_last).w
	rts		
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutines to check if an object needs to be loaded,
; with and without y-wrapping enabled.
;
; input variables:
;  d3 = upper boundary to load object
;  d4 = lower boundary to load object
;  d5 = #$FFF, used to filter out object's y position
;
;  a0 = address in object placement list
;  a1 = object
;  a3 = address in object respawn table
;
; writes:
;  d1, d2, d7
; ---------------------------------------------------------------------------
ChkLoadObj_YWrap:
	tst.b	(a3)	; is object already loaded?
	bpl.s	OPL9	; if not, branch
	addq.w	#6,a0	; address of next object
	moveq	#0,d1	; let the objects manager know that it can keep going
	rts	
; ---------------------------------------------------------------------------
 
OPL9:	
	move.w	(a0)+,d7	; x_pos
	move.w	(a0)+,d1	; there are three things stored in this word
	move.w	d1,d2	; does this object skip y-Checks?
	bmi.s	OPL10	; if yes, branch
	and.w	d5,d1	; y_pos
	cmp.w	d3,d1
	bcc.s	LoadObj_YWrap
	cmp.w	d4,d1
	bls.s	LoadObj_YWrap
	addq.w	#2,a0	; address of next object
	moveq	#0,d1	; let the objects manager know that it can keep going
	rts	
; ---------------------------------------------------------------------------
 
OPL10:	
	and.w	d5,d1	; y_pos
 
LoadObj_YWrap:
	bset	#7,(a3)	; mark object as loaded
	move.w	d7,8(a1)
	move.w	d1,$C(a1)
	rol.w	#3,d2	; adjust bits
	andi.w	#3,d2	; get render flags and status
	move.b	d2,1(a1)
	move.b	d2,$22(a1)
    moveq	#0,d0
	move.b	(a0)+,d0
	andi.b	#$7F,d0
	move.b	d0,0(a1)
	move.b	(a0)+,$28(a1)
	move.w	a3,Obj_RespawnIdx(a1)
	bra.s	SingleObjLoad	; find new object slot
 
;loc_17F36
ChkLoadObj:
	tst.b	(a3)	; is object already loaded?
	bpl.s	OPL11	; if not, branch
	addq.w	#6,a0	; address of next object
	moveq	#0,d1	; let the objects manager know that it can keep going
	rts
; ---------------------------------------------------------------------------
 
OPL11:	
	move.w	(a0)+,d7	; x_pos
	move.w	(a0)+,d1	; there are three things stored in this word
	move.w	d1,d2	; does this object skip y-Checks?	;*6
	bmi.s	OPL13	; if yes, branch
	and.w	d5,d1	; y_pos
	cmp.w	d3,d1
	bcs.s	OPL12	; branch, if object is out of range from the top
	cmp.w	d4,d1
	bls.s	LoadObj	; branch, if object is in range from the bottom
OPL12:
	addq.w	#2,a0	; address of next object
	moveq	#0,d1
	rts		
; ---------------------------------------------------------------------------
 
OPL13:	
	and.w	d5,d1	; y_pos
 
LoadObj:
	bset	#7,(a3)	; mark object as loaded
	move.w	d7,8(a1)
	move.w	d1,$C(a1)
	rol.w	#3,d2	; adjust bits
	andi.w	#3,d2	; get render flags and status
	move.b	d2,1(a1)
	move.b	d2,$22(a1)
    moveq	#0,d0
    move.b	(a0)+,d0
	andi.b	#$7F,d0
	move.b	d0,0(a1)
	move.b	(a0)+,$28(a1)
	move.w	a3,Obj_RespawnIdx(a1)
	; continue straight to SingleObjLoad
; End of function ChkLoadObj
; ===========================================================================

; ---------------------------------------------------------------------------
; Single object	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SingleObjLoad:
		lea	($FFFFD800).w,a1 ; start address for object RAM
		move.w	#$5F,d0

loc_DA94:
		tst.b	(a1)		; is object RAM	slot empty?
		beq.s	locret_DAA0	; if yes, branch
		lea	$40(a1),a1	; goto next object RAM slot
		dbf	d0,loc_DA94	; repeat $5F times

locret_DAA0:
		rts	
; End of function SingleObjLoad


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SingleObjLoad2:
		movea.l	a0,a1
		move.w	#-$1000,d0
		sub.w	a0,d0
		lsr.w	#6,d0
		subq.w	#1,d0
		bcs.s	locret_DABC

loc_DAB0:
		tst.b	(a1)
		beq.s	locret_DABC
		lea	$40(a1),a1
		dbf	d0,loc_DAB0

locret_DABC:
		rts	
; End of function SingleObjLoad2


RingsManager:
	moveq	#0,d0
	move.b	(Rings_manager_routine).w,d0
	move.w	RingsManager_States(pc,d0.w),d0
	jmp	RingsManager_States(pc,d0.w)
; ===========================================================================
; off_16F96:
RingsManager_States:
	dc.w RingsManager_Init-RingsManager_States
	dc.w RingsManager_Main-RingsManager_States
; ===========================================================================
; loc_16F9A:
RingsManager_Init:
	addq.b	#2,(Rings_manager_routine).w ; => RingsManager_Main
	bsr.w	RingsManager_Setup
	movea.l	(Ring_start_addr_ROM).w,a1
	lea	(Ring_Positions).w,a2
	move.w	($FFFFF700).w,d4
	subq.w	#8,d4
	bhi.s	loc_16FB6
	moveq	#1,d4
	bra.s	loc_16FB6
; ===========================================================================

loc_16FB2:
	addq.w	#4,a1
	addq.w	#2,a2

loc_16FB6:
	cmp.w	(a1),d4
	bhi.s	loc_16FB2
	move.l	a1,(Ring_start_addr_ROM).w
	move.w	a2,(Ring_start_addr_RAM).w
	addi.w	#$150,d4
	bra.s	loc_16FCE
; ===========================================================================

loc_16FCA:
	addq.w	#4,a1

loc_16FCE:
	cmp.w	(a1),d4
	bhi.s	loc_16FCA
	move.l	a1,(Ring_end_addr_ROM).w
	rts
; ===========================================================================
; loc_16FDE:
RingsManager_Main:
	lea	(Ring_consumption_table).w,a2
	move.w	(a2)+,d1
	subq.w	#1,d1
	bcs.s	loc_17014

loc_16FE8:
	move.w	(a2)+,d0
	beq.s	loc_16FE8
	movea.w	d0,a1
	subq.b	#1,(a1)
	bne.s	loc_17010
	move.b	#6,(a1)
	addq.b	#1,1(a1)
	cmpi.b	#8,1(a1)
	bne.s	loc_17010
	move.w	#-1,(a1)
	move.w	#0,-2(a2)
	subq.w	#1,(Ring_consumption_table).w

loc_17010:
	dbf	d1,loc_16FE8

loc_17014:
	movea.l	(Ring_start_addr_ROM).w,a1
	movea.w	(Ring_start_addr_RAM).w,a2
	move.w	($FFFFF700).w,d4
	subq.w	#8,d4
	bhi.s	loc_17028
	moveq	#1,d4
	bra.s	loc_17028
; ===========================================================================

loc_17024:
	addq.w	#4,a1
	addq.w	#2,a2

loc_17028:
	cmp.w	(a1),d4
	bhi.s	loc_17024
	bra.s	loc_17032
; ===========================================================================

loc_17030:
	subq.w	#4,a1
	subq.w	#2,a2

loc_17032:
	cmp.w	-4(a1),d4
	bls.s	loc_17030
	move.l	a1,(Ring_start_addr_ROM).w
	move.w	a2,(Ring_start_addr_RAM).w
	movea.l	(Ring_end_addr_ROM).w,a2
	addi.w	#$150,d4
	bra.s	loc_1704A
; ===========================================================================

loc_17046:
	addq.w	#4,a2

loc_1704A:
	cmp.w	(a2),d4
	bhi.s	loc_17046
	bra.s	loc_17054
; ===========================================================================

loc_17052:
	subq.w	#4,a2

loc_17054:
	cmp.w	-4(a2),d4
	bls.s	loc_17052
	move.l	a2,(Ring_end_addr_ROM).w
	rts

; ===========================================================================

Touch_Rings:
	movea.l	(Ring_start_addr_ROM).w,a1
	movea.l	(Ring_end_addr_ROM).w,a2

loc_170D0:
	cmpa.l	a1,a2
	beq.w	return_17166
	movea.w	(Ring_start_addr_RAM).w,a4
	cmpi.w	#$5A,$30(a0)
	bcc.w	return_17166
	tst.b	($FFFFFE2C).w	; does Sonic have a lightning shield?
	beq.s	Touch_Rings_NoAttraction	; if not, branch
	move.w	8(a0),d2
	move.w	$C(a0),d3
	subi.w	#$40,d2
	subi.w	#$40,d3
	move.w	#6,d1
	move.w	#$C,d6
	move.w	#$80,d4
	move.w	#$80,d5
	bra.s	loc_17112
; ===========================================================================
	
Touch_Rings_NoAttraction:
	move.w	8(a0),d2
	move.w	$C(a0),d3
	subi.w	#8,d2
	moveq	#0,d5
	move.b	$16(a0),d5
	subq.b	#3,d5
	sub.w	d5,d3
	cmpi.b	#$4D,4(a0)
	bne.s	RM1
	addi.w	#$C,d3
	moveq	#$A,d5
RM1:
	move.w	#6,d1
	move.w	#$C,d6
	move.w	#$10,d4
	add.w	d5,d5

loc_17112:
	tst.w	(a4)
	bne.w	loc_1715C
	move.w	(a1),d0
	sub.w	d1,d0
	sub.w	d2,d0
	bcc.s	loc_1712A
	add.w	d6,d0
	bcs.s	loc_17130
	bra.w	loc_1715C
; ===========================================================================

loc_1712A:
	cmp.w	d4,d0
	bhi.w	loc_1715C

loc_17130:
	move.w	2(a1),d0
	sub.w	d1,d0
	sub.w	d3,d0
	bcc.s	loc_17142
	add.w	d6,d0
	bcs.s	loc_17148
	bra.w	loc_1715C
; ===========================================================================

loc_17142:
	cmp.w	d5,d0
	bhi.w	loc_1715C

loc_17148:
	tst.b	($FFFFFE2C).w
	bne.s	AttractRing
	
loc_17148_cont:
	move.w	#$604,(a4)
	bsr.s	loc_17168
	lea	(Ring_consumption_table+2).w,a3

loc_17152:
	tst.w	(a3)+
	bne.s	loc_17152
	move.w	a4,-(a3)
	addq.w	#1,(Ring_consumption_table).w

loc_1715C:
	addq.w	#4,a1
	addq.w	#2,a4
	cmpa.l	a1,a2
	bne.w	loc_17112

return_17166:
	rts
; ===========================================================================

loc_17168:
	subq.w	#1,(Perfect_rings_left).w
	bra.w	CollectRing
; ===========================================================================

AttractRing:
	movea.l	a1,a3
	jsr	SingleObjLoad
	bne.w	AttractRing_NoFreeSlot
	move.b	#7,(a1)
	move.w	(a3),8(a1)
	move.w	2(a3),$C(a1)
	move.w	a0,$34(a1)
	move.w	#-1,(a4)
	rts	
; ===========================================================================
	
AttractRing_NoFreeSlot:
	movea.l	a3,a1
	bra.s	loc_17148_cont
; ===========================================================================

BuildRings:
	movea.l	(Ring_start_addr_ROM).w,a0
	move.l	(Ring_end_addr_ROM).w,d7
	sub.l	a0,d7
	bne.s	loc_17186
	rts
; ===========================================================================

loc_17186:
	movea.w	(Ring_start_addr_RAM).w,a4
	lea	($FFFFF700).w,a3

loc_1718A:
	tst.w	(a4)+
	bmi.w	loc_171EC
	move.w	(a0),d3
	sub.w	(a3),d3
	addi.w	#$80,d3
	move.w	2(a0),d2
	sub.w	4(a3),d2
	andi.w	#$7FF,d2
	addi.w	#8,d2
	bmi.s	loc_171EC
	cmpi.w	#$F0,d2
	bge.s	loc_171EC
	addi.w	#$78,d2
	lea	(Map_Obj25).l,a1
	moveq	#0,d1
	move.b	-1(a4),d1
	bne.s	loc_171C8
	move.b	($FFFFFEC3).w,d1

loc_171C8:
	add.w	d1,d1
	adda.w	(a1,d1.w),a1
	moveq	#$00,d1
	move.b	(a1)+,d1
	subq.b	#1,d1
	bmi.s	loc_171EC
	move.b	(a1)+,d0
	ext.w	d0
	add.w	d2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,(a2)+
	addq.b	#1,d5
	move.b	d5,(a2)+
	move.b	(a1)+,d0
	lsl.w	#8,d0
	move.b	(a1)+,d0
	addi.w	#$27B2,d0
	move.w	d0,(a2)+
	move.b	(a1)+,d0
	ext.w	d0
	add.w	d3,d0
	move.w	d0,(a2)+

loc_171EC:
	addq.w	#4,a0
	subq.w	#4,d7
	bne.w	loc_1718A
	rts
; ===========================================================================

RingsManager_Setup:
	lea	(Ring_Positions).w,a1
	moveq	#0,d0
	move.w	#Rings_Space/4-1,d1

loc_172AE:				; CODE XREF: h+33Cj
	move.l	d0,(a1)+
	dbf	d1,loc_172AE

	; d0 = 0
	lea	(Ring_consumption_table).w,a1
	move.w	#$1F,d1
RMBack1:
	move.l	d0,(a1)+
	dbf	d1,RMBack1

	moveq	#0,d5
	moveq	#0,d0
	move.w	($FFFFFE10).w,d0
	lsl.b	#6,d0
	lsr.w	#4,d0
	lea	(RingPos_Index).l,a1
	move.w	(a1,d0.w),d0
	lea	(a1,d0.w),a1
	move.l	a1,(Ring_start_addr_ROM).w
	addq.w	#4,a1
	moveq	#0,d5
	move.w	#(Max_Rings-1),d0	
	
RMBack2:
	tst.l	(a1)+
	bmi.s	RM2
	addq.w	#1,d5
	dbf	d0,RMBack2
RM2:
	move.w	d5,(Perfect_rings_left).w
	rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

Obj41:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj41_Index(pc,d0.w),d1
		jsr	Obj41_Index(pc,d1.w)
		bsr.w	DisplaySprite
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj41_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject	; and delete object

Obj41_NoDel:
		rts	
; ===========================================================================
Obj41_Index:	dc.w Obj41_Main-Obj41_Index
		dc.w Obj41_Up-Obj41_Index
		dc.w Obj41_AniUp-Obj41_Index
		dc.w Obj41_ResetUp-Obj41_Index
		dc.w Obj41_LR-Obj41_Index
		dc.w Obj41_AniLR-Obj41_Index
		dc.w Obj41_ResetLR-Obj41_Index
		dc.w Obj41_Dwn-Obj41_Index
		dc.w Obj41_AniDwn-Obj41_Index
		dc.w Obj41_ResetDwn-Obj41_Index

Obj41_Powers:	dc.w -$1000		; power	of red spring
		dc.w -$A00		; power	of yellow spring
; ===========================================================================

Obj41_Main:				; XREF: Obj41_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj41,4(a0)
		move.w	#$523,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$200,Obj_Priority(a0)
		move.b	$28(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.s	loc_DB54	; if not, branch
		move.b	#8,$24(a0)	; use "Obj41_LR" routine
		move.b	#1,$1C(a0)
		move.b	#3,$1A(a0)
		move.w	#$533,2(a0)
		move.b	#8,Obj_SprWidth(a0)

loc_DB54:
		btst	#5,d0		; does the spring face downwards?
		beq.s	loc_DB66	; if not, branch
		move.b	#$E,$24(a0)	; use "Obj41_Dwn" routine
		bset	#1,$22(a0)

loc_DB66:
		btst	#1,d0
		beq.s	loc_DB72
		bset	#5,2(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	Obj41_Powers(pc,d0.w),$30(a0)
		rts	
; ===========================================================================

Obj41_Up:				; XREF: Obj41_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		tst.b	$25(a0)		; is Sonic on top of the spring?
		bne.s	Obj41_BounceUp	; if yes, branch
		rts	
; ===========================================================================

Obj41_BounceUp:				; XREF: Obj41_Up
		addq.b	#2,$24(a0)
		addq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)	; move Sonic upwards
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#$10,$1C(a1)	; use "bouncing" animation
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	#$CC,d0
		jsr	(PlaySound_Special).l ;	play spring sound

Obj41_AniUp:				; XREF: Obj41_Index
		lea	(Ani_obj41).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Obj41_ResetUp:				; XREF: Obj41_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_Up" routine
		rts	
; ===========================================================================

Obj41_LR:				; XREF: Obj41_Index
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,$24(a0)
		bne.s	loc_DC0C
		move.b	#8,$24(a0)

loc_DC0C:
		btst	#5,$22(a0)
		bne.s	Obj41_BounceLR
		rts	
; ===========================================================================

Obj41_BounceLR:				; XREF: Obj41_LR
		addq.b	#2,$24(a0)
		move.w	$30(a0),$10(a1)	; move Sonic to	the left
		addq.w	#8,8(a1)
		btst	#0,$22(a0)	; is object flipped?
		bne.s	loc_DC36	; if yes, branch
		subi.w	#$10,8(a1)
		neg.w	$10(a1)		; move Sonic to	the right

loc_DC36:
		move.w	#$F,$3E(a1)
		move.w	$10(a1),Obj_Inertia(a1)
		bchg	#0,$22(a1)
		btst	#2,$22(a1)
		bne.s	loc_DC56
		move.b	#0,$1C(a1)	; use running animation

loc_DC56:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)
		move.w	#$CC,d0
		jsr	(PlaySound_Special).l ;	play spring sound

Obj41_AniLR:				; XREF: Obj41_Index
		clr.w	($FFFFC904).w	; clear screen delay counter
		lea	(Ani_obj41).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Obj41_ResetLR:				; XREF: Obj41_Index
		move.b	#2,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_LR" routine
		rts	
; ===========================================================================

Obj41_Dwn:				; XREF: Obj41_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,$24(a0)
		bne.s	loc_DCA4
		move.b	#$E,$24(a0)

loc_DCA4:
		tst.b	$25(a0)
		bne.s	locret_DCAE
		tst.w	d4
		bmi.s	Obj41_BounceDwn

locret_DCAE:
		rts	
; ===========================================================================

Obj41_BounceDwn:			; XREF: Obj41_Dwn
		addq.b	#2,$24(a0)
		subq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)
		neg.w	$12(a1)		; move Sonic downwards
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	#$CC,d0
		jsr	(PlaySound_Special).l ;	play spring sound

Obj41_AniDwn:				; XREF: Obj41_Index
		lea	(Ani_obj41).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Obj41_ResetDwn:				; XREF: Obj41_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_Dwn" routine
		rts	
; ===========================================================================
Ani_obj41:
	include "Objects/Springs/Animations.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - springs
; ---------------------------------------------------------------------------
Map_obj41:
	include "Objects/Springs/Mappings.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Object 47 - pinball bumper (SYZ)
; ---------------------------------------------------------------------------

Obj47:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj47_Index(pc,d0.w),d1
		jmp	Obj47_Index(pc,d1.w)
; ===========================================================================
Obj47_Index:	dc.w Obj47_Main-Obj47_Index
		dc.w Obj47_Hit-Obj47_Index
; ===========================================================================

Obj47_Main:				; XREF: Obj47_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj47,4(a0)
		move.w	#$380,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#$D7,$20(a0)

Obj47_Hit:				; XREF: Obj47_Index
		tst.b	$21(a0)		; has Sonic touched the	bumper?
		beq.w	Obj47_Display	; if not, branch
		clr.b	$21(a0)
		lea	($FFFFD000).w,a1
		move.w	8(a0),d1
		move.w	$C(a0),d2
		sub.w	8(a1),d1
		sub.w	$C(a1),d2
		jsr	(CalcAngle).l
		jsr	(CalcSine).l
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,$10(a1)	; bounce Sonic away
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,$12(a1)	; bounce Sonic away
		bset	#1,$22(a1)
		bclr	#4,$22(a1)
		bclr	#5,$22(a1)
		clr.b	$3C(a1)
		move.b	#1,$1C(a0)
		move.w	#$B4,d0
		jsr	(PlaySound_Special).l ;	play bumper sound
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj47_Score		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		cmpi.b	#$8A,(a2)	; has bumper been hit $8A times?
		bcc.s	Obj47_Display	; if yes, Sonic	gets no	points
		addq.b	#1,(a2)

Obj47_Score:
		moveq	#1,d0
		jsr	AddPoints	; add 10 to score
		bsr.w	SingleObjLoad
		bne.s	Obj47_Display
		move.b	#$29,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#4,$1A(a1)

Obj47_Display:
		lea	(Ani_obj47).l,a1
		bsr.w	AnimateSprite
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj47_ChkHit
		bra.w	DisplaySprite
; ===========================================================================

Obj47_ChkHit:				; XREF: Obj47_Display
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj47_Delete		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again

Obj47_Delete:
		bra.w	DeleteObject
; ===========================================================================
Ani_obj47:
	include "_anim\obj47.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - pinball bumper (SYZ)
; ---------------------------------------------------------------------------
Map_obj47:
	include "_maps\obj47.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0D - signpost at the end of a level
; ---------------------------------------------------------------------------

Obj0D:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0D_Index(pc,d0.w),d1
		jsr	Obj0D_Index(pc,d1.w)
		lea	(Ani_obj0D).l,a1
		bsr.w	AnimateSprite
		bsr.w	DisplaySprite
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj0D_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject	; and delete object

Obj0D_NoDel:
		rts	
; ===========================================================================
Obj0D_Index:	dc.w Obj0D_Main-Obj0D_Index
		dc.w Obj0D_Touch-Obj0D_Index
		dc.w Obj0D_Spin-Obj0D_Index
		dc.w Obj0D_SonicRun-Obj0D_Index
		dc.w locret_ED1A-Obj0D_Index
; ===========================================================================

Obj0D_Main:				; XREF: Obj0D_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj0D,4(a0)
		move.w	#$680,2(a0)
		move.b	#4,1(a0)
		move.b	#$18,Obj_SprWidth(a0)
		move.w	#$200,Obj_Priority(a0)

Obj0D_Touch:				; XREF: Obj0D_Index
		move.w	($FFFFD008).w,d0
		sub.w	8(a0),d0
		bcs.s	locret_EBBA
		cmpi.w	#$20,d0		; is Sonic within $20 pixels of	the signpost?
		bcc.s	locret_EBBA	; if not, branch
		move.w	#$CF,d0
		jsr	(PlaySound).l	; play signpost	sound
		clr.b	($FFFFFE1E).w	; stop time counter
		move.w	($FFFFF72A).w,($FFFFF728).w ; lock screen position
		addq.b	#2,$24(a0)

locret_EBBA:
		rts	
; ===========================================================================

Obj0D_Spin:				; XREF: Obj0D_Index
		subq.w	#1,$30(a0)	; subtract 1 from spin time
		bpl.s	Obj0D_Sparkle	; if time remains, branch
		move.w	#60,$30(a0)	; set spin cycle time to 1 second
		addq.b	#1,$1C(a0)	; next spin cycle
		cmpi.b	#3,$1C(a0)	; have 3 spin cycles completed?
		bne.s	Obj0D_Sparkle	; if not, branch
		addq.b	#2,$24(a0)

Obj0D_Sparkle:
		subq.w	#1,$32(a0)	; subtract 1 from time delay
		bpl.s	locret_EC42	; if time remains, branch
		move.w	#$B,$32(a0)	; set time between sparkles to $B frames
		moveq	#0,d0
		move.b	$34(a0),d0
		addq.b	#2,$34(a0)
		andi.b	#$E,$34(a0)
		lea	Obj0D_SparkPos(pc,d0.w),a2 ; load sparkle position data
		bsr.w	SingleObjLoad
		bne.s	locret_EC42
		move.b	#$25,0(a1)	; load rings object
		move.b	#6,$24(a1)	; jump to ring sparkle subroutine
		move.b	(a2)+,d0
		ext.w	d0
		add.w	8(a0),d0
		move.w	d0,8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		move.l	#Map_obj25,4(a1)
		move.w	#$27B2,2(a1)
		move.b	#4,1(a1)
		move.w	#$100,Obj_Priority(a1)
		move.b	#8,Obj_SprWidth(a1)

locret_EC42:
		rts	
; ===========================================================================
Obj0D_SparkPos:	dc.b -$18,-$10		; x-position, y-position
		dc.b	8,   8
		dc.b -$10,   0
		dc.b  $18,  -8
		dc.b	0,  -8
		dc.b  $10,   0
		dc.b -$18,   8
		dc.b  $18, $10
; ===========================================================================

Obj0D_SonicRun:				; XREF: Obj0D_Index
		tst.w	($FFFFFE08).w	; is debug mode	on?
		bne.w	locret_ECEE	; if yes, branch
		btst	#1,($FFFFD022).w
		bne.s	loc_EC70
		move.b	#1,($FFFFF7CC).w ; lock	controls
		move.w	#$800,($FFFFF602).w ; make Sonic run to	the right

loc_EC70:
		tst.b	($FFFFD000).w
		beq.s	loc_EC86
		move.w	($FFFFD008).w,d0
		move.w	($FFFFF72A).w,d1
		addi.w	#$128,d1
		cmp.w	d1,d0
		bcs.s	locret_ECEE

loc_EC86:
		addq.b	#2,$24(a0)

; ---------------------------------------------------------------------------
; Subroutine to	set up bonuses at the end of an	act
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


GotThroughAct:				; XREF: Obj3E_EndAct
		tst.b	($FFFFD5C0).w
		bne.s	locret_ECEE
		move.w	($FFFFF72A).w,($FFFFF728).w
		clr.b	($FFFFFE2D).w	; disable invincibility
		clr.b	($FFFFFE1E).w	; stop time counter
		move.b	#$3A,($FFFFD5C0).w
		moveq	#PLCID_TtlCard,d0
		jsr	(LoadPLC2).l	; load title card patterns
		move.b	#1,($FFFFF7D6).w
		moveq	#0,d0
		move.b	($FFFFFE23).w,d0
		mulu.w	#60,d0		; convert minutes to seconds
		moveq	#0,d1
		move.b	($FFFFFE24).w,d1
		add.w	d1,d0		; add up your time
		divu.w	#15,d0		; divide by 15
		moveq	#$14,d1
		cmp.w	d1,d0		; is time 5 minutes or higher?
		bcs.s	loc_ECD0	; if not, branch
		move.w	d1,d0		; use minimum time bonus (0)

loc_ECD0:
		add.w	d0,d0
		move.w	TimeBonuses(pc,d0.w),($FFFFF7D2).w ; set time bonus
		move.w	($FFFFFE20).w,d0 ; load	number of rings
		mulu.w	#10,d0		; multiply by 10
		move.w	d0,($FFFFF7D4).w ; set ring bonus

locret_ECEE:
		rts	
; End of function GotThroughAct

; ===========================================================================
TimeBonuses:	dc.w 5000, 5000, 1000, 500, 400, 400, 300, 300,	200, 200
		dc.w 200, 200, 100, 100, 100, 100, 50, 50, 50, 50, 0
; ===========================================================================

locret_ED1A:				; XREF: Obj0D_Index
		rts	
; ===========================================================================
Ani_obj0D:
	include "_anim\obj0D.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - signpost
; ---------------------------------------------------------------------------
Map_obj0D:
	include "_maps\obj0D.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Object 54 - invisible	lava tag (MZ)
; ---------------------------------------------------------------------------

Obj54:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj54_Index(pc,d0.w),d1
		jmp	Obj54_Index(pc,d1.w)
; ===========================================================================
Obj54_Index:	dc.w Obj54_Main-Obj54_Index
		dc.w Obj54_ChkDel-Obj54_Index

Obj54_Sizes:	dc.b $96, $94, $95, 0
; ===========================================================================

Obj54_Main:				; XREF: Obj54_Index
		addq.b	#2,$24(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		move.b	Obj54_Sizes(pc,d0.w),$20(a0)
		move.l	#Map_obj54,4(a0)
		move.b	#$84,1(a0)

Obj54_ChkDel:				; XREF: Obj54_Index
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj54_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject	; and delete object

Obj54_NoDel:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - invisible lava tag (MZ)
; ---------------------------------------------------------------------------
Map_obj54:
	include "_maps\obj54.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 40 - Moto Bug enemy (GHZ)
; ---------------------------------------------------------------------------

Obj40:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj40_Index(pc,d0.w),d1
		jmp	Obj40_Index(pc,d1.w)
; ===========================================================================
Obj40_Index:	dc.w Obj40_Main-Obj40_Index
		dc.w Obj40_Action-Obj40_Index
		dc.w Obj40_Animate-Obj40_Index
		dc.w Obj40_Delete-Obj40_Index
; ===========================================================================

Obj40_Main:				; XREF: Obj40_Index
		move.l	#Map_obj40,4(a0)
		move.w	#$4F0,2(a0)
		move.b	#4,1(a0)
		move.w	#$200,Obj_Priority(a0)
		move.b	#$14,Obj_SprWidth(a0)
		tst.b	$1C(a0)		; is object a smoke trail?
		bne.s	Obj40_SetSmoke	; if yes, branch
		move.b	#$E,$16(a0)
		move.b	#8,$17(a0)
		move.b	#$C,$20(a0)
		bsr.w	ObjectFall
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	locret_F68A
		add.w	d1,$C(a0)	; match	object's position with the floor
		move.w	#0,$12(a0)
		addq.b	#2,$24(a0)
		bchg	#0,$22(a0)

locret_F68A:
		rts	
; ===========================================================================

Obj40_SetSmoke:				; XREF: Obj40_Main
		addq.b	#4,$24(a0)
		bra.w	Obj40_Animate
; ===========================================================================

Obj40_Action:				; XREF: Obj40_Index
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj40_Index2(pc,d0.w),d1
		jsr	Obj40_Index2(pc,d1.w)
		lea	(Ani_obj40).l,a1
		bsr.w	AnimateSprite

; ---------------------------------------------------------------------------
; Routine to mark an enemy/monitor/ring	as destroyed
; ---------------------------------------------------------------------------

MarkObjGone:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	Mark_ChkGone
		bra.w	DisplaySprite
; ===========================================================================

Mark_ChkGone:
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject	; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject

; ===========================================================================
Obj40_Index2:	dc.w Obj40_Move-Obj40_Index2
		dc.w Obj40_FixToFloor-Obj40_Index2
; ===========================================================================

Obj40_Move:				; XREF: Obj40_Index2
		subq.w	#1,$30(a0)	; subtract 1 from pause	time
		bpl.s	locret_F70A	; if time remains, branch
		addq.b	#2,$25(a0)
		move.w	#-$100,$10(a0)	; move object to the left
		move.b	#1,$1C(a0)
		bchg	#0,$22(a0)
		bne.s	locret_F70A
		neg.w	$10(a0)		; change direction

locret_F70A:
		rts	
; ===========================================================================

Obj40_FixToFloor:			; XREF: Obj40_Index2
		bsr.w	SpeedToPos
		jsr	ObjHitFloor
		cmpi.w	#-8,d1
		blt.s	Obj40_Pause
		cmpi.w	#$C,d1
		bge.s	Obj40_Pause
		add.w	d1,$C(a0)	; match	object's position with the floor
		subq.b	#1,$33(a0)
		bpl.s	locret_F756
		move.b	#$F,$33(a0)
		bsr.w	SingleObjLoad
		bne.s	locret_F756
		move.b	#$40,0(a1)	; load exhaust smoke object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	$22(a0),$22(a1)
		move.b	#2,$1C(a1)

locret_F756:
		rts	
; ===========================================================================

Obj40_Pause:				; XREF: Obj40_FixToFloor
		subq.b	#2,$25(a0)
		move.w	#59,$30(a0)	; set pause time to 1 second
		move.w	#0,$10(a0)	; stop the object moving
		move.b	#0,$1C(a0)
		rts	
; ===========================================================================

Obj40_Animate:				; XREF: Obj40_Index
		lea	(Ani_obj40).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Obj40_Delete:				; XREF: Obj40_Index
		bra.w	DeleteObject
; ===========================================================================
Ani_obj40:
	include "_anim\obj40.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Moto Bug enemy (GHZ)
; ---------------------------------------------------------------------------
Map_obj40:
	include "_maps\obj40.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Solid	object subroutine (includes spikes, blocks, rocks etc)
;
; variables:
; d1 = width
; d2 = height /	2 (when	jumping)
; d3 = height /	2 (when	walking)
; d4 = x-axis position
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SolidObject:
		tst.b	$25(a0)
		beq.w	loc_FAC8
		move.w	d1,d2
		add.w	d2,d2
		lea	($FFFFD000).w,a1
		btst	#1,$22(a1)
		bne.s	loc_F9FE
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F9FE
		cmp.w	d2,d0
		bcs.s	loc_FA12

loc_F9FE:
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA12:
		move.w	d4,d2
		jsr	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

SolidObject71:				; XREF: Obj71_Solid
		tst.b	$25(a0)
		beq.w	loc_FAD0
		move.w	d1,d2
		add.w	d2,d2
		lea	($FFFFD000).w,a1
		btst	#1,$22(a1)
		bne.s	loc_FA44
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_FA44
		cmp.w	d2,d0
		bcs.s	loc_FA58

loc_FA44:
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA58:
		move.w	d4,d2
		jsr	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

SolidObject2F:				; XREF: Obj2F_Solid
		lea	($FFFFD000).w,a1
		tst.b	1(a0)
		bpl.w	loc_FB92
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.w	d0,d5
		btst	#0,1(a0)
		beq.s	loc_FA94
		not.w	d5
		add.w	d3,d5

loc_FA94:
		lsr.w	#1,d5
		moveq	#0,d3
		move.b	(a2,d5.w),d3
		sub.b	(a2),d3
		move.w	$C(a0),d5
		sub.w	d3,d5
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	d5,d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92
		bra.w	loc_FB0E
; ===========================================================================

loc_FAC8:
		tst.b	1(a0)
		bpl.w	loc_FB92

loc_FAD0:
		lea	($FFFFD000).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92

loc_FB0E:
		tst.b	($FFFFF7C8).w
		bmi.w	loc_FB92
		cmpi.b	#6,($FFFFD024).w
		bcc.w	loc_FB92
		tst.w	($FFFFFE08).w
		bne.w	loc_FBAC
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.s	loc_FB36
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_FB36:
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.s	loc_FB44
		subq.w	#4,d3
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_FB44:
		cmp.w	d1,d5
		bhi.w	loc_FBB0
		cmpi.w	#4,d1
		bls.s	loc_FB8C
		tst.w	d0
		beq.s	loc_FB70
		bmi.s	loc_FB5E
		tst.w	$10(a1)
		bmi.s	loc_FB70
		bra.s	loc_FB64
; ===========================================================================

loc_FB5E:
		tst.w	$10(a1)
		bpl.s	loc_FB70

loc_FB64:
		move.w	#0,Obj_Inertia(a1)	; stop Sonic moving
		move.w	#0,$10(a1)

loc_FB70:
		sub.w	d0,8(a1)
		btst	#1,$22(a1)
		bne.s	loc_FB8C
		bset	#5,$22(a1)
		bset	#5,$22(a0)
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB8C:
		bsr.s	loc_FBA0
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB92:
		btst	#5,$22(a0)
		beq.s	loc_FBAC
		cmp.b	#2,$1C(a1)	; check if in jumping/rolling animation
		beq.s	loc_FBA0
		cmp.b	#$17,$1C(a1)	; check if in drowning animation
		beq.s	loc_FBA0
		cmp.b	#$1A,$1C(a1)	; check if in hurt animation
		beq.s	loc_FBA0
		move.w	#1,$1C(a1)	; use walking animation

loc_FBA0:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)

loc_FBAC:
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FBB0:
		tst.w	d3
		bmi.s	loc_FBBC
		cmpi.w	#$10,d3
		bcs.s	loc_FBEE
		bra.s	loc_FB92
; ===========================================================================

loc_FBBC:
		tst.w	$12(a1)
		beq.s	loc_FBD6
		bpl.s	loc_FBD2
		tst.w	d3
		bpl.s	loc_FBD2
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)	; stop Sonic moving

loc_FBD2:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBD6:
		btst	#1,$22(a1)
		bne.s	loc_FBD2
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	KillSonic
		movea.l	(sp)+,a0
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBEE:
		subq.w	#4,d3
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.s	loc_FC28
		cmp.w	d2,d1
		bcc.s	loc_FC28
		tst.w	$12(a1)
		bmi.s	loc_FC28
		sub.w	d3,$C(a1)
		subq.w	#1,$C(a1)
		bsr.s	sub_FC2C
		move.b	#2,$25(a0)
		bset	#3,$22(a0)
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FC28:
		moveq	#0,d4
		rts	
; End of function SolidObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_FC2C:				; XREF: SolidObject
		btst	#3,$22(a1)
		beq.s	loc_FC4E
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,$22(a2)
		clr.b	$25(a2)

loc_FC4E:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,$26(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),Obj_Inertia(a1)
		btst	#1,$22(a1)
		beq.s	loc_FC84
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	Sonic_ResetOnFloor
		movea.l	(sp)+,a0

loc_FC84:
		bset	#3,$22(a1)
		bset	#3,$22(a0)
		rts	
; End of function sub_FC2C

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 71 - invisible	solid blocks
; ---------------------------------------------------------------------------

Obj71:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj71_Index(pc,d0.w),d1
		jmp	Obj71_Index(pc,d1.w)
; ===========================================================================
Obj71_Index:	dc.w Obj71_Main-Obj71_Index
		dc.w Obj71_Solid-Obj71_Index
; ===========================================================================

Obj71_Main:				; XREF: Obj71_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj71,4(a0)
		move.w	#$8680,2(a0)
		ori.b	#4,1(a0)
		move.b	$28(a0),d0	; get object type
		move.b	d0,d1
		andi.w	#$F0,d0		; read only the	1st byte
		addi.w	#$10,d0
		lsr.w	#1,d0
		move.b	d0,Obj_SprWidth(a0)	; set object width
		andi.w	#$F,d1		; read only the	2nd byte
		addq.w	#1,d1
		lsl.w	#3,d1
		move.b	d1,$16(a0)	; set object height

Obj71_Solid:				; XREF: Obj71_Index
		bsr.w	ChkObjOnScreen
		bne.s	Obj71_ChkDel
		moveq	#0,d1
		move.b	Obj_SprWidth(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject71

Obj71_ChkDel:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj71_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj71_Delete		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj71_Delete	; and delete object

Obj71_NoDel:
		tst.w	($FFFFFE08).w	; are you using	debug mode?
		beq.s	Obj71_NoDisplay	; if not, branch
		jmp	DisplaySprite	; if yes, display the object
; ===========================================================================

Obj71_NoDisplay:
		rts	
; ===========================================================================

Obj71_Delete:
		jmp	DeleteObject
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - invisible solid blocks
; ---------------------------------------------------------------------------
Map_obj71:
	include "_maps\obj71.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Object 64 - bubbles (LZ)
; ---------------------------------------------------------------------------

Obj64:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj64_Index(pc,d0.w),d1
		jmp	Obj64_Index(pc,d1.w)
; ===========================================================================
Obj64_Index:	dc.w Obj64_Main-Obj64_Index
		dc.w Obj64_Animate-Obj64_Index
		dc.w Obj64_ChkWater-Obj64_Index
		dc.w Obj64_Display2-Obj64_Index
		dc.w Obj64_Delete3-Obj64_Index
		dc.w Obj64_BblMaker-Obj64_Index
; ===========================================================================

Obj64_Main:				; XREF: Obj64_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj64,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	$28(a0),d0	; get object type
		bpl.s	Obj64_Bubble	; if type is $0-$7F, branch
		addq.b	#8,$24(a0)
		andi.w	#$7F,d0		; read only last 7 bits	(deduct	$80)
		move.b	d0,$32(a0)
		move.b	d0,$33(a0)
		move.b	#6,$1C(a0)
		bra.w	Obj64_BblMaker
; ===========================================================================

Obj64_Bubble:				; XREF: Obj64_Main
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)	; float	bubble upwards
		jsr	(RandomNumber).l
		move.b	d0,$26(a0)

Obj64_Animate:				; XREF: Obj64_Index
		lea	(Ani_obj64).l,a1
		jsr	AnimateSprite
		cmpi.b	#6,$1A(a0)
		bne.s	Obj64_ChkWater
		move.b	#1,$2E(a0)

Obj64_ChkWater:				; XREF: Obj64_Index
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; is bubble underwater?
		bcs.s	Obj64_Wobble	; if yes, branch

Obj64_Burst:				; XREF: Obj64_Wobble
		move.b	#6,$24(a0)
		addq.b	#3,$1C(a0)	; run "bursting" animation
		bra.w	Obj64_Display2
; ===========================================================================

Obj64_Wobble:				; XREF: Obj64_ChkWater
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; change bubble's horizontal position
		tst.b	$2E(a0)
		beq.s	Obj64_Display
		bsr.w	Obj64_ChkSonic	; has Sonic touched the	bubble?
		beq.s	Obj64_Display	; if not, branch

		bsr.w	ResumeMusic	; cancel countdown music
		move.w	#$AD,d0
		jsr	(PlaySound_Special).l ;	play collecting	bubble sound
		lea	($FFFFD000).w,a1
		clr.w	$10(a1)
		clr.w	$12(a1)
		clr.w	Obj_Inertia(a1)
		move.b	#$15,$1C(a1)
		move.w	#$23,$3E(a1)
		move.b	#0,$3C(a1)
		bclr	#5,$22(a1)
		bclr	#4,$22(a1)
		btst	#2,$22(a1)
		beq.w	Obj64_Burst
		bclr	#2,$22(a1)
		move.b	#$13,$16(a1)
		move.b	#9,$17(a1)
		subq.w	#5,$C(a1)
		bra.w	Obj64_Burst
; ===========================================================================

Obj64_Display:				; XREF: Obj64_Wobble
		bsr.w	SpeedToPos
		tst.b	1(a0)
		bpl.s	Obj64_Delete
		jmp	DisplaySprite
; ===========================================================================

Obj64_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj64_Display2:				; XREF: Obj64_Index
		lea	(Ani_obj64).l,a1
		jsr	AnimateSprite
		tst.b	1(a0)
		bpl.s	Obj64_Delete2
		jmp	DisplaySprite
; ===========================================================================

Obj64_Delete2:
		jmp	DeleteObject
; ===========================================================================

Obj64_Delete3:				; XREF: Obj64_Index
		bra.w	DeleteObject
; ===========================================================================

Obj64_BblMaker:				; XREF: Obj64_Index
		tst.w	$36(a0)
		bne.s	loc_12874
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; is bubble maker underwater?
		bcc.w	Obj64_ChkDel	; if not, branch
		tst.b	1(a0)
		bpl.w	Obj64_ChkDel
		subq.w	#1,$38(a0)
		bpl.w	loc_12914
		move.w	#1,$36(a0)

loc_1283A:
		jsr	(RandomNumber).l
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bcc.s	loc_1283A

		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	(Obj64_BblTypes).l,a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,$32(a0)
		bpl.s	loc_12872
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)

loc_12872:
		bra.s	loc_1287C
; ===========================================================================

loc_12874:				; XREF: Obj64_BblMaker
		subq.w	#1,$38(a0)
		bpl.w	loc_12914

loc_1287C:
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		bsr.w	SingleObjLoad
		bne.s	loc_128F8
		move.b	#$64,0(a1)	; load bubble object
		move.w	8(a0),8(a1)
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,8(a1)
		move.w	$C(a0),$C(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),$28(a1)
		btst	#7,$36(a0)
		beq.s	loc_128F8
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	loc_128E4
		bset	#6,$36(a0)
		bne.s	loc_128F8
		move.b	#2,$28(a1)

loc_128E4:
		tst.b	$34(a0)
		bne.s	loc_128F8
		bset	#6,$36(a0)
		bne.s	loc_128F8
		move.b	#2,$28(a1)

loc_128F8:
		subq.b	#1,$34(a0)
		bpl.s	loc_12914
		jsr	(RandomNumber).l
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,$38(a0)
		clr.w	$36(a0)

loc_12914:
		lea	(Ani_obj64).l,a1
		jsr	AnimateSprite

Obj64_ChkDel:				; XREF: Obj64_BblMaker
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj64_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.w	DeleteObject		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.w	DeleteObject	; and delete object

Obj64_NoDel:
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcs.w	DisplaySprite
		rts	
; ===========================================================================
; bubble production sequence

; 0 = small bubble, 1 =	large bubble

Obj64_BblTypes:	dc.b 0,	1, 0, 0, 0, 0, 1, 0, 0,	0, 0, 1, 0, 1, 0, 0, 1,	0

; ===========================================================================

Obj64_ChkSonic:				; XREF: Obj64_Wobble
		tst.b	($FFFFF7C8).w
		bmi.s	loc_12998
		lea	($FFFFD000).w,a1
		move.w	8(a1),d0
		move.w	8(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bcc.s	loc_12998
		addi.w	#$20,d1
		cmp.w	d0,d1
		bcs.s	loc_12998
		move.w	$C(a1),d0
		move.w	$C(a0),d1
		cmp.w	d0,d1
		bcc.s	loc_12998
		addi.w	#$10,d1
		cmp.w	d0,d1
		bcs.s	loc_12998
		moveq	#1,d0
		rts	
; ===========================================================================

loc_12998:
		moveq	#0,d0
		rts	
; ===========================================================================
Ani_obj64:
	include "_anim\obj64.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - bubbles (LZ)
; ---------------------------------------------------------------------------
Map_obj64:
	include "_maps\obj64.asm"

; ===========================================================================

SpinDash_dust:
Sprite_1DD20:				; DATA XREF: ROM:0001600C?o
		moveq	#0,d0
		move.b	$24(a0),d0
		move	off_1DD2E(pc,d0.w),d1
		jmp	off_1DD2E(pc,d1.w)
; ===========================================================================
off_1DD2E:	dc loc_1DD36-off_1DD2E; 0 ; DATA XREF: h+6DBA?o h+6DBC?o ...
		dc loc_1DD90-off_1DD2E; 1
		dc loc_1DE46-off_1DD2E; 2
		dc loc_1DE4A-off_1DD2E; 3
; ===========================================================================

loc_1DD36:				; DATA XREF: h+6DBA?o
		addq.b	#2,$24(a0)
		move.l	#MapUnc_1DF5E,4(a0)
		or.b	#4,1(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move	#$7A0,2(a0)
		move	#-$3000,$3E(a0)
		move	#$F400,$3C(a0)
		cmp	#-$2E40,a0
		beq.s	loc_1DD8C
		move.b	#1,$34(a0)
;		cmp	#2,($FFFFFF70).w
;		beq.s	loc_1DD8C
;		move	#$48C,2(a0)
;		move	#-$4FC0,$3E(a0)
;		move	#-$6E80,$3C(a0)

loc_1DD8C:				; CODE XREF: h+6DF6?j h+6E04?j
;		bsr.w	sub_16D6E

loc_1DD90:				; DATA XREF: h+6DBA?o
		movea.w	$3E(a0),a2
		moveq	#0,d0
		move.b	$1C(a0),d0
		add	d0,d0
		move	off_1DDA4(pc,d0.w),d1
		jmp	off_1DDA4(pc,d1.w)
; ===========================================================================
off_1DDA4:	dc loc_1DE28-off_1DDA4; 0 ; DATA XREF: h+6E30?o h+6E32?o ...
		dc loc_1DDAC-off_1DDA4; 1
		dc loc_1DDCC-off_1DDA4; 2
		dc loc_1DE20-off_1DDA4; 3
; ===========================================================================

loc_1DDAC:				; DATA XREF: h+6E30?o
		move	($FFFFF646).w,$C(a0)
		tst.b	$1D(a0)
		bne.s	loc_1DE28
		move	8(a2),8(a0)
		move.b	#0,$22(a0)
		and	#$7FFF,2(a0)
		bra.s	loc_1DE28
; ===========================================================================

loc_1DDCC:				; DATA XREF: h+6E30?o
;		cmp.b	#$C,$28(a2)
;		bcs.s	loc_1DE3E
		cmp.b	#4,$24(a2)
		bcc.s	loc_1DE3E
		tst.b	$39(a2)
		beq.s	loc_1DE3E
		move	8(a2),8(a0)
		move	$C(a2),$C(a0)
		move.b	$22(a2),$22(a0)
		and.b	#1,$22(a0)
		tst.b	$34(a0)
		beq.s	loc_1DE06
		sub	#4,$C(a0)

loc_1DE06:				; CODE XREF: h+6E8A?j
		tst.b	$1D(a0)
		bne.s	loc_1DE28
		and	#$7FFF,2(a0)
		tst	2(a2)
		bpl.s	loc_1DE28
		or	#-$8000,2(a0)
; ===========================================================================

loc_1DE20:				; DATA XREF: h+6E30?o
loc_1DE28:				; CODE XREF: h+6E42?j h+6E56?j ...
		lea	(off_1DF38).l,a1
		jsr	AnimateSprite
		bsr.w	loc_1DEE4
		jmp	DisplaySprite
; ===========================================================================

loc_1DE3E:				; CODE XREF: h+6E5E?j h+6E66?j ...
		move.b	#0,$1C(a0)
		rts	
; ===========================================================================

loc_1DE46:				; DATA XREF: h+6DBA?o
		bra.w	DeleteObject
; ===========================================================================



loc_1DE4A:
	movea.w	$3E(a0),a2
	moveq	#$10,d1
	cmp.b	#$D,$1C(a2)
	beq.s	loc_1DE64
	moveq	#$6,d1
	cmp.b	#$3,$21(a2)
	beq.s	loc_1DE64
	move.b	#2,$24(a0)
	move.b	#0,$32(a0)
	rts
; ===========================================================================

loc_1DE64:				; CODE XREF: h+6EE0?j
		subq.b	#1,$32(a0)
		bpl.s	loc_1DEE0
		move.b	#3,$32(a0)
		jsr	SingleObjLoad
		bne.s	loc_1DEE0
		move.b	0(a0),0(a1)
		move	8(a2),8(a1)
		move	$C(a2),$C(a1)
		tst.b	$34(a0)
		beq.s	loc_1DE9A
		sub	#4,d1

loc_1DE9A:				; CODE XREF: h+6F1E?j
		add	d1,$C(a1)
		move.b	#0,$22(a1)
		move.b	#3,$1C(a1)
		addq.b	#2,$24(a1)
		move.l	4(a0),4(a1)
		move.b	1(a0),1(a1)
		move.w	#$80,Obj_Priority(a1)
		move.b	#4,Obj_SprWidth(a1)
		move	2(a0),2(a1)
		move	$3E(a0),$3E(a1)
		and	#$7FFF,2(a1)
		tst	2(a2)
		bpl.s	loc_1DEE0
		or	#-$8000,2(a1)

loc_1DEE0:				; CODE XREF: h+6EF4?j h+6F00?j ...
		bsr.s	loc_1DEE4
		rts	
; ===========================================================================

loc_1DEE4:				; CODE XREF: h+6EC0?p h+6F6C?p
		moveq	#0,d0
		move.b	$1A(a0),d0
		cmp.b	$30(a0),d0
		beq.w	locret_1DF36
		move.b	d0,$30(a0)
		lea	(off_1E074).l,a2
		add	d0,d0
		add	(a2,d0.w),a2
		move	(a2)+,d5
		subq	#1,d5
		bmi.w	locret_1DF36
		move $3C(a0),d4

loc_1DF0A:				; CODE XREF: h+6FBE?j
		moveq	#0,d1
		move	(a2)+,d1
		move	d1,d3
		lsr.w	#8,d3
		and	#$F0,d3	; 'ð'
		add	#$10,d3
		and	#$FFF,d1
		lsl.l	#5,d1
		add.l	#Art_Dust,d1
		move	d4,d2
		add	d3,d4
		add	d3,d4
		jsr	(QueueDMATransfer).l
		dbf	d5,loc_1DF0A
    rts

locret_1DF36:				; CODE XREF: h+6F7A?j h+6F90?j
		rts	
; ===========================================================================
off_1DF38:	dc byte_1DF40-off_1DF38; 0 ; DATA XREF: h+6EB4?o h+6FC4?o ...
		dc byte_1DF43-off_1DF38; 1
		dc byte_1DF4F-off_1DF38; 2
		dc byte_1DF58-off_1DF38; 3
byte_1DF40:	dc.b $1F,  0,$FF	; 0 ; DATA XREF: h+6FC4?o
byte_1DF43:	dc.b   3,  1,  2,  3,  4,  5,  6,  7,  8,  9,$FD,  0; 0	; DATA XREF: h+6FC4?o
byte_1DF4F:	dc.b   1, $A, $B, $C, $D, $E, $F,$10,$FF; 0 ; DATA XREF: h+6FC4?o
byte_1DF58:	dc.b   3,$11,$12,$13,$14,$FC; 0	; DATA XREF: h+6FC4?o
; -------------------------------------------------------------------------------
; Unknown Sprite Mappings
; -------------------------------------------------------------------------------
MapUnc_1DF5E:
	dc word_1DF8A-MapUnc_1DF5E; 0
	dc word_1DF8C-MapUnc_1DF5E; 1
	dc word_1DF96-MapUnc_1DF5E; 2
	dc word_1DFA0-MapUnc_1DF5E; 3
	dc word_1DFAA-MapUnc_1DF5E; 4
	dc word_1DFB4-MapUnc_1DF5E; 5
	dc word_1DFBE-MapUnc_1DF5E; 6
	dc word_1DFC8-MapUnc_1DF5E; 7
	dc word_1DFD2-MapUnc_1DF5E; 8
	dc word_1DFDC-MapUnc_1DF5E; 9
	dc word_1DFE6-MapUnc_1DF5E; 10
	dc word_1DFF0-MapUnc_1DF5E; 11
	dc word_1DFFA-MapUnc_1DF5E; 12
	dc word_1E004-MapUnc_1DF5E; 13
	dc word_1E016-MapUnc_1DF5E; 14
	dc word_1E028-MapUnc_1DF5E; 15
	dc word_1E03A-MapUnc_1DF5E; 16
	dc word_1E04C-MapUnc_1DF5E; 17
	dc word_1E056-MapUnc_1DF5E; 18
	dc word_1E060-MapUnc_1DF5E; 19
	dc word_1E06A-MapUnc_1DF5E; 20
	dc word_1DF8A-MapUnc_1DF5E; 21
word_1DF8A:	dc.b 0
word_1DF8C:	dc.b 1
	dc.b $F2, $0D, $0, 0,$F0; 0
word_1DF96:	dc.b 1
	dc.b $E2, $0F, $0, 0,$F0; 0
word_1DFA0:	dc.b 1
	dc.b $E2, $0F, $0, 0,$F0; 0
word_1DFAA:	dc.b 1
	dc.b $E2, $0F, $0, 0,$F0; 0
word_1DFB4:	dc.b 1
	dc.b $E2, $0F, $0, 0,$F0; 0
word_1DFBE:	dc.b 1
	dc.b $E2, $0F, $0, 0,$F0; 0
word_1DFC8:	dc.b 1
	dc.b $F2, $0D, $0, 0,$F0; 0
word_1DFD2:	dc.b 1
	dc.b $F2, $0D, $0, 0,$F0; 0
word_1DFDC:	dc.b 1
	dc.b $F2, $0D, $0, 0,$F0; 0
word_1DFE6:	dc.b 1
	dc.b $4, $0D, $0, 0,$E0; 0
word_1DFF0:	dc.b 1
	dc.b $4, $0D, $0, 0,$E0; 0
word_1DFFA:	dc.b 1
	dc.b $4, $0D, $0, 0,$E0; 0
word_1E004:	dc.b 2
	dc.b $F4, $01, $0, 0,$E8; 0
	dc.b $4, $0D, $0, 2,$E0; 4
word_1E016:	dc.b 2
	dc.b $F4, $05, $0, 0,$E8; 0
	dc.b $4, $0D, $0, 4,$E0; 4
word_1E028:	dc.b 2
	dc.b $F4, $09, $0, 0,$E0; 0
	dc.b $4, $0D, $0, 6,$E0; 4
word_1E03A:	dc.b 2
	dc.b $F4, $09, $0, 0,$E0; 0
	dc.b $4, $0D, $0, 6,$E0; 4
word_1E04C:	dc.b 1
	dc.b $F8, $05, $0, 0,$F8; 0
word_1E056:	dc.b 1
	dc.b $F8, $05, $0, 4,$F8; 0
word_1E060:	dc.b 1
	dc.b $F8, $05, $0, 8,$F8; 0
word_1E06A:	dc.b 1
	dc.b $F8, $05, $0, $C,$F8; 0
	dc.b 0
off_1E074:	dc word_1E0A0-off_1E074; 0
	dc word_1E0A2-off_1E074; 1
	dc word_1E0A6-off_1E074; 2
	dc word_1E0AA-off_1E074; 3
	dc word_1E0AE-off_1E074; 4
	dc word_1E0B2-off_1E074; 5
	dc word_1E0B6-off_1E074; 6
	dc word_1E0BA-off_1E074; 7
	dc word_1E0BE-off_1E074; 8
	dc word_1E0C2-off_1E074; 9
	dc word_1E0C6-off_1E074; 10
	dc word_1E0CA-off_1E074; 11
	dc word_1E0CE-off_1E074; 12
	dc word_1E0D2-off_1E074; 13
	dc word_1E0D8-off_1E074; 14
	dc word_1E0DE-off_1E074; 15
	dc word_1E0E4-off_1E074; 16
	dc word_1E0EA-off_1E074; 17
	dc word_1E0EA-off_1E074; 18
	dc word_1E0EA-off_1E074; 19
	dc word_1E0EA-off_1E074; 20
	dc word_1E0EC-off_1E074; 21
word_1E0A0:	dc 0
word_1E0A2:	dc 1
	dc $7000
word_1E0A6:	dc 1
	dc $F008
word_1E0AA:	dc 1
	dc $F018
word_1E0AE:	dc 1
	dc $F028
word_1E0B2:	dc 1
	dc $F038
word_1E0B6:	dc 1
	dc $F048
word_1E0BA:	dc 1
	dc $7058
word_1E0BE:	dc 1
	dc $7060
word_1E0C2:	dc 1
	dc $7068
word_1E0C6:	dc 1
	dc $7070
word_1E0CA:	dc 1
	dc $7078
word_1E0CE:	dc 1
	dc $7080
word_1E0D2:	dc 2
	dc $1088
	dc $708A
word_1E0D8:	dc 2
	dc $3092
	dc $7096
word_1E0DE:	dc 2
	dc $509E
	dc $70A4
word_1E0E4:	dc 2
	dc $50AC
	dc $70B2
word_1E0EA:	dc 0
word_1E0EC:	dc 1
	dc $F0BA
	even

; ---------------------------------------------------------------------------
; Object 01 - Sonic
; ---------------------------------------------------------------------------

Obj01:					; XREF: Obj_Index
		tst.w	($FFFFFE08).w	; is debug mode	being used?
		beq.s	Obj01_Normal	; if not, branch
		jmp	DebugMode
; ===========================================================================

Obj01_Normal:
		moveq	#0,d0
		move.b	Obj_Routine(a0),d0
		move.w	Obj01_Index(pc,d0.w),d1
		jmp	Obj01_Index(pc,d1.w)
; ===========================================================================
Obj01_Index:	dc.w Obj01_Main-Obj01_Index
		dc.w Obj01_Control-Obj01_Index
		dc.w Obj01_Hurt-Obj01_Index
		dc.w Obj01_Death-Obj01_Index
		dc.w Obj01_ResetLevel-Obj01_Index
		dc.w Sonic_Drowned-Obj01_Index
; ===========================================================================

Obj01_Main:				; XREF: Obj01_Index
		move.b	#$00,($FFFFFFF7).w			; MJ: set collision to 1st
		move.b	#5,$FFFFD1C0.w
		addq.b	#2,Obj_Routine(a0)
		move.b	#$13,Obj_YHitbox(a0)
		move.b	#9,Obj_XHitbox(a0)
		move.l	#Map_Sonic,Obj_Mappings(a0)
		move.w	#$780,Obj_ArtTile(a0)
		move.w	#$100,Obj_Priority(a0)
		move.b	#$18,Obj_SprWidth(a0)
		move.b	#4,Obj_Render(a0)
		move.w	#$600,($FFFFF760).w ; Sonic's top speed
		move.w	#$C,($FFFFF762).w ; Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; Sonic's deceleration

Obj01_Control:				; XREF: Obj01_Index
		tst.w	($FFFFFFFA).w	; is debug cheat enabled?
		beq.s	loc_12C58	; if not, branch
		btst	#4,($FFFFF605).w ; is button C pressed?
		beq.s	loc_12C58	; if not, branch
		move.w	#1,($FFFFFE08).w ; change Sonic	into a ring/item
		clr.b	($FFFFF7CC).w
		rts	
; ===========================================================================

loc_12C58:
		tst.b	($FFFFF7CC).w	; are controls locked?
		bne.s	loc_12C64	; if yes, branch
		move.w	($FFFFF604).w,($FFFFF602).w ; enable joypad control

loc_12C64:
		btst	#0,($FFFFF7C8).w ; are controls	locked?
		bne.s	loc_12C7E	; if yes, branch
		moveq	#0,d0
		move.b	Obj_Status(a0),d0
		andi.w	#6,d0
		move.w	Obj01_Modes(pc,d0.w),d1
		jsr	Obj01_Modes(pc,d1.w)

loc_12C7E:
		bsr.s	Sonic_Display
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Water
		move.b	($FFFFF768).w,Plyr_FrontAngle(a0)
		move.b	($FFFFF76A).w,Plyr_BackAngle(a0)
		tst.b	($FFFFF7C7).w
		beq.s	loc_12CA6
		tst.b	Obj_Animation(a0)
		bne.s	loc_12CA6
		move.b	Obj_AnimRstrt(a0),Obj_Animation(a0)

loc_12CA6:
		bsr.w	Sonic_Animate
		tst.b	($FFFFF7C8).w
		bmi.s	loc_12CB6
		jsr	TouchResponse

loc_12CB6:
		bsr.w	LoadSonicDynPLC
		rts	
; ===========================================================================
Obj01_Modes:	dc.w Obj01_MdNormal-Obj01_Modes
		dc.w Obj01_MdJump-Obj01_Modes
		dc.w Obj01_MdRoll-Obj01_Modes
		dc.w Obj01_MdJump2-Obj01_Modes
; ===========================================================================

Sonic_Display:				; XREF: loc_12C7E
		move.w	Plyr_InvulnTime(a0),d0
		beq.s	Obj01_Display
		subq.w	#1,Plyr_InvulnTime(a0)
		lsr.w	#3,d0
		bcc.s	Obj01_ChkInvin

Obj01_Display:
		jsr	DisplaySprite

Obj01_ChkInvin:
		tst.b	($FFFFFE2D).w	; does Sonic have invincibility?
		beq.s	Obj01_ChkShoes	; if not, branch
		tst.w	Plyr_InvincTime(a0)		; check	time remaining for invinciblity
		beq.s	Obj01_ChkShoes	; if no	time remains, branch
		subq.w	#1,Plyr_InvincTime(a0)	; subtract 1 from time
		bne.s	Obj01_ChkShoes
		tst.b	($FFFFF7AA).w
		bne.s	Obj01_RmvInvin
		cmpi.w	#$C,($FFFFFE14).w
		bcs.s	Obj01_RmvInvin
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		cmpi.w	#$103,($FFFFFE10).w ; check if level is	SBZ3
		bne.s	Obj01_PlayMusic
		moveq	#5,d0		; play SBZ music

Obj01_PlayMusic:
		lea	(MusicList).l,a1
		move.b	(a1,d0.w),d0
		jsr	(PlaySound).l	; play normal music

Obj01_RmvInvin:
		move.b	#0,($FFFFFE2D).w ; cancel invincibility

Obj01_ChkShoes:
		tst.b	($FFFFFE2E).w	; does Sonic have speed	shoes?
		beq.s	Obj01_ExitChk	; if not, branch
		tst.w	Plyr_SpeedTime(a0)		; check	time remaining
		beq.s	Obj01_ExitChk
		subq.w	#1,Plyr_SpeedTime(a0)	; subtract 1 from time
		bne.s	Obj01_ExitChk
		move.w	#$600,($FFFFF760).w ; restore Sonic's speed
		move.w	#$C,($FFFFF762).w ; restore Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; restore Sonic's deceleration
		move.b	#0,($FFFFFE2E).w ; cancel speed	shoes
		move.w	#$E3,d0
		jmp	(PlaySound).l	; run music at normal speed
; ===========================================================================

Obj01_ExitChk:
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	record Sonic's previous positions for invincibility stars
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RecordPos:			; XREF: loc_12C7E; Obj01_Hurt; Obj01_Death
		move.w	($FFFFF7A8).w,d0
		lea	($FFFFCB00).w,a1
		lea	(a1,d0.w),a1
		move.w	Obj_XPosition(a0),(a1)+
		move.w	Obj_YPosition(a0),(a1)+
		addq.b	#4,($FFFFF7A9).w
		rts	
; End of function Sonic_RecordPos

; ---------------------------------------------------------------------------
; Subroutine for Sonic when he's underwater
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Water:				; XREF: loc_12C7E
		cmpi.b	#1,($FFFFFE10).w ; is level LZ?
		beq.s	Obj01_InWater	; if yes, branch

locret_12D80:
		rts	
; ===========================================================================

Obj01_InWater:
		move.w	($FFFFF646).w,d0
		cmp.w	Obj_YPosition(a0),d0	; is Sonic above the water?
		bge.s	Obj01_OutWater	; if yes, branch
		bset	#6,$22(a0)
		bne.s	locret_12D80
		bsr.w	ResumeMusic
		move.b	#$A,($FFFFD340).w ; load bubbles object	from Sonic's mouth
		move.b	#$81,($FFFFD368).w
		move.w	#$300,($FFFFF760).w ; change Sonic's top speed
		move.w	#6,($FFFFF762).w ; change Sonic's acceleration
		move.w	#$40,($FFFFF764).w ; change Sonic's deceleration
		asr	Obj_XVelocity(a0)
		asr	Obj_YVelocity(a0)
		asr	Obj_YVelocity(a0)
		beq.s	locret_12D80
        move.w	#$100,($FFFFD1DC).w    ; set the spin dash dust animation to splash
		move.w	#$AA,d0
		jmp	(PlaySound_Special).l ;	play splash sound
; ===========================================================================

Obj01_OutWater:
		bclr	#6,Obj_Status(a0)
		beq.s	locret_12D80
		bsr.w	ResumeMusic
		move.w	#$600,($FFFFF760).w ; restore Sonic's speed
		move.w	#$C,($FFFFF762).w ; restore Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; restore Sonic's deceleration
		asl	Obj_YVelocity(a0)
		tst.w	Obj_YVelocity(a0)
		beq.w	locret_12D80
        move.w	#$100,($FFFFD1DC).w    ; set the spin dash dust animation to splash
		cmpi.w	#-$1000,Obj_YVelocity(a0)
		bgt.s	loc_12E0E
		move.w	#-$1000,Obj_YVelocity(a0)	; set maximum speed on leaving water

loc_12E0E:
		move.w	#$AA,d0
		jmp	(PlaySound_Special).l ;	play splash sound
; End of function Sonic_Water

; ===========================================================================
; ---------------------------------------------------------------------------
; Modes	for controlling	Sonic
; ---------------------------------------------------------------------------

Obj01_MdNormal:				; XREF: Obj01_Modes
		bsr.w	Sonic_SpinDash
		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBound
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts	
; ===========================================================================

Obj01_MdJump:				; XREF: Obj01_Modes
		clr.b	$39(a0)
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBound
		jsr	ObjectFall
		btst	#6,Obj_Status(a0)
		beq.s	loc_12E5C
		subi.w	#$28,Obj_YVelocity(a0)

loc_12E5C:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts	
; ===========================================================================

Obj01_MdRoll:				; XREF: Obj01_Modes
		bsr.w	Sonic_Jump
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBound
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts	
; ===========================================================================

Obj01_MdJump2:				; XREF: Obj01_Modes
		clr.b	$39(a0)
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBound
		jsr	ObjectFall
		btst	#6,Obj_Status(a0)
		beq.s	loc_12EA6
		subi.w	#$28,Obj_YVelocity(a0)

loc_12EA6:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	make Sonic walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Move:				; XREF: Obj01_MdNormal
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		move.w	($FFFFF764).w,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_12FEE
		tst.w	Plyr_CtrlLock(a0)
		bne.w	Obj01_ResetScr
		btst	#2,($FFFFF602).w ; is left being pressed?
		beq.s	Obj01_NotLeft	; if not, branch
		bsr.w	Sonic_MoveLeft

Obj01_NotLeft:
		btst	#3,($FFFFF602).w ; is right being pressed?
		beq.s	Obj01_NotRight	; if not, branch
		bsr.w	Sonic_MoveRight

Obj01_NotRight:
		move.b	Obj_Angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0		; is Sonic on a	slope?
		bne.w	Obj01_ResetScr	; if yes, branch
		tst.w	Obj_Inertia(a0)		; is Sonic moving?
		bne.w	Obj01_ResetScr	; if yes, branch
		bclr	#5,Obj_Status(a0)
		move.b	#5,Obj_Animation(a0)	; use "standing" animation
		btst	#3,Obj_Status(a0)
		beq.s	Sonic_Balance
		moveq	#0,d0
		move.b	Plyr_ObjOnTopOf(a0),d0
		lsl.w	#6,d0
		lea	($FFFFD000).w,a1
		lea	(a1,d0.w),a1
		tst.b	Obj_Status(a1)
		bmi.s	Sonic_LookUp
		moveq	#0,d1
		move.b	Obj_SprWidth(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	Obj_XPosition(a0),d1
		sub.w	Obj_XPosition(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_12F6A
		cmp.w	d2,d1
		bge.s	loc_12F5A
		bra.s	Sonic_LookUp
; ===========================================================================

Sonic_Balance:
		jsr	ObjHitFloor
		cmpi.w	#$C,d1
		blt.s	Sonic_LookUp
		cmpi.b	#3,Plyr_FrontAngle(a0)
		bne.s	loc_12F62

loc_12F5A:
		bclr	#0,Obj_Status(a0)
		bra.s	loc_12F70
; ===========================================================================

loc_12F62:
		cmpi.b	#3,Plyr_BackAngle(a0)
		bne.s	Sonic_LookUp

loc_12F6A:
		bset	#0,Obj_Status(a0)

loc_12F70:
		move.b	#6,Obj_Animation(a0)	; use "balancing" animation
		bra.s	Obj01_ResetScr
; ===========================================================================

Sonic_LookUp:
		btst	#0,($FFFFF602).w ; is up being pressed?
		beq.s	Sonic_Duck	; if not, branch
		move.b	#7,$1C(a0)	; use "looking up" animation
		addq.b	#1,($FFFFC903).w
		cmp.b	#$78,($FFFFC903).w
		bcs.s	Obj01_ResetScr_Part2
		move.b	#$78,($FFFFC903).w
		cmpi.w	#$C8,($FFFFF73E).w
		beq.s	loc_12FC2
		addq.w	#2,($FFFFF73E).w
		bra.s	loc_12FC2
; ===========================================================================

Sonic_Duck:
		btst	#1,($FFFFF602).w ; is down being pressed?
		beq.s	Obj01_ResetScr	; if not, branch
		move.b	#8,$1C(a0)	; use "ducking"	animation
		addq.b	#1,($FFFFC903).w
		cmpi.b	#$78,($FFFFC903).w
		bcs.s	Obj01_ResetScr_Part2
		move.b	#$78,($FFFFC903).w
		cmpi.w	#8,($FFFFF73E).w
		beq.s	loc_12FC2
		subq.w	#2,($FFFFF73E).w
		bra.s	loc_12FC2
; ===========================================================================

Obj01_ResetScr:
		move.b	#0,($FFFFC903).w
		
Obj01_ResetScr_Part2:
		cmpi.w	#$60,($FFFFF73E).w ; is	screen in its default position?
		beq.s	loc_12FC2	; if yes, branch
		bcc.s	loc_12FBE
		addq.w	#4,($FFFFF73E).w ; move	screen back to default

loc_12FBE:
		subq.w	#2,($FFFFF73E).w ; move	screen back to default

loc_12FC2:
		move.b	($FFFFF602).w,d0
		andi.b	#$C,d0		; is left/right	pressed?
		bne.s	loc_12FEE	; if yes, branch
		move.w	Obj_Inertia(a0),d0
		beq.s	loc_12FEE
		bmi.s	loc_12FE2
		sub.w	d5,d0
		bcc.s	loc_12FDC
		move.w	#0,d0

loc_12FDC:
		move.w	d0,Obj_Inertia(a0)
		bra.s	loc_12FEE
; ===========================================================================

loc_12FE2:
		add.w	d5,d0
		bcc.s	loc_12FEA
		move.w	#0,d0

loc_12FEA:
		move.w	d0,Obj_Inertia(a0)

loc_12FEE:
		move.b	Obj_Angle(a0),d0
		jsr	(CalcSine).l
		muls.w	Obj_Inertia(a0),d1
		asr.l	#8,d1
		move.w	d1,Obj_XVelocity(a0)
		muls.w	Obj_Inertia(a0),d0
		asr.l	#8,d0
		move.w	d0,Obj_YVelocity(a0)

loc_1300C:
		move.b	Obj_Angle(a0),d0
		addi.b	#$40,d0
		bmi.s	locret_1307C
		move.b	#$40,d1
		tst.w	Obj_Inertia(a0)
		beq.s	locret_1307C
		bmi.s	loc_13024
		neg.w	d1

loc_13024:
		move.b	Obj_Angle(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_1307C
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_13078
		cmpi.b	#$40,d0
		beq.s	loc_13066
		cmpi.b	#$80,d0
		beq.s	loc_13060
		add.w	d1,Obj_XVelocity(a0)
		bset	#5,Obj_Status(a0)
		move.w	#0,Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_13060:
		sub.w	d1,Obj_YVelocity(a0)
		rts	
; ===========================================================================

loc_13066:
		sub.w	d1,Obj_XVelocity(a0)
		bset	#5,Obj_Status(a0)
		move.w	#0,Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_13078:
		add.w	d1,Obj_YVelocity(a0)

locret_1307C:
		rts	
; End of function Sonic_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_MoveLeft:		   ; XREF: Sonic_Move
		move.w	Obj_Inertia(a0),d0
		beq.s	loc_13086
		bpl.s	loc_130B2

loc_13086:
		bset	#0,Obj_Status(a0)
		bne.s	loc_1309A
		bclr	#5,Obj_Status(a0)
		move.b	#1,Obj_AnimRstrt(a0)

loc_1309A:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_130A6
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_130A6
		move.w	d1,d0

loc_130A6:
		move.w	d0,Obj_Inertia(a0)
		move.b	#0,Obj_Animation(a0); use walking animation
		rts
; ===========================================================================

loc_130B2:				; XREF: Sonic_MoveLeft
		sub.w	d4,d0
		bcc.s	loc_130BA
		move.w	#-$80,d0

loc_130BA:
		move.w	d0,Obj_Inertia(a0)
		move.b	Obj_Angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_130E8
		cmpi.w	#$400,d0
		blt.s	locret_130E8
		move.b	#$D,Obj_Animation(a0)	; use "stopping" animation
		bclr	#0,Obj_Status(a0)
		move.w	#$A4,d0
		jsr	(PlaySound_Special).l ;	play stopping sound
        move.b	#6,($FFFFD1E4).w    ; set the spin dash dust routine to skid dust
        move.b	#$15,($FFFFD1DA).w

locret_130E8:
		rts	
; End of function Sonic_MoveLeft


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_MoveRight:	   ; XREF: Sonic_Move
		move.w	Obj_Inertia(a0),d0
		bmi.s	loc_13118
		bclr	#0,Obj_Status(a0)
		beq.s	loc_13104
		bclr	#5,Obj_Status(a0)
		move.b	#1,Obj_AnimRstrt(a0)

loc_13104:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_1310C
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_1310C
		move.w	d6,d0

loc_1310C:
		move.w	d0,Obj_Inertia(a0)
		move.b	#0,Obj_Animation(a0); use walking animation
		rts
; ===========================================================================

loc_13118:				; XREF: Sonic_MoveRight
		add.w	d4,d0
		bcc.s	loc_13120
		move.w	#$80,d0

loc_13120:
		move.w	d0,Obj_Inertia(a0)
		move.b	Obj_Angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_1314E
		cmpi.w	#-$400,d0
		bgt.s	locret_1314E
		move.b	#$D,Obj_Animation(a0)	; use "stopping" animation
		bset	#0,Obj_Status(a0)
		move.w	#$A4,d0
		jsr	(PlaySound_Special).l ;	play stopping sound
        move.b	#6,($FFFFD1E4).w    ; set the spin dash dust routine to skid dust
        move.b	#$15,($FFFFD1DA).w

locret_1314E:
		rts	
; End of function Sonic_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's speed as he rolls
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollSpeed:			; XREF: Obj01_MdRoll
		move.w	($FFFFF760).w,d6
		asl.w	#1,d6
		move.w	($FFFFF762).w,d5
		asr.w	#1,d5
		move.w	($FFFFF764).w,d4
		asr.w	#2,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_131CC
		tst.w	Plyr_CtrlLock(a0)
		bne.s	loc_13188
		btst	#2,($FFFFF602).w ; is left being pressed?
		beq.s	loc_1317C	; if not, branch
		bsr.w	Sonic_RollLeft

loc_1317C:
		btst	#3,($FFFFF602).w ; is right being pressed?
		beq.s	loc_13188	; if not, branch
		bsr.w	Sonic_RollRight

loc_13188:
		move.w	Obj_Inertia(a0),d0
		beq.s	loc_131AA
		bmi.s	loc_1319E
		sub.w	d5,d0
		bcc.s	loc_13198
		move.w	#0,d0

loc_13198:
		move.w	d0,Obj_Inertia(a0)
		bra.s	loc_131AA
; ===========================================================================

loc_1319E:				; XREF: Sonic_RollSpeed
		add.w	d5,d0
		bcc.s	loc_131A6
		move.w	#0,d0

loc_131A6:
		move.w	d0,Obj_Inertia(a0)

loc_131AA:
		tst.w	Obj_Inertia(a0)		; is Sonic moving?
		bne.s	loc_131CC	; if yes, branch
		bclr	#2,Obj_Status(a0)
		move.b	#$13,Obj_YHitbox(a0)
		move.b	#9,Obj_XHitbox(a0)
		move.b	#5,Obj_Animation(a0)	; use "standing" animation
		subq.w	#5,Obj_YPosition(a0)

loc_131CC:
		cmp.w	#$60,($FFFFF73E).w
		beq.s	@cont2
		bcc.s	@cont1
		addq.w	#4,($FFFFF73E).w
		
@cont1:
		subq.w	#2,($FFFFF73E).w
		
@cont2:
		move.b	$26(a0),d0
		jsr	(CalcSine).l
		muls.w	Obj_Inertia(a0),d0
		asr.l	#8,d0
		move.w	d0,Obj_YVelocity(a0)
		muls.w	Obj_Inertia(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_131F0
		move.w	#$1000,d1

loc_131F0:
		cmpi.w	#-$1000,d1
		bge.s	loc_131FA
		move.w	#-$1000,d1

loc_131FA:
		move.w	d1,Obj_XVelocity(a0)
		bra.w	loc_1300C
; End of function Sonic_RollSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollLeft:				; XREF: Sonic_RollSpeed
		move.w	Obj_Inertia(a0),d0
		beq.s	loc_1320A
		bpl.s	loc_13218

loc_1320A:
		bset	#0,Obj_Status(a0)
		move.b	#2,Obj_Animation(a0)	; use "rolling"	animation
		rts	
; ===========================================================================

loc_13218:
		sub.w	d4,d0
		bcc.s	loc_13220
		move.w	#-$80,d0

loc_13220:
		move.w	d0,Obj_Inertia(a0)
		rts	
; End of function Sonic_RollLeft


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollRight:			; XREF: Sonic_RollSpeed
		move.w	Obj_Inertia(a0),d0
		bmi.s	loc_1323A
		bclr	#0,Obj_Status(a0)
		move.b	#2,Obj_Animation(a0)	; use "rolling"	animation
		rts	
; ===========================================================================

loc_1323A:
		add.w	d4,d0
		bcc.s	loc_13242
		move.w	#$80,d0

loc_13242:
		move.w	d0,Obj_Inertia(a0)
		rts	
; End of function Sonic_RollRight

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's direction while jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_ChgJumpDir:		; XREF: Obj01_MdJump; Obj01_MdJump2
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		asl.w	#1,d5
		move.w	Obj_XVelocity(a0),d0	
		btst	#2,($FFFFF602).w; is left being pressed?	
		beq.s	loc_13278; if not, branch	
		bset	#0,Obj_Status(a0)	
		sub.w	d5,d0	
		move.w	d6,d1	
		neg.w	d1	
		cmp.w	d1,d0	
		bgt.s	loc_13278	
		add.w	d5,d0		; +++ remove this frame's acceleration change
		cmp.w	d1,d0		; +++ compare speed with top speed
		ble.s	loc_13278	; +++ if speed was already greater than the maximum, branch	
		move.w	d1,d0

loc_13278:
		btst	#3,($FFFFF602).w; is right being pressed?	
		beq.s	Obj01_JumpMove; if not, branch	
		bclr	#0,Obj_Status(a0)	
		add.w	d5,d0	
		cmp.w	d6,d0	
		blt.s	Obj01_JumpMove
		sub.w	d5,d0		; +++ remove this frame's acceleration change
		cmp.w	d6,d0		; +++ compare speed with top speed
		bge.s	Obj01_JumpMove	; +++ if speed was already greater than the maximum, branch
		move.w	d6,d0

Obj01_JumpMove:
		move.w	d0,Obj_XVelocity(a0)	; change Sonic's horizontal speed

Obj01_ResetScr2:
		cmpi.w	#$60,($FFFFF73E).w ; is	the screen in its default position?
		beq.s	loc_132A4	; if yes, branch
		bcc.s	loc_132A0
		addq.w	#4,($FFFFF73E).w

loc_132A0:
		subq.w	#2,($FFFFF73E).w

loc_132A4:
		cmpi.w	#-$400,Obj_YVelocity(a0)	; is Sonic moving faster than -$400 upwards?
		bcs.s	locret_132D2	; if yes, branch
		move.w	Obj_XVelocity(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_132D2
		bmi.s	loc_132C6
		sub.w	d1,d0
		bcc.s	loc_132C0
		move.w	#0,d0

loc_132C0:
		move.w	d0,Obj_XVelocity(a0)
		rts	
; ===========================================================================

loc_132C6:
		sub.w	d1,d0
		bcs.s	loc_132CE
		move.w	#0,d0

loc_132CE:
		move.w	d0,Obj_XVelocity(a0)

locret_132D2:
		rts	
; End of function Sonic_ChgJumpDir

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	prevent	Sonic leaving the boundaries of	a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_LevelBound:			; XREF: Obj01_MdNormal; et al
		move.l	Obj_XPosition(a0),d1
		move.w	Obj_XVelocity(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	($FFFFF728).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bhi.s	Boundary_Sides	; if yes, branch
		move.w	($FFFFF72A).w,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.s	loc_13332
		addi.w	#$40,d0

loc_13332:
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bls.s	Boundary_Sides	; if yes, branch

loc_13336:
		move.w	($FFFFF72E).w,d0
		addi.w	#$E0,d0
		cmp.w	Obj_YPosition(a0),d0	; has Sonic touched the	bottom boundary?
		blt.s	Boundary_Bottom	; if yes, branch
		rts	
; ===========================================================================

Boundary_Bottom:
		move.w	($FFFFF726).w,d0
		move.w	($FFFFF72E).w,d1
		cmp.w	d0,d1
		blt.s	Boundary_Bottom_locret
		cmpi.w	#$501,($FFFFFE10).w ; is level SBZ2 ?
		bne.w	KillSonic	; if not, kill Sonic
		cmpi.w	#$2000,($FFFFD008).w
		bcs.w	KillSonic
		clr.b	($FFFFFE30).w	; clear	lamppost counter
		move.w	#1,($FFFFFE02).w ; restart the level
		move.w	#$103,($FFFFFE10).w ; set level	to SBZ3	(LZ4)

Boundary_Bottom_locret:
		rts	
; ===========================================================================

Boundary_Sides:
		move.w	d0,Obj_XPosition(a0)
		move.w	#0,Obj_XSubpixel(a0)
		move.w	#0,Obj_XVelocity(a0)	; stop Sonic moving
		move.w	#0,Obj_Inertia(a0)
		bra.s	loc_13336
; End of function Sonic_LevelBound

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to roll when he's moving
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Roll:				; XREF: Obj01_MdNormal
		tst.b	($FFFFF7CA).w
		bne.s	Obj01_NoRoll
		move.w	Obj_Inertia(a0),d0
		bpl.s	loc_13392
		neg.w	d0

loc_13392:
        btst    #1,($FFFFF602).w    ; is down being pressed?
        beq.s    Obj01_NoRoll    ; if not, branch
        move.b    ($FFFFF602).w,d0
        andi.b    #$C,d0    ; is left/right being pressed?
        bne.s    Obj01_NoRoll    ; if yes, branch
        move.w    Obj_Inertia(a0),d0
        bpl.s    @cont ; If ground speed is positive, continue
        neg.w    d0 ; If not, negate it to get the absolute value
 
@cont
        cmpi.w    #$100,d0    ; is Sonic moving at $100 speed or faster?
        bhi.s    Obj01_ChkRoll    ; if yes, branch
        move.b    #8,$1C(a0)    ; use "ducking" animation

Obj01_NoRoll:
		rts	
; ===========================================================================

Obj01_ChkRoll:
		btst	#2,Obj_Status(a0)	; is Sonic already rolling?
		beq.s	Obj01_DoRoll	; if not, branch
		rts	
; ===========================================================================

Obj01_DoRoll:
		bset	#2,Obj_Status(a0)
		move.b	#$E,Obj_YHitbox(a0)
		move.b	#7,Obj_XHitbox(a0)
		move.b	#2,Obj_Animation(a0)	; use "rolling"	animation
		addq.w	#5,Obj_YPosition(a0)
		move.w	#$BE,d0
		jsr	(PlaySound_Special).l ;	play rolling sound
		tst.w	Obj_Inertia(a0)
		bne.s	locret_133E8
		move.w	#$200,Obj_Inertia(a0)

locret_133E8:
		rts	
; End of function Sonic_Roll

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to jump
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Jump:				; XREF: Obj01_MdNormal; Obj01_MdRoll
		move.b	($FFFFF603).w,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		beq.w	locret_1348E	; if not, branch
		moveq	#0,d0
		move.b	Obj_Angle(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_14D48
		cmpi.w	#6,d1
		blt.w	locret_1348E
		move.w	#$680,d2
		btst	#6,Obj_Status(a0)
		beq.s	loc_1341C
		move.w	#$380,d2

loc_1341C:
		moveq	#0,d0
		move.b	Obj_Angle(a0),d0
		subi.b	#$40,d0
		jsr	(CalcSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,Obj_XVelocity(a0)	; make Sonic jump
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,Obj_YVelocity(a0)	; make Sonic jump
		bset	#1,Obj_Status(a0)
		bclr	#5,Obj_Status(a0)
		addq.l	#4,sp
		move.b	#1,Plyr_Jumped(a0)
		clr.b	Plyr_StckToSrfc(a0)
		move.w	#$A0,d0
		jsr	(PlaySound_Special).l ;	play jumping sound
		move.b	#$13,Obj_YHitbox(a0)
		move.b	#9,Obj_XHitbox(a0)
		btst	#2,Obj_Status(a0)
		bne.s	loc_13490
		move.b	#$E,Obj_YHitbox(a0)
		move.b	#7,Obj_XHitbox(a0)
		move.b	#2,Obj_Animation(a0)	; use "jumping"	animation
		bset	#2,Obj_Status(a0)
		addq.w	#5,Obj_YPosition(a0)

locret_1348E:
		rts	
; ===========================================================================

loc_13490:
		bset	#4,Obj_Status(a0)
		rts	
; End of function Sonic_Jump


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_JumpHeight:			; XREF: Obj01_MdJump; Obj01_MdJump2
		tst.b	Plyr_Jumped(a0)
		beq.s	loc_134C4
		move.w	#-$400,d1
		btst	#6,Obj_Status(a0)
		beq.s	loc_134AE
		move.w	#-$200,d1

loc_134AE:
		cmp.w	Obj_YVelocity(a0),d1
		ble.s	locret_134C2
		move.b	($FFFFF602).w,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		bne.s	locret_134C2	; if yes, branch
		move.w	d1,Obj_YVelocity(a0)

locret_134C2:
		rts	
; ===========================================================================

loc_134C4:
		cmpi.w	#-$FC0,Obj_YVelocity(a0)
		bge.s	locret_134D2
		move.w	#-$FC0,Obj_YVelocity(a0)

locret_134D2:
		rts	
; End of function Sonic_JumpHeight

Sonic_SpinDash:
		tst.b	$39(a0)			; already Spin Dashing?
		bne.s	loc2_1AC8E		; if set, branch
		cmpi.b	#8,$1C(a0)		; is anim duck
		bne.s	locret2_1AC8C		; if not, return
		move.b	($FFFFF603).w,d0	; read controller
		andi.b	#$70,d0			; pressing A/B/C ?
		beq.w	locret2_1AC8C		; if not, return
		move.b	#$1F,$1C(a0)		; set Spin Dash anim (9 in s2)
		move.w	#$D1,d0			; spin sound ($E0 in s2)
		jsr	(PlaySound_Special).l	; play spin sound
		addq.l	#4,sp			; increment stack ptr
		move.b	#1,$39(a0)		; set Spin Dash flag
		move.w	#0,$3A(a0)		; set charge count to 0
		cmpi.b	#$C,$28(a0)		; ??? oxygen remaining?
		move.b	#2,($FFFFD1DC).w	; Set the Spin Dash dust animation to $2

loc2_1AC84:
		jsr	Sonic_LevelBound
		jsr	Sonic_AnglePos

locret2_1AC8C:
		rts	
; ---------------------------------------------------------------------------

loc2_1AC8E:
		move.b	#$1F,$1C(a0)
		move.b	($FFFFF602).w,d0	; read controller
		btst	#1,d0			; check down button
		bne.w	loc2_1AD30		; if set, branch
		move.b	#$E,$16(a0)		; $16(a0) is height/2
		move.b	#7,$17(a0)		; $17(a0) is width/2
		move.b	#2,$1C(a0)		; set animation to roll
		addq.w	#5,$C(a0)		; $C(a0) is Y coordinate
		move.b	#0,$39(a0)		; clear Spin Dash flag
		moveq	#0,d0
		move.b	$3A(a0),d0		; copy charge count
		add.w	d0,d0			; double it
		move.w	spdsh_norm(pc,d0.w),Obj_Inertia(a0) ; get normal speed
		tst.b	($FFFFFE19).w		; is sonic super?
		beq.s	loc2_1ACD0		; if no, branch
		move.w	spdsh_super(pc,d0.w),Obj_inertia(a0) ; get super speed

loc2_1ACD0:					; TODO: figure this out
		move.w	Obj_Inertia(a0),d0		; get inertia
		subi.w	#$800,d0		; subtract $800
		add.w	d0,d0			; double it
		andi.w	#$1F00,d0		; mask it against $1F00
		neg.w	d0			; negate it
		addi.w	#$2000,d0		; add $2000
		move.w	d0,($FFFFC904).w	; move to $EED0
		btst	#0,$22(a0)		; is sonic facing right?
		beq.s	loc2_1ACF4		; if not, branch
		neg.w	Obj_Inertia(a0)			; negate inertia

loc2_1ACF4:
		bset	#2,$22(a0)		; set unused (in s1) flag
		move.b	#0,($FFFFD1DC).w	; clear Spin Dash dust animation
		move.w	#$BC,d0			; spin release sound
		jsr	(PlaySound_Special).l	; play it!
		move.b	#8,($FFFFFF5B).w 	; set afterimage counter to 8
		bra.s	loc2_1AD78
; ===========================================================================
spdsh_norm:
		dc.w  $800		; 0
		dc.w  $880		; 1
		dc.w  $900		; 2
		dc.w  $980		; 3
		dc.w  $A00		; 4
		dc.w  $A80		; 5
		dc.w  $B00		; 6
		dc.w  $B80		; 7
		dc.w  $C00		; 8

spdsh_super:
		dc.w  $B00		; 0
		dc.w  $B80		; 1
		dc.w  $C00		; 2
		dc.w  $C80		; 3
		dc.w  $D00		; 4
		dc.w  $D80		; 5
		dc.w  $E00		; 6
		dc.w  $E80		; 7
		dc.w  $F00		; 8
; ===========================================================================

loc2_1AD30:				; If still charging the dash...
		tst.w	$3A(a0)		; check charge count
		beq.s	loc2_1AD48	; if zero, branch
		move.w	$3A(a0),d0	; otherwise put it in d0
		lsr.w	#5,d0		; shift right 5 (divide it by 32)
		sub.w	d0,$3A(a0)	; subtract from charge count
		bcc.s	loc2_1AD48	; ??? branch if carry clear
		move.w	#0,$3A(a0)	; set charge count to 0

loc2_1AD48:
		move.b	($FFFFF603).w,d0	; read controller
		andi.b	#$70,d0			; pressing A/B/C?
		beq.w	loc2_1AD78		; if not, branch
		move.w	#$1F00,$1C(a0)		; reset spdsh animation
		move.w	#$D1,d0			; was $E0 in sonic 2
		move.b	#2,$FFFFD1DC.w	; Set the Spin Dash dust animation to $2.
		jsr	(PlaySound_Special).l	; play charge sound
		addi.w	#$200,$3A(a0)		; increase charge count
		cmpi.w	#$800,$3A(a0)		; check if it's maxed
		bcs.s	loc2_1AD78		; if not, then branch
		move.w	#$800,$3A(a0)		; reset it to max

loc2_1AD78:
		addq.l	#4,sp			; increase stack ptr
		cmpi.w	#$60,($FFFFF73E).w
		beq.s	loc2_1AD8C
		bcc.s	loc2_1AD88
		addq.w	#4,($FFFFF73E).w

loc2_1AD88:
		subq.w	#2,($FFFFF73E).w

loc2_1AD8C:
		jsr	Sonic_LevelBound
		jsr	Sonic_AnglePos
		rts
; End of function Sonic_SpinDash

; ---------------------------------------------------------------------------
; Subroutine to	slow Sonic walking up a	slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_SlopeResist:			; XREF: Obj01_MdNormal
		move.b	Obj_Angle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bcc.s	locret_13508
		move.b	Obj_Angle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$20,d0
		asr.l	#8,d0
		tst.w	Obj_Inertia(a0)
		beq.s	locret_13508
		bmi.s	loc_13504
		tst.w	d0
		beq.s	locret_13502
		add.w	d0,Obj_Inertia(a0)	; change Sonic's inertia

locret_13502:
		rts	
; ===========================================================================

loc_13504:
		add.w	d0,Obj_Inertia(a0)

locret_13508:
		rts	
; End of function Sonic_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope	while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollRepel:			; XREF: Obj01_MdRoll
		move.b	Obj_Angle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#-$40,d0
		bcc.s	locret_13544
		move.b	Obj_Angle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$50,d0
		asr.l	#8,d0
		tst.w	Obj_Inertia(a0)
		bmi.s	loc_1353A
		tst.w	d0
		bpl.s	loc_13534
		asr.l	#2,d0

loc_13534:
		add.w	d0,Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_1353A:
		tst.w	d0
		bmi.s	loc_13540
		asr.l	#2,d0

loc_13540:
		add.w	d0,Obj_Inertia(a0)

locret_13544:
		rts	
; End of function Sonic_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_SlopeRepel:			; XREF: Obj01_MdNormal; Obj01_MdRoll
		tst.b	Plyr_StckToSrfc(a0)
		bne.s	locret_13580
		tst.w	Plyr_CtrlLock(a0)
		bne.s	loc_13582
		move.b	Obj_Angle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	locret_13580
		move.w	Obj_Inertia(a0),d0
		bpl.s	loc_1356A
		neg.w	d0

loc_1356A:
		cmpi.w	#$280,d0
		bcc.s	locret_13580
		clr.w	Obj_Inertia(a0)
		bset	#1,Obj_Status(a0)
		move.w	#$1E,Plyr_CtrlLock(a0)

locret_13580:
		rts	
; ===========================================================================

loc_13582:
		subq.w	#1,Plyr_CtrlLock(a0)
		rts	
; End of function Sonic_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to	return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_JumpAngle:			; XREF: Obj01_MdJump; Obj01_MdJump2
		move.b	Obj_Angle(a0),d0	; get Sonic's angle
		beq.s	locret_135A2	; if already 0,	branch
		bpl.s	loc_13598	; if higher than 0, branch

		addq.b	#2,d0		; increase angle
		bcc.s	loc_13596
		moveq	#0,d0

loc_13596:
		bra.s	loc_1359E
; ===========================================================================

loc_13598:
		subq.b	#2,d0		; decrease angle
		bcc.s	loc_1359E
		moveq	#0,d0

loc_1359E:
		move.b	d0,Obj_Angle(a0)

locret_135A2:
		rts	
; End of function Sonic_JumpAngle

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with	the floor after	jumping/falling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Floor:				; XREF: Obj01_MdJump; Obj01_MdJump2
		move.w	Obj_XVelocity(a0),d1
		move.w	Obj_YVelocity(a0),d2
		jsr	(CalcAngle).l
		move.b	d0,($FFFFFFEC).w
		subi.b	#$20,d0
		move.b	d0,($FFFFFFED).w
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFEE).w
		cmpi.b	#$40,d0
		beq.w	loc_13680
		cmpi.b	#$80,d0
		beq.w	loc_136E2
		cmpi.b	#-$40,d0
		beq.w	loc_1373E
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_135F0
		sub.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)

loc_135F0:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13602
		add.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)

loc_13602:
		bsr.w	Sonic_HitFloor
		move.b	d1,($FFFFFFEF).w
		tst.w	d1
		bpl.s	locret_1367E
		move.b	Obj_YVelocity(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_1361E
		cmp.b	d2,d0
		blt.s	locret_1367E

loc_1361E:
		add.w	d1,Obj_YPosition(a0)
		move.b	d3,Obj_Angle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,Obj_Animation(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_1365C
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.s	loc_1364E
		asr	Obj_YVelocity(a0)
		bra.s	loc_13670
; ===========================================================================

loc_1364E:
		move.w	#0,Obj_YVelocity(a0)
		move.w	Obj_XVelocity(a0),Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_1365C:
		move.w	#0,Obj_XVelocity(a0)
		cmpi.w	#$FC0,Obj_YVelocity(a0)
		ble.s	loc_13670
		move.w	#$FC0,Obj_YVelocity(a0)

loc_13670:
		move.w	Obj_YVelocity(a0),Obj_Inertia(a0)
		tst.b	d3
		bpl.s	locret_1367E
		neg.w	Obj_Inertia(a0)

locret_1367E:
		rts	
; ===========================================================================

loc_13680:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_1369A
		sub.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)
		move.w	Obj_YVelocity(a0),Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_1369A:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_136B4
		sub.w	d1,Obj_YPosition(a0)
		tst.w	Obj_YVelocity(a0)
		bpl.s	locret_136B2
		move.w	#0,Obj_YVelocity(a0)

locret_136B2:
		rts	
; ===========================================================================

loc_136B4:
		tst.w	Obj_YVelocity(a0)
		bmi.s	locret_136E0
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_136E0
		add.w	d1,Obj_YPosition(a0)
		move.b	d3,Obj_Angle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,Obj_Animation(a0)
		move.w	#0,Obj_YVelocity(a0)
		move.w	Obj_XVelocity(a0),Obj_Inertia(a0)

locret_136E0:
		rts	
; ===========================================================================

loc_136E2:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_136F4
		sub.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)

loc_136F4:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13706
		add.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)

loc_13706:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	locret_1373C
		sub.w	d1,Obj_YPosition(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_13726
		move.w	#0,Obj_YVelocity(a0)
		rts	
; ===========================================================================

loc_13726:
		move.b	d3,Obj_Angle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.w	Obj_YVelocity(a0),Obj_Inertia(a0)
		tst.b	d3
		bpl.s	locret_1373C
		neg.w	Obj_Inertia(a0)

locret_1373C:
		rts	
; ===========================================================================

loc_1373E:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13758
		add.w	d1,Obj_XPosition(a0)
		move.w	#0,Obj_XVelocity(a0)
		move.w	Obj_YVelocity(a0),Obj_Inertia(a0)
		rts	
; ===========================================================================

loc_13758:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_13772
		sub.w	d1,Obj_YPosition(a0)
		tst.w	Obj_YVelocity(a0)
		bpl.s	locret_13770
		move.w	#0,Obj_YVelocity(a0)

locret_13770:
		rts	
; ===========================================================================

loc_13772:
		tst.w	Obj_YVelocity(a0)
		bmi.s	locret_1379E
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_1379E
		add.w	d1,Obj_YPosition(a0)
		move.b	d3,Obj_Angle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,Obj_Animation(a0)
		move.w	#0,Obj_YVelocity(a0)
		move.w	Obj_XVelocity(a0),Obj_Inertia(a0)

locret_1379E:
		rts	
; End of function Sonic_Floor

; ---------------------------------------------------------------------------
; Subroutine to	reset Sonic's mode when he lands on the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_ResetOnFloor:			; XREF: PlatformObject; et al
		and.b	#%11001101,Obj_Status(a0)	; Get wrekt Naka, n00b
		btst	#2,Obj_Status(a0)
		beq.s	loc_137E4
		bclr	#2,Obj_Status(a0)
		move.b	#$13,Obj_YHitbox(a0)
		move.b	#9,Obj_XHitbox(a0)
		move.b	#0,Obj_Animation(a0)	; use running/walking animation
		subq.w	#5,Obj_YPosition(a0)

loc_137E4:
		move.b	#0,Plyr_Jumped(a0)
		move.w	#0,($FFFFF7D0).w
		rts	
; End of function Sonic_ResetOnFloor

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when he	gets hurt
; ---------------------------------------------------------------------------

Obj01_Hurt:				; XREF: Obj01_Index
		jsr	SpeedToPos
		addi.w	#$30,$12(a0)
		btst	#6,$22(a0)
		beq.s	loc_1380C
		subi.w	#$20,$12(a0)

loc_1380C:
		bsr.w	Sonic_HurtStop
		bsr.w	Sonic_LevelBound
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Water
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic falling after he's been hurt
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HurtStop:				; XREF: Obj01_Hurt
		move.w	($FFFFF72E).w,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0
		bcs.w	KillSonic
		bsr.w	Sonic_Floor
		btst	#1,$22(a0)
		bne.s	locret_13860
		moveq	#0,d0
		move.w	d0,$12(a0)
		move.w	d0,$10(a0)
		move.w	d0,Obj_Inertia(a0)
		move.b	#0,$1C(a0)
		subq.b	#2,$24(a0)
		move.w	#$78,$30(a0)

locret_13860:
		rts	
; End of function Sonic_HurtStop

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when he	dies
; ---------------------------------------------------------------------------

Obj01_Death:				; XREF: Obj01_Index
		bsr.w	GameOver
		jsr	ObjectFall
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	DisplaySprite

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


GameOver:				; XREF: Obj01_Death
		move.w	($FFFFF704).w,d0
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bge.w	locret_13900
		move.w	#-$38,$12(a0)
		addq.b	#2,$24(a0)
		clr.b	($FFFFFE1E).w	; stop time counter
		addq.b	#1,($FFFFFE1C).w ; update lives	counter
		subq.b	#1,($FFFFFE12).w ; subtract 1 from number of lives
		bne.s	loc_138D4
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load GAME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#1,($FFFFD0DA).w ; set OVER object to correct frame
		clr.b	($FFFFFE1A).w

loc_138C2:
		move.w	#$8F,d0
		jsr	(PlaySound).l	; play game over music
		moveq	#PLCID_GameOver,d0
		jmp	(LoadPLC).l	; load game over patterns
; ===========================================================================

loc_138D4:
		move.w	#60,$3A(a0)	; set time delay to 1 second
		tst.b	($FFFFFE1A).w	; is TIME OVER tag set?
		beq.s	locret_13900	; if not, branch
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load TIME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#2,($FFFFD09A).w
		move.b	#3,($FFFFD0DA).w
		bra.s	loc_138C2
; ===========================================================================

locret_13900:
		rts	
; End of function GameOver

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when the level is restarted
; ---------------------------------------------------------------------------

Obj01_ResetLevel:			; XREF: Obj01_Index
		tst.w	$3A(a0)
		beq.s	locret_13914
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.s	locret_13914
		move.w	#1,($FFFFFE02).w ; restart the level

locret_13914:
		rts

; ---------------------------------------------------------------------------
; Sonic when he's drowning
; ---------------------------------------------------------------------------
 
; ||||||||||||||| S	U B	R O	U T	I N	E |||||||||||||||||||||||||||||||||||||||
 
 
Sonic_Drowned:
		bsr.w   SpeedToPos		; Make Sonic able to move
		addi.w  #$10,$12(a0)	; Apply gravity
		bsr.w   Sonic_RecordPos	; Record position
		bsr.s   Sonic_Animate	; Animate Sonic
		bsr.w   LoadSonicDynPLC	; Load Sonic's DPLCs
		bra.w   DisplaySprite	; And finally, display Sonic

; ---------------------------------------------------------------------------
; Subroutine to	animate	Sonic's sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Animate:				; XREF: Obj01_Control; et al
		lea	(SonicAniData).l,a1
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.s	SAnim_Do	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

SAnim_Do:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),d0
		bmi.s	SAnim_WalkRun	; if animation is walk/run/roll/jump, branch
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	SAnim_Delay	; if time remains, branch
		move.b	d0,$1E(a0)	; load frame duration

SAnim_Do2:
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		cmp.b	#$FD,d0					; MJ: is it a flag from FD to FF?
		bhs	SAnim_End_FF				; MJ: if so, branch to flag routines

SAnim_Next:
		move.b	d0,$1A(a0)	; load sprite number
		addq.b	#1,$1B(a0)	; next frame number

SAnim_Delay:
		rts	
; ===========================================================================

SAnim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.s	SAnim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	SAnim_Next
; ===========================================================================

SAnim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.s	SAnim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	SAnim_Next
; ===========================================================================

SAnim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.s	SAnim_End	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

SAnim_End:
		rts	
; ===========================================================================

SAnim_WalkRun:				; XREF: SAnim_Do
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	SAnim_Delay	; if time remains, branch
		addq.b	#1,d0		; is animation walking/running?
		bne.w	SAnim_RollJump	; if not, branch
		moveq	#0,d1
		move.b	$26(a0),d0	; get Sonic's angle
		move.b	$22(a0),d2
		andi.b	#1,d2		; is Sonic mirrored horizontally?
		bne.s	loc_13A70	; if yes, branch
		not.b	d0		; reverse angle

loc_13A70:
		addi.b	#$10,d0		; add $10 to angle
		bpl.s	loc_13A78	; if angle is $0-$7F, branch
		moveq	#3,d1

loc_13A78:
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		btst	#5,$22(a0)
		bne.w	SAnim_Push
		lsr.b	#4,d0		; divide angle by $10
		andi.b	#6,d0		; angle	must be	0, 2, 4	or 6
		move.w	Obj_Inertia(a0),d2	; get Sonic's speed
		bpl.s	loc_13A9C
		neg.w	d2

loc_13A9C:
		lea	(SonAni_Run).l,a1 ; use	running	animation
		cmpi.w	#$600,d2	; is Sonic at running speed?
		bcc.s	loc_13AB4	; if yes, branch
		lea	(SonAni_Walk).l,a1 ; use walking animation
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0

loc_13AB4:
		add.b	d0,d0
		move.b	d0,d3
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_13AC2
		moveq	#0,d2

loc_13AC2:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		bsr.w	SAnim_Do2
		add.b	d3,$1A(a0)	; modify frame number
		rts	
; ===========================================================================

SAnim_RollJump:				; XREF: SAnim_WalkRun
		addq.b	#1,d0		; is animation rolling/jumping?
		bne.s	SAnim_Push	; if not, branch
		move.w	Obj_Inertia(a0),d2	; get Sonic's speed
		bpl.s	loc_13ADE
		neg.w	d2

loc_13ADE:
		lea	(SonAni_Roll2).l,a1 ; use fast animation
		cmpi.w	#$600,d2	; is Sonic moving fast?
		bcc.s	loc_13AF0	; if yes, branch
		lea	(SonAni_Roll).l,a1 ; use slower	animation

loc_13AF0:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_13AFA
		moveq	#0,d2

loc_13AFA:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; ===========================================================================

SAnim_Push:				; XREF: SAnim_RollJump
		move.w	Obj_Inertia(a0),d2	; get Sonic's speed
		bmi.s	loc_13B1E
		neg.w	d2

loc_13B1E:
		addi.w	#$800,d2
		bpl.s	loc_13B26
		moveq	#0,d2

loc_13B26:
		lsr.w	#6,d2
		move.b	d2,$1E(a0)	; modify frame duration
		lea	(SonAni_Push).l,a1
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; End of function Sonic_Animate

; ===========================================================================
SonicAniData:
	include "_anim\Sonic.asm"

; ---------------------------------------------------------------------------
; Sonic	pattern	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadSonicDynPLC:			; XREF: Obj01_Control; et al
		moveq	#0,d0
		move.b	$1A(a0),d0	; load frame number
		cmp.b	($FFFFF766).w,d0
		beq.s	locret_13C96
		move.b	d0,($FFFFF766).w
		lea	(SonicDynPLC).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		moveq	#0,d5
		move.b	(a2)+,d5
		subq.w	#1,d5
		bmi.s	locret_13C96
		move.w	#$F000,d4
		move.l	#Art_Sonic,d6

SPLC_ReadEntry:
		moveq	#0,d1
		move.b	(a2)+,d1
		lsl.w	#8,d1
		move.b	(a2)+,d1
		move.w	d1,d3
		lsr.w	#8,d3
		andi.w	#$F0,d3
		addi.w	#$10,d3
		andi.w	#$FFF,d1
		lsl.l	#5,d1
		add.l	d6,d1
		move.w	d4,d2
		add.w	d3,d4
		add.w	d3,d4
		jsr	(QueueDMATransfer).l
		dbf	d5,SPLC_ReadEntry	; repeat for number of entries

locret_13C96:
		rts	
; End of function LoadSonicDynPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0A - drowning countdown numbers and small bubbles (LZ)
; ---------------------------------------------------------------------------

Obj0A:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0A_Index(pc,d0.w),d1
		jmp	Obj0A_Index(pc,d1.w)
; ===========================================================================
Obj0A_Index:	dc.w Obj0A_Main-Obj0A_Index, Obj0A_Animate-Obj0A_Index
		dc.w Obj0A_ChkWater-Obj0A_Index, Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete2-Obj0A_Index,	Obj0A_Countdown-Obj0A_Index
		dc.w Obj0A_AirLeft-Obj0A_Index,	Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete2-Obj0A_Index
; ===========================================================================

Obj0A_Main:				; XREF: Obj0A_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj64,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	$28(a0),d0
		bpl.s	loc_13D00
		addq.b	#8,$24(a0)
		move.l	#Map_obj0A,4(a0)
		move.w	#$440,2(a0)
		andi.w	#$7F,d0
		move.b	d0,$33(a0)
		bra.w	Obj0A_Countdown
; ===========================================================================

loc_13D00:
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)

Obj0A_Animate:				; XREF: Obj0A_Index
		lea	(Ani_obj0A).l,a1
		jsr	AnimateSprite

Obj0A_ChkWater:				; XREF: Obj0A_Index
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; has bubble reached the water surface?
		bcs.s	Obj0A_Wobble	; if not, branch
		move.b	#6,$24(a0)
		addq.b	#7,$1C(a0)
		cmpi.b	#$D,$1C(a0)
        bcs.s	Obj0A_Display ; that would be "bcs.s    Drown_Display" for Git/Hive2021 users
        move.b	#$D,$1C(a0)      ; change $1C to obAnim if you using the disassembly I mentioned above
		bra.s	Obj0A_Display
; ===========================================================================

Obj0A_Wobble:
		tst.b	($FFFFF7C7).w
		beq.s	loc_13D44
		addq.w	#4,$30(a0)

loc_13D44:
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		bsr.s	Obj0A_ShowNumber
		jsr	SpeedToPos
		tst.b	1(a0)
		bpl.s	Obj0A_Delete
		jmp	DisplaySprite
; ===========================================================================

Obj0A_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj0A_Display:				; XREF: Obj0A_Index
		bsr.s	Obj0A_ShowNumber
		lea	(Ani_obj0A).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ===========================================================================

Obj0A_Delete2:				; XREF: Obj0A_Index
		jmp	DeleteObject
; ===========================================================================

Obj0A_AirLeft:				; XREF: Obj0A_Index
		cmpi.w	#$C,($FFFFFE14).w ; check air remaining
		bhi.s	Obj0A_Delete3	; if higher than $C, branch
		subq.w	#1,$38(a0)
		bne.s	Obj0A_Display2
		move.b	#$E,$24(a0)
		addq.b	#7,$1C(a0)
		bra.s	Obj0A_Display
; ===========================================================================

Obj0A_Display2:
		lea	(Ani_obj0A).l,a1
		jsr	AnimateSprite
		tst.b	1(a0)
		bpl.s	Obj0A_Delete3
		jmp	DisplaySprite
; ===========================================================================

Obj0A_Delete3:
		jmp	DeleteObject
; ===========================================================================

Obj0A_ShowNumber:			; XREF: Obj0A_Wobble; Obj0A_Display
		tst.w	$38(a0)
		beq.s	locret_13E1A
		subq.w	#1,$38(a0)
		bne.s	locret_13E1A
		cmpi.b	#7,$1C(a0)
		bcc.s	locret_13E1A
		move.w	#$F,$38(a0)
		clr.w	$12(a0)
		move.b	#$80,1(a0)
		move.w	8(a0),d0
		sub.w	($FFFFF700).w,d0
		addi.w	#$80,d0
		move.w	d0,8(a0)
		move.w	$C(a0),d0
		sub.w	($FFFFF704).w,d0
		addi.w	#$80,d0
		move.w	d0,$A(a0)
		move.b	#$C,$24(a0)

locret_13E1A:
		rts	
; ===========================================================================
Obj0A_WobbleData:
		dc.b 0, 0, 0, 0, 0, 0,	1, 1, 1, 1, 1, 2, 2, 2,	2, 2, 2
		dc.b 2,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 3, 3, 4, 3
		dc.b 3,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 2, 2, 2, 2
		dc.b 2,	2, 2, 1, 1, 1, 1, 1, 0,	0, 0, 0, 0, 0, -1, -1
		dc.b -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -3, -2
		dc.b -2, -2, -2, -2, -1, -1, -1, -1, -1
; ===========================================================================

Obj0A_Countdown:			; XREF: Obj0A_Index
		tst.w	$2C(a0)
		bne.w	loc_13F86
		cmpi.b	#6,($FFFFD024).w
		bcc.w	locret_1408C
		btst	#6,($FFFFD022).w
		beq.w	locret_1408C
		subq.w	#1,$38(a0)
		bpl.w	loc_13FAC
		move.w	#59,$38(a0)
		move.w	#1,$36(a0)
		jsr	(RandomNumber).l
		andi.w	#1,d0
		move.b	d0,$34(a0)
		move.w	($FFFFFE14).w,d0 ; check air remaining
		cmpi.w	#$19,d0
		beq.s	Obj0A_WarnSound	; play sound if	air is $19
		cmpi.w	#$14,d0
		beq.s	Obj0A_WarnSound
		cmpi.w	#$F,d0
		beq.s	Obj0A_WarnSound
		cmpi.w	#$C,d0
		bhi.s	Obj0A_ReduceAir	; if air is above $C, branch
		bne.s	loc_13F02
		move.w	#$92,d0
		jsr	(PlaySound).l	; play countdown music

loc_13F02:
		subq.b	#1,$32(a0)
		bpl.s	Obj0A_ReduceAir
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
		bra.s	Obj0A_ReduceAir
; ===========================================================================

Obj0A_WarnSound:			; XREF: Obj0A_Countdown
		move.w	#$C2,d0
		jsr	(PlaySound_Special).l ;	play "ding-ding" warning sound

Obj0A_ReduceAir:
		subq.w	#1,($FFFFFE14).w ; subtract 1 from air remaining
		bcc.w	Obj0A_GoMakeItem ; if air is above 0, branch
		bsr.w	ResumeMusic
		move.b	#$81,($FFFFF7C8).w ; lock controls
		move.w	#$B2,d0
		jsr	(PlaySound_Special).l ;	play drowning sound
		move.b	#$A,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$78,$2C(a0)
		move.l	a0,-(sp)
		lea	($FFFFD000).w,a0
		bsr.w	Sonic_ResetOnFloor
		move.b	#$17,$1C(a0)	; use Sonic's drowning animation
		bset	#1,$22(a0)
		bset	#7,2(a0)
		move.w	#0,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,Obj_Inertia(a0)
		move.b	#$A,$24(a0)		; Force the character to drown
		move.b	#1,($FFFFF744).w
		move.b	#0,($FFFFFE1E).w	; Stop the timer immediately
		movea.l	(sp)+,a0
		rts
; ===========================================================================

loc_13F86:
		subq.w	#1,$2C(a0)
		bne.s	loc_13FAC	; Make it jump straight to this location
		move.b	#6,($FFFFD000+$24).w
		rts
; ===========================================================================

Obj0A_GoMakeItem:			; XREF: Obj0A_ReduceAir
		bra.s	Obj0A_MakeItem
; ===========================================================================

loc_13FAC:
		tst.w	$36(a0)
		beq.w	locret_1408C
		subq.w	#1,$3A(a0)
		bpl.w	locret_1408C

Obj0A_MakeItem:
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		move.w	d0,$3A(a0)
		jsr	SingleObjLoad
		bne.w	locret_1408C
		move.b	#$A,0(a1)	; load object
		move.w	($FFFFD008).w,8(a1) ; match X position to Sonic
		moveq	#6,d0
		btst	#0,($FFFFD022).w
		beq.s	loc_13FF2
		neg.w	d0
		move.b	#$40,$26(a1)

loc_13FF2:
		add.w	d0,8(a1)
		move.w	($FFFFD00C).w,$C(a1)
		move.b	#6,$28(a1)
		tst.w	$2C(a0)
		beq.w	loc_1403E
		andi.w	#7,$3A(a0)
		addi.w	#0,$3A(a0)
		move.w	($FFFFD00C).w,d0
		subi.w	#$C,d0
		move.w	d0,$C(a1)
		jsr	(RandomNumber).l
		move.b	d0,$26(a1)
		move.w	($FFFFFE04).w,d0
		andi.b	#3,d0
		bne.s	loc_14082
		move.b	#$E,$28(a1)
		bra.s	loc_14082
; ===========================================================================

loc_1403E:
		btst	#7,$36(a0)
		beq.s	loc_14082
		move.w	($FFFFFE14).w,d2
		lsr.w	#1,d2
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	loc_1406A
		bset	#6,$36(a0)
		bne.s	loc_14082
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_1406A:
		tst.b	$34(a0)
		bne.s	loc_14082
		bset	#6,$36(a0)
		bne.s	loc_14082
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_14082:
		subq.b	#1,$34(a0)
		bpl.s	locret_1408C
		clr.w	$36(a0)

locret_1408C:
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	play music for LZ/SBZ3 after a countdown
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ResumeMusic:				; XREF: Obj64_Wobble; Sonic_Water; Obj0A_ReduceAir
		cmpi.w	#$C,($FFFFFE14).w
		bhi.s	loc_140AC
		move.w	#$82,d0		; play LZ music
		cmpi.w	#$103,($FFFFFE10).w ; check if level is	0103 (SBZ3)
		bne.s	loc_140A6
		move.w	#$86,d0		; play SBZ music

loc_140A6:
		jsr	(PlaySound).l

loc_140AC:
		move.w	#$1E,($FFFFFE14).w
		clr.b	($FFFFD372).w
		rts	
; End of function ResumeMusic

; ===========================================================================
Ani_obj0A:
	include "_anim\obj0A.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - drowning countdown numbers (LZ)
; ---------------------------------------------------------------------------
Map_obj0A:
	include "_maps\obj0A.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 38 - shield and invincibility stars
; ---------------------------------------------------------------------------

Obj38:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj38_Index(pc,d0.w),d1
		jmp	Obj38_Index(pc,d1.w)
; ===========================================================================
Obj38_Index:	dc.w Obj38_Main-Obj38_Index
		dc.w Obj38_Shield-Obj38_Index
		dc.w Obj38_Stars-Obj38_Index
; ===========================================================================

Obj38_Main:				; XREF: Obj38_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj38,4(a0)
		move.b	#4,1(a0)
		move.w	#$80,Obj_Priority(a0)
		move.b	#$10,Obj_SprWidth(a0)
		tst.b	$1C(a0)		; is object a shield?
		bne.s	Obj38_DoStars	; if not, branch
		move.w	#$541,2(a0)	; shield specific code
		rts	
; ===========================================================================

Obj38_DoStars:
		addq.b	#2,$24(a0)	; stars	specific code
		move.w	#$55C,2(a0)
		rts	
; ===========================================================================

Obj38_Shield:				; XREF: Obj38_Index
		tst.b	($FFFFFE2D).w	; does Sonic have invincibility?
		bne.s	Obj38_RmvShield	; if yes, branch
		tst.b	($FFFFFE2C).w	; does Sonic have shield?
		beq.s	Obj38_Delete	; if not, branch
		move.w	($FFFFD008).w,8(a0)
		move.w	($FFFFD00C).w,$C(a0)
		move.b	($FFFFD022).w,$22(a0)
		lea	(Ani_obj38).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ===========================================================================

Obj38_RmvShield:
		rts	
; ===========================================================================

Obj38_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj38_Stars:				; XREF: Obj38_Index
		tst.b	($FFFFFE2D).w	; does Sonic have invincibility?
		beq.s	Obj38_Delete2	; if not, branch
		move.w	($FFFFF7A8).w,d0
		move.b	$1C(a0),d1
		subq.b	#1,d1
		bra.s	Obj38_StarTrail
; ===========================================================================
		lsl.b	#4,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		andi.b	#$F,d1
		move.b	d1,$30(a0)
		bra.s	Obj38_StarTrail2a
; ===========================================================================

Obj38_StarTrail:			; XREF: Obj38_Stars
		lsl.b	#3,d1
		move.b	d1,d2
		add.b	d1,d1
		add.b	d2,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		cmpi.b	#$18,d1
		bcs.s	Obj38_StarTrail2
		moveq	#0,d1

Obj38_StarTrail2:
		move.b	d1,$30(a0)

Obj38_StarTrail2a:
		lea	($FFFFCB00).w,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,8(a0)
		move.w	(a1)+,$C(a0)
		move.b	($FFFFD022).w,$22(a0)
		lea	(Ani_obj38).l,a1
		jsr	AnimateSprite
		jmp	DisplaySprite
; ===========================================================================

Obj38_Delete2:				; XREF: Obj38_Stars
		jmp	DeleteObject
; ===========================================================================

Ani_obj38:
	include "_anim\obj38.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - shield and invincibility stars
; ---------------------------------------------------------------------------
Map_obj38:
	include "_maps\obj38.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle & position as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

Sonic_AnglePos:				; XREF: Obj01_MdNormal; Obj01_MdRoll
		move.l	($FFFFFFD0).w,($FFFFF796).w		; MJ: load first collision data location
		tst.b	($FFFFFFF7).w				; MJ: is second sollision set to be used?
		beq.s	SAP_First				; MJ: if not, branch
		move.l	($FFFFFFD4).w,($FFFFF796).w		; MJ: load second collision data location

SAP_First:
		btst	#3,$22(a0)
		beq.s	loc_14602
		moveq	#0,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		rts	
; ===========================================================================

loc_14602:
		moveq	#3,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		move.b	$26(a0),d0
		addi.b	#$20,d0
		bpl.s	loc_14624
		move.b	$26(a0),d0
		bpl.s	loc_1461E
		subq.b	#1,d0

loc_1461E:
		addi.b	#$20,d0
		bra.s	loc_14630
; ===========================================================================

loc_14624:
		move.b	$26(a0),d0
		bpl.s	loc_1462C
		addq.b	#1,d0

loc_1462C:
		addi.b	#$1F,d0

loc_14630:
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	Sonic_WalkVertL
		cmpi.b	#$80,d0
		beq.w	Sonic_WalkCeiling
		cmpi.b	#$C0,d0
		beq.w	Sonic_WalkVertR
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_146BE
		bpl.s	loc_146C0
		cmpi.w	#-$E,d1
		blt.s	locret_146E6
		add.w	d1,$C(a0)

locret_146BE:
		rts	
; ===========================================================================

loc_146C0:
		cmpi.w	#$E,d1
		bgt.s	loc_146CC

loc_146C6:
		add.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_146CC:
		tst.b	$38(a0)
		bne.s	loc_146C6
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; ===========================================================================

locret_146E6:
		rts	
; End of function Sonic_AnglePos

; ===========================================================================
		move.l	8(a0),d2
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.l	d2,8(a0)
		move.w	#$38,d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts	
; ===========================================================================

locret_1470A:
		rts	
; ===========================================================================
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		subi.w	#$38,d0
		move.w	d0,$12(a0)
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts	
		rts	
; ===========================================================================
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Angle:				; XREF: Sonic_AnglePos; et al
		move.b	($FFFFF76A).w,d2
		cmp.w	d0,d1
		ble.s	loc_1475E
		move.b	($FFFFF768).w,d2
		move.w	d0,d1

loc_1475E:
		btst	#0,d2
		bne.s	loc_1476A
		move.b	d2,$26(a0)
		rts	
; ===========================================================================

loc_1476A:
		move.b	$26(a0),d2
		addi.b	#$20,d2
		andi.b	#$C0,d2
		move.b	d2,$26(a0)
		rts	
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertR:			; XREF: Sonic_AnglePos
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_147F0
		bpl.s	loc_147F2
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		add.w	d1,8(a0)

locret_147F0:
		rts	
; ===========================================================================

loc_147F2:
		cmpi.w	#$E,d1
		bgt.s	loc_147FE

loc_147F8:
		add.w	d1,8(a0)
		rts	
; ===========================================================================

loc_147FE:
		tst.b	$38(a0)
		bne.s	loc_147F8
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertR

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk upside-down
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkCeiling:			; XREF: Sonic_AnglePos
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14892
		bpl.s	loc_14894
		cmpi.w	#-$E,d1
		blt.w	locret_146E6
		sub.w	d1,$C(a0)

locret_14892:
		rts	
; ===========================================================================

loc_14894:
		cmpi.w	#$E,d1
		bgt.s	loc_148A0

loc_1489A:
		sub.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_148A0:
		tst.b	$38(a0)
		bne.s	loc_1489A
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkCeiling

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertL:
		move.w	$C(a0),d2				; MJ: Load Y position
		move.w	8(a0),d3				; MJ: Load X position
		moveq	#0,d0					; MJ: clear d0
		move.b	$17(a0),d0				; MJ: load height
		ext.w	d0					; MJ: set left byte pos or neg
		sub.w	d0,d2					; MJ: subtract from Y position
		move.b	$16(a0),d0				; MJ: load width
		ext.w	d0					; MJ: set left byte pos or neg
		sub.w	d0,d3					; MJ: subtract from X position
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4			; MJ: load address of the angle value set
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14934
		bpl.s	loc_14936
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		sub.w	d1,8(a0)

locret_14934:
		rts

; ===========================================================================

loc_14936:
		cmpi.w	#$E,d1
		bgt.s	loc_14942

loc_1493C:
		sub.w	d1,8(a0)
		rts	

; ===========================================================================

loc_14942:
		tst.b	$38(a0)
		bne.s	loc_1493C
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertL

; ---------------------------------------------------------------------------
; Subroutine to	find which tile	the object is standing on
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

Floor_ChkTile:				; XREF: FindFloor; et al
		move.w	d2,d0					; MJ: load Y position
		andi.w	#$0780,d0				; MJ: get within 780 (E00 pixels) in multiples of 80
		add.w	d0,d0					; MJ: multiply by 2
		move.w	d3,d1					; MJ: load X position
		lsr.w	#7,d1					; MJ: shift to right side
		andi.w	#$007F,d1				; MJ: get within 7F
		add.w	d1,d0					; MJ: add calc'd Y to calc'd X
		moveq	#-1,d1					; MJ: prepare FFFF in d3
		movea.l	($FFFFA400).w,a1			; MJ: load address of Layout to a1
		move.b	(a1,d0.w),d1				; MJ: collect correct chunk ID based on the X and Y position
		andi.w	#$FF,d1					; MJ: keep within FF
		lsl.w	#$07,d1					; MJ: multiply by 80
		move.w	d2,d0					; MJ: load Y position
		andi.w	#$0070,d0				; MJ: keep Y within 80 pixels
		add.w	d0,d1					; MJ: add to ror'd chunk ID
		move.w	d3,d0					; MJ: load X position
		lsr.w	#3,d0					; MJ: divide by 8
		andi.w	#$000E,d0				; MJ: keep X within 10 pixels
		add.w	d0,d1					; MJ: add to ror'd chunk ID

loc_14996:
		movea.l	d1,a1					; MJ: set address (Chunk to read)
		rts						; MJ: return
; ===========================================================================

loc_1499A:
		andi.w	#$7F,d1
		btst	#6,1(a0)
		beq.s	loc_149B2
		addq.w	#1,d1
		cmpi.w	#$29,d1
		bne.s	loc_149B2
		move.w	#$51,d1

loc_149B2:
		ror.w	#7,d1
		ror.w	#2,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$070,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$0E,d0
		add.w	d0,d1
		movea.l	d1,a1
		rts
; End of function Floor_ChkTile


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColisionChkLayer:
		tst.b	($FFFFFFF7).w				; MJ: is collision set to first?
		beq.s	CCL_NoChange				; MJ: if so, branch
		move.w	d0,d4					; MJ: load block ID to d4
		and.w	#$0FFF,d0				; MJ: clear solid settings of d0
		and.w	#$C000,d4				; MJ: get only second solid settings of d4
		lsr.w	#$02,d4					; MJ: shift them to first solid settings location
		add.w	d4,d0					; MJ: add to rest of block ID

CCL_NoChange:
		rts						; MJ: return


FindFloor:
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.s	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_149DE
		btst	d5,d4
		bne.s	loc_149EC

loc_149DE:
		add.w	a3,d2
		bsr.w	FindFloor2
		sub.w	a3,d2
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_149EC:
		movea.l	($FFFFF796).w,a2			; MJ: load collision index address
		move.b	(a2,d0.w),d0				; MJ: load correct Collision ID based on the Block ID
		andi.w	#$FF,d0					; MJ: clear the left byte
		beq.s	loc_149DE				; MJ: if collision ID is 00, branch
		lea	(AngleMap).l,a2				; MJ: load angle map data to a2
		move.b	(a2,d0.w),(a4)				; MJ: collect correct angle based on the collision ID
		lsl.w	#4,d0					; MJ: multiply collision ID by 10
		move.w	d3,d1					; MJ: load X position
		btst	#$A,d4					; MJ: is the block mirrored?
		beq.s	loc_14A12				; MJ: if not, branch
		not.w	d1					; MJ: reverse bits of the X position
		neg.b	(a4)					; MJ: reverse the angle ID

loc_14A12:
		btst	#$B,d4					; MJ: is the block flipped?
		beq.s	loc_14A22				; MJ: if not, branch
		addi.b	#$40,(a4)				; MJ: increase angle ID by 40..
		neg.b	(a4)					; MJ: ..reverse the angle ID..
		subi.b	#$40,(a4)				; MJ: ..and subtract 40 again 

loc_14A22:
		andi.w	#$F,d1					; MJ: get only within 10 (d1 is pixel based on the collision block)
		add.w	d0,d1					; MJ: add collision ID (x10) (d0 is the collision block being read)
		lea	(CollArray1).l,a2			; MJ: load collision array
		move.b	(a2,d1.w),d0				; MJ: load solid value
		ext.w	d0					; MJ: clear left byte
		eor.w	d6,d4					; MJ: set ceiling/wall bits
		btst	#$B,d4					; MJ: is sonic walking on the left wall?
		beq.s	loc_14A3E				; MJ: if not, branch
		neg.w	d0					; MJ: reverse solid value

loc_14A3E:
		tst.w	d0					; MJ: is the solid data null?
		beq.s	loc_149DE				; MJ: if so, branch
		bmi.s	loc_14A5A				; MJ: if it's negative, branch
		cmpi.b	#$10,d0					; MJ: is it 10?
		beq.s	loc_14A66				; MJ: if so, branch
		move.w	d2,d1					; MJ: load Y position
		andi.w	#$F,d1					; MJ: get only within 10 pixels
		add.w	d1,d0					; MJ: add to solid value
		move.w	#$F,d1					; MJ: set F
		sub.w	d0,d1					; MJ: minus solid value from F
		rts			; d1 = position?	; MJ: return

; ===========================================================================

loc_14A5A:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_149DE

loc_14A66:
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts	
; End of function FindFloor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindFloor2:				; XREF: FindFloor
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_14A86
		btst	d5,d4
		bne.s	loc_14A94

loc_14A86:
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14A94:
		movea.l	($FFFFF796).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14A86
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14ABA
		not.w	d1
		neg.b	(a4)

loc_14ABA:
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14ACA
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14ACA:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14AE6
		neg.w	d0

loc_14AE6:
		tst.w	d0
		beq.s	loc_14A86
		bmi.s	loc_14AFC
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14AFC:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14A86
		not.w	d1
		rts	
; End of function FindFloor2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall:
		bsr.w	Floor_ChkTile				; MJ: get chunk/block location
		move.w	(a1),d0					; MJ: load block ID from chunk
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4					; MJ: copy to d4
		andi.w	#$3FF,d0				; MJ: clear flip/mirror/etc data
		beq.s	loc_14B1E				; MJ: if it was null, branch
		btst	d5,d4					; MJ: check solid set (C top solid | D Left/right solid)
		bne.s	loc_14B2C				; MJ: if the specific solid is set, branch

loc_14B1E:
		add.w	a3,d3					; MJ: add 10 to X position
		bsr.w	FindWall2
		sub.w	a3,d3					; MJ: minus 10 from X position
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_14B2C:
		movea.l	($FFFFF796).w,a2			; MJ: load address of collision for level
		move.b	(a2,d0.w),d0				; MJ: load correct colision ID based on the block ID
		andi.w	#$FF,d0					; MJ: keep within FF
		beq.s	loc_14B1E				; MJ: if it's null, branch
		lea	(AngleMap).l,a2				; MJ: load angle map data to a2
		move.b	(a2,d0.w),(a4)				; MJ: load angle set location based on collision ID
		lsl.w	#4,d0					; MJ: multiply by 10
		move.w	d2,d1					; MJ: load Y position
		btst	#$B,d4					; MJ: is the block ID flipped?
		beq.s	loc_14B5A				; MJ: if not, branch
		not.w	d1
		addi.b	#$40,(a4)				; MJ: increase angle set by 40
		neg.b	(a4)					; MJ: negate to opposite
		subi.b	#$40,(a4)				; MJ: decrease angle set by 40

loc_14B5A:
		btst	#$A,d4					; MJ: is the block ID mirrored?
		beq.s	loc_14B62				; MJ: if not, branch
		neg.b	(a4)					; MJ: negate to opposite

loc_14B62:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14B7E
		neg.w	d0

loc_14B7E:
		tst.w	d0
		beq.s	loc_14B1E
		bmi.s	loc_14B9A
		cmpi.b	#$10,d0
		beq.s	loc_14BA6
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14B9A:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14B1E

loc_14BA6:
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts	
; End of function FindWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall2:				; XREF: FindWall
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_14BC6
		btst	d5,d4
		bne.s	loc_14BD4

loc_14BC6:
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14BD4:
		movea.l	($FFFFF796).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14BC6
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14C02
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14C02:
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14C0A
		neg.b	(a4)

loc_14C0A:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14C26
		neg.w	d0

loc_14C26:
		tst.w	d0
		beq.s	loc_14BC6
		bmi.s	loc_14C3C
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14C3C:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14BC6
		not.w	d1
		rts	
; End of function FindWall2

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkSpeed:			; XREF: Sonic_Move
		move.l	8(a0),d3
		move.l	$C(a0),d2
		move.w	$10(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	$12(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	loc_14D1A
		move.b	d1,d0
		bpl.s	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.s	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.s	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.s	loc_14D3C
		addq.w	#8,d2

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC

; End of function Sonic_WalkSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14D48:				; XREF: Sonic_Jump
		move.b	d0,($FFFFF768).w
		move.b	d0,($FFFFF76A).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to	make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitFloor:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#0,d2

loc_14DD0:
		move.b	($FFFFF76A).w,d3
		cmp.w	d0,d1
		ble.s	loc_14DDE
		move.b	($FFFFF768).w,d3
		exg	d0,d1

loc_14DDE:
		btst	#0,d3
		beq.s	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts	

; End of function Sonic_HitFloor

loc_14DF0:				; XREF: Sonic_WalkSpeed
		addi.w	#$A,d2
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	#0,d2

loc_14E0A:				; XREF: sub_14EB4
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts	

; ---------------------------------------------------------------------------
; Subroutine allowing objects to interact with the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitFloor:
		move.w	8(a0),d3

; End of function ObjHitFloor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitFloor2:
		move.w	$C(a0),d2
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_14E4E
		move.b	#0,d3

locret_14E4E:
		rts	
; End of function ObjHitFloor2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14E50:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14EB4:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function sub_14EB4

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallRight:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts	

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing	Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_DontRunOnWalls:			; XREF: Sonic_Floor; et al
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls


loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	#-$80,d2
		bra.w	loc_14E0A

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitCeiling:
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts	
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitWall:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallLeft:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	($FFFFF768).w,a4
		move.b	#0,(a4)
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	($FFFFF768).w,d3
		btst	#0,d3
		beq.s	locret_15098
		move.b	#$40,d3

locret_15098:
		rts	
; End of function ObjHitWallLeft

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 79 - lamppost
; ---------------------------------------------------------------------------

Obj79:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj79_Index(pc,d0.w),d1
		jsr	Obj79_Index(pc,d1.w)
		jmp	MarkObjGone
; ===========================================================================
Obj79_Index:	dc.w Obj79_Main-Obj79_Index
		dc.w Obj79_BlueLamp-Obj79_Index
		dc.w Obj79_AfterHit-Obj79_Index
		dc.w Obj79_Twirl-Obj79_Index
; ===========================================================================

Obj79_Main:				; XREF: Obj79_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj79,4(a0)
		move.w	#($D800/$20),2(a0)
		move.b	#4,1(a0)
		move.b	#8,Obj_SprWidth(a0)
		move.w	#$280,Obj_Priority(a0)
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		movea.w	d0,a2	; load address into a2
		btst	#0,(a2)
		bne.s	Obj79_RedLamp
		move.b	($FFFFFE30).w,d1
		andi.b	#$7F,d1
		move.b	$28(a0),d2	; get lamppost number
		andi.b	#$7F,d2
		cmp.b	d2,d1		; is lamppost number higher than the number hit?
		bcs.s	Obj79_BlueLamp	; if yes, branch

Obj79_RedLamp:
		bset	#0,(a2)
		move.b	#4,$24(a0)	; run "Obj79_AfterHit" routine
		move.b	#3,$1A(a0)	; use red lamppost frame
		rts	
; ===========================================================================

Obj79_BlueLamp:				; XREF: Obj79_Index
		tst.w	($FFFFFE08).w	; is debug mode	being used?
		bne.w	locret_16F90	; if yes, branch
		tst.b	($FFFFF7C8).w
		bmi.w	locret_16F90
		move.b	($FFFFFE30).w,d1
		andi.b	#$7F,d1
		move.b	$28(a0),d2
		andi.b	#$7F,d2
		cmp.b	d2,d1
		bcs.s	Obj79_HitLamp
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		movea.w	d0,a2	; load address into a2
		bset	#0,(a2)
		move.b	#4,$24(a0)
		move.b	#3,$1A(a0)
		bra.w	locret_16F90
; ===========================================================================

Obj79_HitLamp:
		move.w	($FFFFD008).w,d0
		sub.w	8(a0),d0
		addq.w	#8,d0
		cmpi.w	#$10,d0
		bcc.w	locret_16F90
		move.w	($FFFFD00C).w,d0
		sub.w	$C(a0),d0
		addi.w	#$40,d0
		cmpi.w	#$68,d0
		bcc.s	locret_16F90
		move.w	#$A1,d0
		jsr	(PlaySound_Special).l ;	play lamppost sound
		addq.b	#2,$24(a0)
		jsr	SingleObjLoad
		bne.s	loc_16F76
		move.b	#$79,0(a1)	; load twirling	lamp object
		move.b	#6,$24(a1)	; use "Obj79_Twirl" routine
		move.w	8(a0),$30(a1)
		move.w	$C(a0),$32(a1)
		subi.w	#$18,$32(a1)
		move.l	#Map_obj79,4(a1)
		move.w	#($D800/$20),2(a1)
		move.b	#4,1(a1)
		move.b	#8,Obj_SprWidth(a1)
		move.w	#$200,Obj_Priority(a1)
		move.b	#2,$1A(a1)
		move.w	#$20,$36(a1)

loc_16F76:
		move.b	#1,$1A(a0)	; use "post only" frame, with no lamp
		bsr.w	Obj79_StoreInfo
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		movea.w	d0,a2	; load address into a2
		bset	#0,(a2)

locret_16F90:
		rts	
; ===========================================================================

Obj79_AfterHit:				; XREF: Obj79_Index
		rts	
; ===========================================================================

Obj79_Twirl:				; XREF: Obj79_Index
		subq.w	#1,$36(a0)
		bpl.s	loc_16FA0
		move.b	#4,$24(a0)

loc_16FA0:
		move.b	$26(a0),d0
		subi.b	#$10,$26(a0)
		subi.b	#$40,d0
		jsr	(CalcSine).l
		muls.w	#$C00,d1
		swap	d1
		add.w	$30(a0),d1
		move.w	d1,8(a0)
		muls.w	#$C00,d0
		swap	d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	store information when you hit a lamppost
; ---------------------------------------------------------------------------

Obj79_StoreInfo:			; XREF: Obj79_HitLamp
		move.b	$28(a0),($FFFFFE30).w 		; lamppost number
		move.b	($FFFFFE30).w,($FFFFFE31).w
		move.w	8(a0),($FFFFFE32).w		; x-position
		move.w	$C(a0),($FFFFFE34).w		; y-position
		move.w	($FFFFFE20).w,($FFFFFE36).w 	; rings
		move.b	($FFFFFE1B).w,($FFFFFE54).w 	; lives
		move.l	($FFFFFE22).w,($FFFFFE38).w 	; time
		move.b	($FFFFF742).w,($FFFFFE3C).w 	; routine counter for dynamic level mod
		move.w	($FFFFF72E).w,($FFFFFE3E).w 	; lower y-boundary of level
		move.w	($FFFFF700).w,($FFFFFE40).w 	; screen x-position
		move.w	($FFFFF704).w,($FFFFFE42).w 	; screen y-position
		move.w	($FFFFF708).w,($FFFFFE44).w 	; bg position
		move.w	($FFFFF70C).w,($FFFFFE46).w 	; bg position
		move.w	($FFFFF710).w,($FFFFFE48).w 	; bg position
		move.w	($FFFFF714).w,($FFFFFE4A).w 	; bg position
		move.w	($FFFFF718).w,($FFFFFE4C).w 	; bg position
		move.w	($FFFFF71C).w,($FFFFFE4E).w 	; bg position
		move.w	($FFFFF648).w,($FFFFFE50).w 	; water height
		move.b	($FFFFF64D).w,($FFFFFE52).w 	; rountine counter for water
		move.b	($FFFFF64E).w,($FFFFFE53).w 	; water direction
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	load stored info when you start	a level	from a lamppost
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj79_LoadInfo:				; XREF: LevelSizeLoad
		move.b	($FFFFFE31).w,($FFFFFE30).w
		move.w	($FFFFFE32).w,($FFFFD008).w
		move.w	($FFFFFE34).w,($FFFFD00C).w
		move.w	($FFFFFE36).w,($FFFFFE20).w
		move.b	($FFFFFE54).w,($FFFFFE1B).w
		clr.w	($FFFFFE20).w
		clr.b	($FFFFFE1B).w
		move.l	($FFFFFE38).w,($FFFFFE22).w
		move.b	#59,($FFFFFE25).w
		subq.b	#1,($FFFFFE24).w
		move.b	($FFFFFE3C).w,($FFFFF742).w
		move.b	($FFFFFE52).w,($FFFFF64D).w
		move.w	($FFFFFE3E).w,($FFFFF72E).w
		move.w	($FFFFFE3E).w,($FFFFF726).w
		move.w	($FFFFFE40).w,($FFFFF700).w
		move.w	($FFFFFE42).w,($FFFFF704).w
		move.w	($FFFFFE44).w,($FFFFF708).w
		move.w	($FFFFFE46).w,($FFFFF70C).w
		move.w	($FFFFFE48).w,($FFFFF710).w
		move.w	($FFFFFE4A).w,($FFFFF714).w
		move.w	($FFFFFE4C).w,($FFFFF718).w
		move.w	($FFFFFE4E).w,($FFFFF71C).w
		cmpi.b	#1,($FFFFFE10).w
		bne.s	loc_170E4
		move.w	($FFFFFE50).w,($FFFFF648).w
		move.b	($FFFFFE52).w,($FFFFF64D).w
		move.b	($FFFFFE53).w,($FFFFF64E).w

loc_170E4:
		tst.b	($FFFFFE30).w
		bpl.s	locret_170F6
		move.w	($FFFFFE32).w,d0
		subi.w	#$A0,d0
		move.w	d0,($FFFFF728).w

locret_170F6:
		rts	
; End of function Obj79_LoadInfo

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - lamppost
; ---------------------------------------------------------------------------
Map_obj79:
	include "_maps\obj79.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3D - Eggman (GHZ)
; ---------------------------------------------------------------------------

Obj3D:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3D_Index(pc,d0.w),d1
		jmp	Obj3D_Index(pc,d1.w)
; ===========================================================================
Obj3D_Index:	dc.w Obj3D_Main-Obj3D_Index
		dc.w Obj3D_ShipMain-Obj3D_Index
		dc.w Obj3D_FaceMain-Obj3D_Index
		dc.w Obj3D_FlameMain-Obj3D_Index

Obj3D_ObjData:	dc.b 2,	0		; routine counter, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

Obj3D_Main:				; XREF: Obj3D_Index
		lea	(Obj3D_ObjData).l,a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.s	Obj3D_LoadBoss
; ===========================================================================

Obj3D_Loop:
		jsr	SingleObjLoad2
		bne.s	loc_17772

Obj3D_LoadBoss:				; XREF: Obj3D_Main
		move.b	(a2)+,$24(a1)
		move.b	#$3D,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,Obj_SprWidth(a1)
		move.w	#$180,Obj_Priority(a1)
		move.b	(a2)+,$1C(a1)
		move.l	a0,$34(a1)
		dbf	d1,Obj3D_Loop	; repeat sequence 2 more times

loc_17772:
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,$20(a0)
		move.b	#8,$21(a0)	; set number of	hits to	8

Obj3D_ShipMain:				; XREF: Obj3D_Index
		moveq	#0,d0
		move.b	$25(a0),d0
		move.w	Obj3D_ShipIndex(pc,d0.w),d1
		jsr	Obj3D_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	AnimateSprite
		move.b	$22(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	DisplaySprite
; ===========================================================================
Obj3D_ShipIndex:dc.w Obj3D_ShipStart-Obj3D_ShipIndex
		dc.w Obj3D_MakeBall-Obj3D_ShipIndex
		dc.w Obj3D_ShipMove-Obj3D_ShipIndex
		dc.w loc_17954-Obj3D_ShipIndex
		dc.w loc_1797A-Obj3D_ShipIndex
		dc.w loc_179AC-Obj3D_ShipIndex
		dc.w loc_179F6-Obj3D_ShipIndex
; ===========================================================================

Obj3D_ShipStart:			; XREF: Obj3D_ShipIndex
		move.w	#$100,$12(a0)	; move ship down
		bsr.w	BossMove
		cmpi.w	#$338,$38(a0)
		bne.s	loc_177E6
		move.w	#0,$12(a0)	; stop ship
		addq.b	#2,$25(a0)	; goto next routine

loc_177E6:
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)
		addq.b	#2,$3F(a0)
		cmpi.b	#8,$25(a0)
		bcc.s	locret_1784A
		tst.b	$22(a0)
		bmi.s	loc_1784C
		tst.b	$20(a0)
		bne.s	locret_1784A
		tst.b	$3E(a0)
		bne.s	Obj3D_ShipFlash
		move.b	#$20,$3E(a0)	; set number of	times for ship to flash
		move.w	#$AC,d0
		jsr	(PlaySound_Special).l ;	play boss damage sound

Obj3D_ShipFlash:
		lea	($FFFFFB22).w,a1 ; load	2nd pallet, 2nd	entry
		moveq	#0,d0		; move 0 (black) to d0
		tst.w	(a1)
		bne.s	loc_1783C
		move.w	#$EEE,d0	; move 0EEE (white) to d0

loc_1783C:
		move.w	d0,(a1)		; load colour stored in	d0
		subq.b	#1,$3E(a0)
		bne.s	locret_1784A
		move.b	#$F,$20(a0)

locret_1784A:
		rts	
; ===========================================================================

loc_1784C:				; XREF: loc_177E6
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#8,$25(a0)
		move.w	#$B3,$3C(a0)
		rts	

; ---------------------------------------------------------------------------
; Defeated boss	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossDefeated:
		move.b	($FFFFFE0F).w,d0
		andi.b	#7,d0
		bne.s	locret_178A2
		jsr	SingleObjLoad
		bne.s	locret_178A2
		move.b	#$3F,0(a1)	; load explosion object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(RandomNumber).l
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)
		clr.b	($FFFFFE1E).w   ; stop time counter

locret_178A2:
		rts	
; End of function BossDefeated

; ---------------------------------------------------------------------------
; Subroutine to	move a boss
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossMove:
        move.w	Obj_XVelocity(a0),d0        
        ext.l	d0
        lsl.l	#8,d0                
        add.l	d0,$30(a0)  
        move.w	Obj_YVelocity(a0),d0          
        ext.l	d0
        lsl.l	#8,d0                
        add.l	d0,$38(a0)
        rts  
; End of function BossMove

; ===========================================================================

Obj3D_MakeBall:				; XREF: Obj3D_ShipIndex
		move.w	#-$100,$10(a0)
		move.w	#-$40,$12(a0)
		bsr.w	BossMove
		cmpi.w	#$2A00,$30(a0)
		bne.s	loc_17916
		move.w	#0,$10(a0)
		move.w	#0,$12(a0)
		addq.b	#2,$25(a0)
		jsr	SingleObjLoad2
		bne.s	loc_17910
		move.b	#$48,0(a1)	; load swinging	ball object
		move.w	$30(a0),8(a1)
		move.w	$38(a0),$C(a1)
		move.l	a0,$34(a1)

loc_17910:
		move.w	#$77,$3C(a0)

loc_17916:
		bra.w	loc_177E6
; ===========================================================================

Obj3D_ShipMove:				; XREF: Obj3D_ShipIndex
		subq.w	#1,$3C(a0)
		bpl.s	Obj3D_Reverse
		addq.b	#2,$25(a0)
		move.w	#$3F,$3C(a0)
		move.w	#$100,$10(a0)	; move the ship	sideways
		cmpi.w	#$2A00,$30(a0)
		bne.s	Obj3D_Reverse
		move.w	#$7F,$3C(a0)
		move.w	#$40,$10(a0)

Obj3D_Reverse:
		btst	#0,$22(a0)
		bne.s	loc_17950
		neg.w	$10(a0)		; reverse direction of the ship

loc_17950:
		bra.w	loc_177E6
; ===========================================================================

loc_17954:				; XREF: Obj3D_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.s	loc_17960
		bsr.w	BossMove
		bra.s	loc_17976
; ===========================================================================

loc_17960:
		bchg	#0,$22(a0)
		move.w	#$3F,$3C(a0)
		subq.b	#2,$25(a0)
		move.w	#0,$10(a0)

loc_17976:
		bra.w	loc_177E6
; ===========================================================================

loc_1797A:				; XREF: Obj3D_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.s	loc_17984
		bra.w	BossDefeated
; ===========================================================================

loc_17984:
		bset	#0,$22(a0)
		bclr	#7,$22(a0)
		clr.w	$10(a0)
		addq.b	#2,$25(a0)
		move.w	#-$26,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.s	locret_179AA
		move.b	#1,($FFFFF7A7).w

locret_179AA:
		rts	
; ===========================================================================

loc_179AC:				; XREF: Obj3D_ShipIndex
		addq.w	#1,$3C(a0)
		beq.s	loc_179BC
		bpl.s	loc_179C2
		addi.w	#$18,$12(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179BC:
		clr.w	$12(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179C2:
		cmpi.w	#$30,$3C(a0)
		bcs.s	loc_179DA
		beq.s	loc_179E0
		cmpi.w	#$38,$3C(a0)
		bcs.s	loc_179EE
		addq.b	#2,$25(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179DA:
		subq.w	#8,$12(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179E0:
		clr.w	$12(a0)
		move.w	#$81,d0
		jsr	(PlaySound).l	; play GHZ music

loc_179EE:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

loc_179F6:				; XREF: Obj3D_ShipIndex
		move.w	#$400,$10(a0)
		move.w	#-$40,$12(a0)
		cmpi.w	#$2AC0,($FFFFF72A).w
		beq.s	loc_17A10
		addq.w	#2,($FFFFF72A).w
		bra.s	loc_17A16
; ===========================================================================

loc_17A10:
		tst.b	1(a0)
		bpl.s	Obj3D_ShipDel

loc_17A16:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

Obj3D_ShipDel:
		jmp	DeleteObject
; ===========================================================================

Obj3D_FaceMain:				; XREF: Obj3D_Index
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	$25(a1),d0
		subq.b	#4,d0
		bne.s	loc_17A3E
		cmpi.w	#$2A00,$30(a1)
		bne.s	loc_17A46
		moveq	#4,d1

loc_17A3E:
		subq.b	#6,d0
		bmi.s	loc_17A46
		moveq	#$A,d1
		bra.s	loc_17A5A
; ===========================================================================

loc_17A46:
		tst.b	$20(a1)
		bne.s	loc_17A50
		moveq	#5,d1
		bra.s	loc_17A5A
; ===========================================================================

loc_17A50:
		cmpi.b	#4,($FFFFD024).w
		bcs.s	loc_17A5A
		moveq	#4,d1

loc_17A5A:
		move.b	d1,$1C(a0)
		subq.b	#2,d0
		bne.s	Obj3D_FaceDisp
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.s	Obj3D_FaceDel

Obj3D_FaceDisp:
		bra.s	Obj3D_Display
; ===========================================================================

Obj3D_FaceDel:
		jmp	DeleteObject
; ===========================================================================

Obj3D_FlameMain:			; XREF: Obj3D_Index
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,$25(a1)
		bne.s	loc_17A96
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.s	Obj3D_FlameDel
		bra.s	Obj3D_FlameDisp
; ===========================================================================

loc_17A96:
		move.w	$10(a1),d0
		beq.s	Obj3D_FlameDisp
		move.b	#8,$1C(a0)

Obj3D_FlameDisp:
		bra.s	Obj3D_Display
; ===========================================================================

Obj3D_FlameDel:
		jmp	DeleteObject
; ===========================================================================

Obj3D_Display:				; XREF: Obj3D_FaceDisp; Obj3D_FlameDisp
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	$22(a1),$22(a0)
		lea	(Ani_Eggman).l,a1
		jsr	AnimateSprite
		move.b	$22(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	DisplaySprite
; ===========================================================================
Ani_Eggman:
	include "_anim\Eggman.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Eggman (boss levels)
; ---------------------------------------------------------------------------
Map_Eggman:
	include "_maps\Eggman.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3E - prison capsule
; ---------------------------------------------------------------------------

Obj3E:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3E_Index(pc,d0.w),d1
		jsr	Obj3E_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bls.s	Obj3E_NoDel
		move.w	Obj_RespawnIdx(a0),d0	; get address in respawn table
		beq.s	Obj3E_Delete		; if it's zero, don't remember object
		movea.w	d0,a2	; load address into a2
		bclr	#7,(a2)	; clear respawn table entry, so object can be loaded again
		bra.s	Obj3E_Delete	; and delete object

Obj3e_NoDel:
		jmp	DisplaySprite
; ===========================================================================

Obj3E_Delete:
		jmp	DeleteObject
; ===========================================================================
Obj3E_Index:	dc.w Obj3E_Main-Obj3E_Index
		dc.w Obj3E_BodyMain-Obj3E_Index
		dc.w Obj3E_Switched-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Animals-Obj3E_Index
		dc.w Obj3E_EndAct-Obj3E_Index

Obj3E_Var:	dc.b 2,	$20, 4,	0	; routine, width, priority, frame
		dc.b 4,	$C, 5, 1
		dc.b 6,	$10, 4,	3
		dc.b 8,	$10, 3,	5
; ===========================================================================

Obj3E_Main:				; XREF: Obj3E_Index
		move.l	#Map_obj3E,4(a0)
		move.w	#$49D,2(a0)
		move.b	#4,1(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#2,d0
		lea	Obj3E_Var(pc,d0.w),a1
		move.b	(a1)+,$24(a0)
		move.b	(a1)+,Obj_SprWidth(a0)
		move.b	(a1)+,Obj_Priority(a0)
		move.w	Obj_Priority(a0),d0 
		lsr.w	#1,d0
		andi.w	#$380,d0 
		move.w	d0,Obj_Priority(a0)
		move.b	(a1)+,$1A(a0)
		cmpi.w	#8,d0		; is object type number	02?
		bne.s	Obj3E_Not02	; if not, branch
		move.b	#6,$20(a0)
		move.b	#8,$21(a0)

Obj3E_Not02:
		rts	
; ===========================================================================

Obj3E_BodyMain:				; XREF: Obj3E_Index
		cmpi.b	#2,($FFFFF7A7).w
		beq.s	Obj3E_ChkOpened
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	#$18,d3
		move.w	8(a0),d4
		jmp	SolidObject
; ===========================================================================

Obj3E_ChkOpened:
		tst.b	$25(a0)		; has the prison been opened?
		beq.s	Obj3E_DoOpen	; if yes, branch
		clr.b	$25(a0)
		bclr	#3,($FFFFD022).w
		bset	#1,($FFFFD022).w

Obj3E_DoOpen:
		move.b	#2,$1A(a0)	; use frame number 2 (destroyed	prison)
		rts	
; ===========================================================================

Obj3E_Switched:				; XREF: Obj3E_Index
		move.w	#$17,d1
		move.w	#8,d2
		move.w	#8,d3
		move.w	8(a0),d4
		jsr	SolidObject
		lea	(Ani_obj3E).l,a1
		jsr	AnimateSprite
		move.w	$30(a0),$C(a0)
		tst.b	$25(a0)
		beq.s	locret_1AC60
		addq.w	#8,$C(a0)
		move.b	#$A,$24(a0)
		move.w	#$3C,$1E(a0)
		clr.b	($FFFFFE1E).w	; stop time counter
		clr.b	($FFFFF7AA).w	; lock screen position
		move.b	#1,($FFFFF7CC).w ; lock	controls
		move.w	#$800,($FFFFF602).w ; make Sonic run to	the right
		clr.b	$25(a0)
		bclr	#3,($FFFFD022).w
		bset	#1,($FFFFD022).w

locret_1AC60:
		rts	
; ===========================================================================

Obj3E_Explosion:			; XREF: Obj3E_Index
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_1ACA0
		jsr	SingleObjLoad
		bne.s	loc_1ACA0
		move.b	#$3F,0(a1)	; load explosion object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(RandomNumber).l
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

loc_1ACA0:
		subq.w	#1,$1E(a0)
		beq.s	Obj3E_MakeAnimal
		rts	
; ===========================================================================

Obj3E_MakeAnimal:
		move.b	#2,($FFFFF7A7).w
		move.b	#$C,$24(a0)	; replace explosions with animals
		move.b	#6,$1A(a0)
		move.w	#$96,$1E(a0)
		addi.w	#$20,$C(a0)
		moveq	#7,d6
		move.w	#$9A,d5
		moveq	#-$1C,d4

Obj3E_Loop:
		jsr	SingleObjLoad
		bne.s	locret_1ACF8
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		add.w	d4,8(a1)
		addq.w	#7,d4
		move.w	d5,$36(a1)
		subq.w	#8,d5
		dbf	d6,Obj3E_Loop	; repeat 7 more	times

locret_1ACF8:
		rts	
; ===========================================================================

Obj3E_Animals:				; XREF: Obj3E_Index
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_1AD38
		jsr	SingleObjLoad
		bne.s	loc_1AD38
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		subq.w	#6,d0
		tst.w	d1
		bpl.s	loc_1AD2E
		neg.w	d0

loc_1AD2E:
		add.w	d0,8(a1)
		move.w	#$C,$36(a1)

loc_1AD38:
		subq.w	#1,$1E(a0)
		bne.s	locret_1AD48
		addq.b	#2,$24(a0)
		move.w	#180,$1E(a0)

locret_1AD48:
		rts	
; ===========================================================================

Obj3E_EndAct:				; XREF: Obj3E_Index
		moveq	#$3E,d0
		moveq	#$28,d1
		moveq	#$40,d2
		lea	($FFFFD040).w,a1 ; load	object RAM

Obj3E_FindObj28:
		cmp.b	(a1),d1		; is object $28	(animal) loaded?
		beq.s	Obj3E_Obj28Found ; if yes, branch
		adda.w	d2,a1		; next object RAM
		dbf	d0,Obj3E_FindObj28 ; repeat $3E	times

		jsr	GotThroughAct
		jmp	DeleteObject
; ===========================================================================

Obj3E_Obj28Found:
		rts	
; ===========================================================================
Ani_obj3E:
	include "_anim\obj3E.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - prison capsule
; ---------------------------------------------------------------------------
Map_obj3E:
	include "_maps\obj3E.asm"

; ---------------------------------------------------------------------------
; Object touch response	subroutine - $20(a0) in	the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


TouchResponse:				; XREF: Obj01
		jsr	(Touch_Rings).l
		move.w	8(a0),d2	; load Sonic's x-axis value
		move.w	$C(a0),d3	; load Sonic's y-axis value
		subq.w	#8,d2
		moveq	#0,d5
		move.b	$16(a0),d5	; load Sonic's height
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#$39,$1A(a0)	; is Sonic ducking?
		bne.s	Touch_NoDuck	; if not, branch
		addi.w	#$C,d3
		moveq	#$A,d5

Touch_NoDuck:
		move.w	#$10,d4
		add.w	d5,d5
		lea	($FFFFD800).w,a1 ; begin checking the object RAM
		move.w	#$5F,d6

Touch_Loop:
		tst.b	1(a1)
		bpl.s	Touch_NextObj
		move.b	$20(a1),d0	; load touch response number
		bne.s	Touch_Height	; if touch response is not 0, branch

Touch_NextObj:
		lea	$40(a1),a1	; next object RAM
		dbf	d6,Touch_Loop	; repeat $5F more times

		moveq	#0,d0
		rts	
; ===========================================================================
Touch_Sizes:	dc.b  $14, $14		; width, height
		dc.b   $C, $14
		dc.b  $14,  $C
		dc.b	4, $10
		dc.b   $C, $12
		dc.b  $10, $10
		dc.b	6,   6
		dc.b  $18,  $C
		dc.b   $C, $10
		dc.b  $10,  $C
		dc.b	8,   8
		dc.b  $14, $10
		dc.b  $14,   8
		dc.b   $E,  $E
		dc.b  $18, $18
		dc.b  $28, $10
		dc.b  $10, $18
		dc.b	8, $10
		dc.b  $20, $70
		dc.b  $40, $20
		dc.b  $80, $20
		dc.b  $20, $20
		dc.b	8,   8
		dc.b	4,   4
		dc.b  $20,   8
		dc.b   $C,  $C
		dc.b	8,   4
		dc.b  $18,   4
		dc.b  $28,   4
		dc.b	4,   8
		dc.b	4, $18
		dc.b	4, $28
		dc.b	4, $20
		dc.b  $18, $18
		dc.b   $C, $18
		dc.b  $48,   8
; ===========================================================================

Touch_Height:				; XREF: TouchResponse
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	Touch_Sizes-2(pc,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_1AE98
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	Touch_Width
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AE98:
		cmp.w	d4,d0
		bhi.w	Touch_NextObj

Touch_Width:
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.s	loc_1AEB6
		add.w	d1,d1
		add.w	d0,d1
		bcs.s	Touch_ChkValue
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AEB6:
		cmp.w	d5,d0
		bhi.w	Touch_NextObj

Touch_ChkValue:
		move.b	$20(a1),d1	; load touch response number
		andi.b	#$C0,d1		; is touch response $40	or higher?
		beq.w	Touch_Enemy	; if not, branch
		cmpi.b	#$C0,d1		; is touch response $C0	or higher?
		beq.w	Touch_Special	; if yes, branch
		tst.b	d1		; is touch response $80-$BF ?
		bmi.w	Touch_ChkHurt	; if yes, branch

; touch	response is $40-$7F

		move.b	$20(a1),d0
		andi.b	#$3F,d0
		cmpi.b	#6,d0		; is touch response $46	?
		beq.s	Touch_Monitor	; if yes, branch
		cmpi.w	#$5A,$30(a0)
		bcc.w	locret_1AEF2
		addq.b	#2,$24(a1)	; advance the object's routine counter

locret_1AEF2:
		rts	
; ===========================================================================

Touch_Monitor:
		tst.w	$12(a0)		; is Sonic moving upwards?
		bpl.s	loc_1AF1E	; if not, branch
		move.w	$C(a0),d0
		subi.w	#$10,d0
		cmp.w	$C(a1),d0
		bcs.s	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		move.w	#-$180,$12(a1)
		tst.b	$25(a1)
		bne.s	locret_1AF2E
		addq.b	#4,$25(a1)	; advance the monitor's routine counter
		rts	
; ===========================================================================

loc_1AF1E:
		cmpi.b	#2,$1C(a0)	; is Sonic rolling/jumping?
		bne.s	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		addq.b	#2,$24(a1)	; advance the monitor's routine counter

locret_1AF2E:
		rts	
; ===========================================================================

Touch_Enemy:				; XREF: Touch_ChkValue
		tst.b	($FFFFFE2D).w	; is Sonic invincible?
		bne.s	loc_1AF40	; if yes, branch
		cmpi.b	#$1F,$1C(a0)	; is Sonic Spin Dashing?
		beq.w	loc_1AF40	; if yes, branch
		cmpi.b	#2,$1C(a0)	; is Sonic rolling?
		bne.w	Touch_ChkHurt	; if not, branch

loc_1AF40:
		tst.b	$21(a1)
		beq.s	Touch_KillEnemy
		neg.w	$10(a0)
		neg.w	$12(a0)
		asr	$10(a0)
		asr	$12(a0)
		move.b	#0,$20(a1)
		subq.b	#1,$21(a1)
		bne.s	locret_1AF68
		bset	#7,$22(a1)

locret_1AF68:
		rts	
; ===========================================================================

Touch_KillEnemy:
		bset	#7,$22(a1)
		moveq	#0,d0
		move.w	($FFFFF7D0).w,d0
		addq.w	#2,($FFFFF7D0).w ; add 2 to item bonus counter
		cmpi.w	#6,d0
		bcs.s	loc_1AF82
		moveq	#6,d0

loc_1AF82:
		move.w	d0,$3E(a1)
		move.w	Enemy_Points(pc,d0.w),d0
		cmpi.w	#$20,($FFFFF7D0).w ; have 16 enemies been destroyed?
		bcs.s	loc_1AF9C	; if not, branch
		move.w	#1000,d0	; fix bonus to 10000
		move.w	#$A,$3E(a1)

loc_1AF9C:
		bsr.w	AddPoints
		move.b	#$27,0(a1)	; change object	to points
		move.b	#0,$24(a1)
		tst.w	$12(a0)
		bmi.s	loc_1AFC2
		move.w	$C(a0),d0
		cmp.w	$C(a1),d0
		bcc.s	loc_1AFCA
		neg.w	$12(a0)
		rts	
; ===========================================================================

loc_1AFC2:
		addi.w	#$100,$12(a0)
		rts	
; ===========================================================================

loc_1AFCA:
		subi.w	#$100,$12(a0)
		rts	
; ===========================================================================
Enemy_Points:	dc.w 10, 20, 50, 100
; ===========================================================================

loc_1AFDA:				; XREF: Touch_CatKiller
		bset	#7,$22(a1)

Touch_ChkHurt:				; XREF: Touch_ChkValue
		tst.b	($FFFFFE2D).w	; is Sonic invincible?
		beq.s	Touch_Hurt	; if not, branch

loc_1AFE6:				; XREF: Touch_Hurt
		moveq	#-1,d0
		rts	
; ===========================================================================

Touch_Hurt:				; XREF: Touch_ChkHurt
		tst.w	$30(a0)
		bne.s	loc_1AFE6
		movea.l	a1,a2

; End of function TouchResponse
; continue straight to HurtSonic

; ---------------------------------------------------------------------------
; Hurting Sonic	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HurtSonic:
		tst.b	($FFFFFE2C).w	; does Sonic have a shield?
		bne.s	Hurt_Shield	; if yes, branch
		tst.w	($FFFFFE20).w	; does Sonic have any rings?
		beq.w	Hurt_NoRings	; if not, branch
		jsr	SingleObjLoad
		bne.s	Hurt_Shield
		move.b	#$37,0(a1)	; load bouncing	multi rings object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Hurt_Shield:
		move.b	#0,($FFFFFE2C).w ; remove shield
		move.b	#4,$24(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#-$400,$12(a0)	; make Sonic bounce away from the object
		move.w	#-$200,$10(a0)
		btst	#6,$22(a0)
		beq.s	Hurt_Reverse
		move.w	#-$200,$12(a0)
		move.w	#-$100,$10(a0)

Hurt_Reverse:
		move.w	8(a0),d0
		cmp.w	8(a2),d0
		bcs.s	Hurt_ChkSpikes	; if Sonic is left of the object, branch
		neg.w	$10(a0)		; if Sonic is right of the object, reverse

Hurt_ChkSpikes:
		move.b	#0,$39(a0)	; clear Spin Dash flag
		move.w	#0,Obj_Inertia(a0)
		move.b	#$1A,$1C(a0)
		move.w	#$78,$30(a0)
		move.w	#$A3,d0		; load normal damage sound
		cmpi.b	#$36,(a2)	; was damage caused by spikes?
		bne.s	Hurt_Sound	; if not, branch
		cmpi.b	#$16,(a2)	; was damage caused by LZ harpoon?
		bne.s	Hurt_Sound	; if not, branch
		move.w	#$A6,d0		; load spikes damage sound

Hurt_Sound:
		jsr	(PlaySound_Special).l
		moveq	#-1,d0
		rts	
; ===========================================================================

Hurt_NoRings:
		tst.w	($FFFFFFFA).w	; is debug mode	cheat on?
		bne.w	Hurt_Shield	; if yes, branch
; End of function HurtSonic

; ---------------------------------------------------------------------------
; Subroutine to	kill Sonic
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


KillSonic:
		tst.w	($FFFFFE08).w	; is debug mode	active?
		bne.s	Kill_NoDeath	; if yes, branch
		move.b	#0,($FFFFFE2D).w ; remove invincibility
		move.b	#6,$24(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#-$700,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,Obj_Inertia(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$18,$1C(a0)
		bset	#7,2(a0)
		move.w	#$A3,d0		; play normal death sound
		cmpi.b	#$36,(a2)	; check	if you were killed by spikes
		bne.s	Kill_Sound
		move.w	#$A6,d0		; play spikes death sound

Kill_Sound:
		jsr	(PlaySound_Special).l

Kill_NoDeath:
		moveq	#-1,d0
		rts	
; End of function KillSonic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Touch_Special:				; XREF: Touch_ChkValue
		move.b	$20(a1),d1
		andi.b	#$3F,d1
		cmpi.b	#$B,d1		; is touch response $CB	?
		beq.s	Touch_CatKiller	; if yes, branch
		cmpi.b	#$C,d1		; is touch response $CC	?
		beq.s	Touch_Yadrin	; if yes, branch
		cmpi.b	#$17,d1		; is touch response $D7	?
		beq.s	Touch_D7orE1	; if yes, branch
		cmpi.b	#$21,d1		; is touch response $E1	?
		beq.s	Touch_D7orE1	; if yes, branch
		rts	
; ===========================================================================

Touch_CatKiller:			; XREF: Touch_Special
		bra.w	loc_1AFDA
; ===========================================================================

Touch_Yadrin:				; XREF: Touch_Special
		sub.w	d0,d5
		cmpi.w	#8,d5
		bcc.s	loc_1B144
		move.w	8(a1),d0
		subq.w	#4,d0
		btst	#0,$22(a1)
		beq.s	loc_1B130
		subi.w	#$10,d0

loc_1B130:
		sub.w	d2,d0
		bcc.s	loc_1B13C
		addi.w	#$18,d0
		bcs.s	loc_1B140
		bra.s	loc_1B144
; ===========================================================================

loc_1B13C:
		cmp.w	d4,d0
		bhi.s	loc_1B144

loc_1B140:
		bra.w	Touch_ChkHurt
; ===========================================================================

loc_1B144:
		bra.w	Touch_Enemy
; ===========================================================================

Touch_D7orE1:				; XREF: Touch_Special
		addq.b	#1,$21(a1)
		rts	
; End of function Touch_Special

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 03 - Collision plane/layer switcher (From Sonic 2 [Modified])
; ---------------------------------------------------------------------------

Obj03:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj03_Index(pc,d0.w),d1
		jsr	Obj03_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj03_MarkChkGone
        tst.w	($FFFFFE08).w
        beq.s   @Return
        jmp DisplaySprite

@Return:
        rts

Obj03_MarkChkGone:
		jmp	Mark_ChkGone
; ===========================================================================
; ---------------------------------------------------------------------------
Obj03_Index:	dc.w Obj03_Init-Obj03_Index
		dc.w Obj03_MainX-Obj03_Index
		dc.w Obj03_MainY-Obj03_Index
; ---------------------------------------------------------------------------
; ===========================================================================
; ---------------------------------------------------------------------------
; Initiation
; ---------------------------------------------------------------------------

Obj03_Init:
		addq.b	#2,$24(a0)
		move.l	#Pathswapper_Maps,$04(a0)
		move.w	#$26BC,$02(a0)
		ori.b	#4,$01(a0)
		move.b	#$10,Obj_SprWidth(a0)
		move.w	#$280,Obj_Priority(a0)
		move.b	$28(a0),d0
		btst	#2,d0
		beq.s	Obj03_Init_CheckX

;Obj03_Init_CheckY:
		addq.b	#2,$24(a0) ; => Obj03_MainY
		andi.w	#7,d0
		move.b	d0,$1A(a0)
		andi.w	#3,d0
		add.w	d0,d0
		move.w	word_1FD68(pc,d0.w),$32(a0)
		move.w	$0C(a0),d1
		lea	($FFFFD000).w,a1 ; a1=character
		cmp.w	$0C(a1),d1
		bcc.s	Obj03_Init_Next
		move.b	#1,$34(a0)
Obj03_Init_Next:
	;	lea	(Sidekick).w,a1 ; a1=character
	;	cmp.w	$0C(a1),d1
	;	bcc.s	+
	;	move.b	#1,$35(a0)
;+
		bra.w	Obj03_MainY
; ===========================================================================
word_1FD68:
	dc.w  $020
	dc.w  $040	; 1
	dc.w  $080	; 2
	dc.w  $100	; 3
; ===========================================================================
; loc_1FD70:
Obj03_Init_CheckX:
		andi.w	#3,d0
		move.b	d0,$1A(a0)
		add.w	d0,d0
		move.w	word_1FD68(pc,d0.w),$32(a0)
		move.w	$08(a0),d1
		lea	($FFFFD000).w,a1 ; a1=character
		cmp.w	$08(a1),d1
		bcc.s	Obj03_Init_CheckX_Next
		move.b	#1,$34(a0)
Obj03_Init_CheckX_Next:
	;	lea	(Sidekick).w,a1 ; a1=character
	;	cmp.w	$08(a1),d1
	;	bcc.s	+
	;	move.b	#1,$35(a0)
;+

Obj03_MainX:
		tst.w	($FFFFFE08).w
		bne.w	return_1FEAC
		move.w	$08(a0),d1
		lea	$34(a0),a2
		lea	($FFFFD000).w,a1 ; a1=character
;		bsr.s	+
;		lea	(Sidekick).w,a1 ; a1=character

;+
		tst.b	(a2)+
		bne.s	Obj03_MainX_Alt
		cmp.w	$08(a1),d1
		bhi.w	return_1FEAC
		move.b	#1,-1(a2)
		move.w	$0C(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$0C(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FEAC
		cmp.w	d3,d4
		bge.w	return_1FEAC
		move.b	$28(a0),d0
		bpl.s	Obj03_ICX_B1
		btst	#1,$2B(a1)
		bne.w	return_1FEAC

Obj03_ICX_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_ICX_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	Obj03_ICX_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_ICX_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#5,d0
		beq.s	return_1FEAC
		ori.w	#$8000,$02(a1)
		bra.s	return_1FEAC
; ===========================================================================

Obj03_MainX_Alt:
		cmp.w	$08(a1),d1
		bls.w	return_1FEAC
		move.b	#0,-1(a2)
		move.w	$0C(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$0C(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FEAC
		cmp.w	d3,d4
		bge.w	return_1FEAC
		move.b	$28(a0),d0
		bpl.s	Obj03_MXA_B1
		btst	#1,$2B(a1)
		bne.w	return_1FEAC

Obj03_MXA_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_MXA_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	Obj03_MXA_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MXA_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#6,d0
		beq.s	return_1FEAC
		ori.w	#$8000,$02(a1)

return_1FEAC:
		rts

; ===========================================================================

Obj03_MainY:
		tst.w	($FFFFFE08).w
		bne.w	return_1FFB6
		move.w	$0C(a0),d1
		lea	$34(a0),a2
		lea	($FFFFD000).w,a1 ; a1=character
;		bsr.s	+
;		lea	(Sidekick).w,a1 ; a1=character

;+
		tst.b	(a2)+
		bne.s	Obj03_MainY_Alt
		cmp.w	$0C(a1),d1
		bhi.w	return_1FFB6
		move.b	#1,-1(a2)
		move.w	$08(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$08(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FFB6
		cmp.w	d3,d4
		bge.w	return_1FFB6
		move.b	$28(a0),d0
		bpl.s	Obj03_MY_B1
		btst	#1,$2B(a1)
		bne.w	return_1FFB6

Obj03_MY_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_MY_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	Obj03_MY_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MY_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#5,d0
		beq.s	return_1FFB6
		ori.w	#$8000,$02(a1)
		bra.s	return_1FFB6

; ===========================================================================

Obj03_MainY_Alt:
		cmp.w	$0C(a1),d1
		bls.w	return_1FFB6
		move.b	#0,-1(a2)
		move.w	$08(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$08(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FFB6
		cmp.w	d3,d4
		bge.w	return_1FFB6
		move.b	$28(a0),d0
		bpl.s	Obj03_MYA_B1
		btst	#1,$2B(a1)
		bne.w	return_1FFB6

Obj03_MYA_B1
		btst	#0,$01(a0)
		bne.s	Obj03_MYA_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	Obj03_MYA_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MYA_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#6,d0
		beq.s	return_1FFB6
		ori.w	#$8000,$02(a1)

return_1FFB6:
		rts

		include	"Objects/Invisible Triggers/Spin Trigger Script.asm"

Pathswapper_Maps:
		include	"Objects/Invisible Triggers/Mappings.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	animate	level graphics
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AniArt_Load:				; XREF: VInt_UpdateArt; loc_F54
		tst.w	($FFFFF63A).w	; is the game paused?
		bne.s	AniArt_Pause	; if yes, branch
		cmp.b	#6,($FFFFD000+Obj_Routine).w
		bge.s	AniArt_Pause
		lea	($C00000).l,a6
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		add.w	d0,d0
		move.w	AniArt_Index(pc,d0.w),d0
		jmp	AniArt_Index(pc,d0.w)
; ===========================================================================

AniArt_Pause:
		rts	
; End of function AniArt_Load

; ===========================================================================
AniArt_Index:	dc.w AniArt_GHZ-AniArt_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Green Hill
; ---------------------------------------------------------------------------

AniArt_GHZ:				; XREF: AniArt_Index
		rts

AniArt_none:				; XREF: AniArt_Index
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	load (d1 - 1) 8x8 tiles
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTiles:
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		dbf	d1,LoadTiles
		rts	
; End of function LoadTiles

; ===========================================================================
; ---------------------------------------------------------------------------
; HUD Object code - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------
loc_40804:
    tst.w    ($FFFFFE20).w
    beq.s    loc_40820
    moveq    #0,d1
    btst    #3,($FFFFFE05).w
    bne.s    BranchTo_loc_40836
    cmpi.b    #9,($FFFFFE23).w
    bne.s    BranchTo_loc_40836
    addq.w    #2,d1

BranchTo_loc_40836
    bra.s    loc_40836
; ===========================================================================

loc_40820:
    moveq    #0,d1
    btst    #3,($FFFFFE05).w
    bne.s    loc_40836
    addq.w    #1,d1
    cmpi.b    #9,($FFFFFE23).w
    bne.s    loc_40836
    addq.w    #2,d1

loc_40836:
    move.w    #$90,d3
    move.w    #$108,d2
    lea    (Map_Obj21).l,a1
    movea.w    #$6CA,a3
    add.w    d1,d1
    adda.w    (a1,d1.w),a1
    moveq    #0,d1
    move.b    (a1)+,d1
    subq.b    #1,d1
    bmi.s    return_40858
    jsr    sub_D762

return_40858:
    rts
; ---------------------------------------------------------------------------
; Sprite mappings - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------
Map_obj21:
	include "_maps\obj21.asm"

; ---------------------------------------------------------------------------
; Add points subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AddPoints:
		move.b	#1,($FFFFFE1F).w ; set score counter to	update
		lea	($FFFFFFC0).w,a2
		lea	($FFFFFE26).w,a3
		add.l	d0,(a3)		; add d0*10 to the score
		move.l	#999999,d1
		cmp.l	(a3),d1		; is #999999 higher than the score?
		bhi.w	loc_1C6AC	; if yes, branch
		move.l	d1,(a3)		; reset	score to #999999
		move.l	d1,(a2)

loc_1C6AC:
		move.l	(a3),d0
		cmp.l	(a2),d0
		bcs.w	locret_1C6B6
		move.l	d0,(a2)

locret_1C6B6:
		rts	
; End of function AddPoints

; ---------------------------------------------------------------------------
; Subroutine to	update the HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HudUpdate:
        tst.w	($FFFFFE08).w 	; is debug mode active?
		bne.w	HudDebug	; if yes, branch
		tst.b	($FFFFFE1F).w	; does the score need updating?
		beq.s	Hud_ChkRings	; if not, branch
		clr.b	($FFFFFE1F).w
		move.l	#$5C800003,d0	; set VRAM address
		move.l	($FFFFFE26).w,d1 ; load	score
		bsr.w	Hud_Score

Hud_ChkRings:
		tst.b	($FFFFFE1D).w	; does the ring	counter	need updating?
		beq.s	Hud_ChkTime	; if not, branch
		bpl.s	loc_1C6E4
		bsr.w	Hud_LoadZero

loc_1C6E4:
		clr.b	($FFFFFE1D).w
		move.l	#$5F400003,d0	; set VRAM address
		moveq	#0,d1
		move.w	($FFFFFE20).w,d1 ; load	number of rings
		bsr.w	Hud_Rings

Hud_ChkTime:
		tst.b	($FFFFFE1E).w	; does the time	need updating?
		beq.s	Hud_ChkLives	; if not, branch
		tst.w	($FFFFF63A).w	; is the game paused?
		bne.s	Hud_ChkLives	; if yes, branch
		lea	($FFFFFE22).w,a1
		cmpi.l	#$93B3B,(a1)+	; is the time 9.59?
		beq.s	TimeOver	; if yes, branch
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.s	Hud_ChkLives
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.s	loc_1C734
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#9,(a1)
		bcs.s	loc_1C734
		move.b	#9,(a1)

loc_1C734:
		move.l	#$5E400003,d0
		moveq	#0,d1
		move.b	($FFFFFE23).w,d1 ; load	minutes
		bsr.w	Hud_Mins
		move.l	#$5EC00003,d0
		moveq	#0,d1
		move.b	($FFFFFE24).w,d1 ; load	seconds
		bsr.w	Hud_Secs

Hud_ChkLives:
		tst.b	($FFFFFE1C).w	; does the lives counter need updating?
		beq.s	Hud_ChkBonus	; if not, branch
		clr.b	($FFFFFE1C).w
		bsr.w	Hud_Lives

Hud_ChkBonus:
		tst.b	($FFFFF7D6).w	; do time/ring bonus counters need updating?
		beq.s	Hud_End		; if not, branch
		clr.b	($FFFFF7D6).w
		move.l	#$6E000002,($C00004).l
		moveq	#0,d1
		move.w	($FFFFF7D2).w,d1 ; load	time bonus
		bsr.w	Hud_TimeRingBonus
		moveq	#0,d1
		move.w	($FFFFF7D4).w,d1 ; load	ring bonus
		bsr.w	Hud_TimeRingBonus

Hud_End:
		rts	
; ===========================================================================

TimeOver:				; XREF: Hud_ChkTime
		clr.b	($FFFFFE1E).w
		lea	($FFFFD000).w,a0
		movea.l	a0,a2
		bsr.w	KillSonic
		move.b	#1,($FFFFFE1A).w
		rts	
; ===========================================================================

HudDebug:				; XREF: HudUpdate
		bsr.w	HudDb_XY
		tst.b	($FFFFFE1D).w	; does the ring	counter	need updating?
		beq.s	HudDb_ObjCount	; if not, branch
		bpl.s	HudDb_Rings
		bsr.w	Hud_LoadZero

HudDb_Rings:
		clr.b	($FFFFFE1D).w
		move.l	#$5F400003,d0	; set VRAM address
		moveq	#0,d1
		move.w	($FFFFFE20).w,d1 ; load	number of rings
		bsr.w	Hud_Rings

HudDb_ObjCount:
		move.l	#$5EC00003,d0	; set VRAM address
		moveq	#0,d1
		move.b	($FFFFF62C).w,d1 ; load	"number	of objects" counter
		bsr.w	Hud_Secs
		tst.b	($FFFFFE1C).w	; does the lives counter need updating?
		beq.s	HudDb_ChkBonus	; if not, branch
		clr.b	($FFFFFE1C).w
		bsr.w	Hud_Lives

HudDb_ChkBonus:
		tst.b	($FFFFF7D6).w	; does the ring/time bonus counter need	updating?
		beq.s	HudDb_End	; if not, branch
		clr.b	($FFFFF7D6).w
		move.l	#$6E000002,($C00004).l ; set VRAM address
		moveq	#0,d1
		move.w	($FFFFF7D2).w,d1 ; load	time bonus
		bsr.w	Hud_TimeRingBonus
		moveq	#0,d1
		move.w	($FFFFF7D4).w,d1 ; load	ring bonus
		bsr.w	Hud_TimeRingBonus

HudDb_End:
		rts	
; End of function HudUpdate

; ---------------------------------------------------------------------------
; Subroutine to	load "0" on the	HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_LoadZero:				; XREF: HudUpdate
		move.l	#$5F400003,($C00004).l
		lea	Hud_TilesZero(pc),a2
		move.w	#2,d2
		bra.s	loc_1C83E
; End of function Hud_LoadZero

; ---------------------------------------------------------------------------
; Subroutine to	load uncompressed HUD patterns ("E", "0", colon)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Base:				; XREF: Level
		lea	($C00000).l,a6
		bsr.w	Hud_Lives
		move.l	#$5C400003,($C00004).l
		lea	Hud_TilesBase(pc),a2
		move.w	#$E,d2

loc_1C83E:				; XREF: Hud_LoadZero
		lea	Art_Hud(pc),a1

loc_1C842:
		move.w	#$F,d1
		move.b	(a2)+,d0
		bmi.s	loc_1C85E
		ext.w	d0
		lsl.w	#5,d0
		lea	(a1,d0.w),a3

loc_1C852:
		move.l	(a3)+,(a6)
		dbf	d1,loc_1C852

loc_1C858:
		dbf	d2,loc_1C842

		rts	
; ===========================================================================

loc_1C85E:
		move.l	#0,(a6)
		dbf	d1,loc_1C85E

		bra.s	loc_1C858
; End of function Hud_Base

; ===========================================================================
Hud_TilesBase:	dc.b $16, $FF, $FF, $FF, $FF, $FF, $FF,	0, 0, $14, 0, 0
Hud_TilesZero:	dc.b $FF, $FF, 0, 0
; ---------------------------------------------------------------------------
; Subroutine to	load debug mode	numbers	patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HudDb_XY:				; XREF: HudDebug
		move.l	#$5C400003,($C00004).l ; set VRAM address
		move.w	($FFFFF700).w,d1 ; load	camera x-position
		swap	d1
		move.w	($FFFFD008).w,d1 ; load	Sonic's x-position
		bsr.s	HudDb_XY2
		move.w	($FFFFF704).w,d1 ; load	camera y-position
		swap	d1
		move.w	($FFFFD00C).w,d1 ; load	Sonic's y-position
; End of function HudDb_XY


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HudDb_XY2:
		moveq	#7,d6
		lea	(Art_Text).l,a1

HudDb_XYLoop:
		rol.w	#4,d1
		move.w	d1,d2
		andi.w	#$F,d2
		cmpi.w	#$A,d2
		bcs.s	loc_1C8B2
		addq.w	#7,d2

loc_1C8B2:
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		swap	d1
		dbf	d6,HudDb_XYLoop	; repeat 7 more	times

		rts	
; End of function HudDb_XY2

; ---------------------------------------------------------------------------
; Subroutine to	load rings numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Rings:				; XREF: HudUpdate
		lea	(Hud_100).l,a2
		moveq	#2,d6
		bra.s	Hud_LoadArt
; End of function Hud_Rings

; ---------------------------------------------------------------------------
; Subroutine to	load score numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Score:				; XREF: HudUpdate
		lea	(Hud_100000).l,a2
		moveq	#5,d6

Hud_LoadArt:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_ScoreLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C8EC:
		sub.l	d3,d1
		bcs.s	loc_1C8F4
		addq.w	#1,d2
		bra.s	loc_1C8EC
; ===========================================================================

loc_1C8F4:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C8FE
		move.w	#1,d4

loc_1C8FE:
		tst.w	d4
		beq.s	loc_1C92C
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1C92C:
		addi.l	#$400000,d0
		dbf	d6,Hud_ScoreLoop

		rts	
; End of function Hud_Score
; ===========================================================================
; ---------------------------------------------------------------------------
; HUD counter sizes
; ---------------------------------------------------------------------------
Hud_100000:	dc.l 100000		; XREF: Hud_Score
Hud_10000:	dc.l 10000
Hud_1000:	dc.l 1000		; XREF: Hud_TimeRingBonus
Hud_100:	dc.l 100		; XREF: Hud_Rings
Hud_10:		dc.l 10			; XREF: ContScrCounter; Hud_Secs; Hud_Lives
Hud_1:		dc.l 1			; XREF: Hud_Mins

; ---------------------------------------------------------------------------
; Subroutine to	load time numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Mins:				; XREF: Hud_ChkTime
		lea	(Hud_1).l,a2
		moveq	#0,d6
		bra.s	loc_1C9BA
; End of function Hud_Mins


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Secs:				; XREF: Hud_ChkTime
		lea	(Hud_10).l,a2
		moveq	#1,d6

loc_1C9BA:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_TimeLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C9C4:
		sub.l	d3,d1
		bcs.s	loc_1C9CC
		addq.w	#1,d2
		bra.s	loc_1C9C4
; ===========================================================================

loc_1C9CC:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C9D6
		move.w	#1,d4

loc_1C9D6:
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		addi.l	#$400000,d0
		dbf	d6,Hud_TimeLoop

		rts	
; End of function Hud_Secs

; ---------------------------------------------------------------------------
; Subroutine to	load time/ring bonus numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_TimeRingBonus:			; XREF: Hud_ChkBonus
		lea	(Hud_1000).l,a2
		moveq	#3,d6
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_BonusLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1CA1E:
		sub.l	d3,d1
		bcs.s	loc_1CA26
		addq.w	#1,d2
		bra.s	loc_1CA1E
; ===========================================================================

loc_1CA26:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1CA30
		move.w	#1,d4

loc_1CA30:
		tst.w	d4
		beq.s	Hud_ClrBonus
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1CA5A:
		dbf	d6,Hud_BonusLoop ; repeat 3 more times

		rts	
; ===========================================================================

Hud_ClrBonus:
		moveq	#$F,d5

Hud_ClrBonusLoop:
		move.l	#0,(a6)
		dbf	d5,Hud_ClrBonusLoop

		bra.s	loc_1CA5A
; End of function Hud_TimeRingBonus

; ---------------------------------------------------------------------------
; Subroutine to	load uncompressed lives	counter	patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Lives:				; XREF: Hud_ChkLives
		move.l	#$7BA00003,d0	; set VRAM address
		moveq	#0,d1
		move.b	($FFFFFE12).w,d1 ; load	number of lives
		lea	(Hud_10).l,a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_LivesNums(pc),a1

Hud_LivesLoop:
		move.l	d0,4(a6)
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1CA90:
		sub.l	d3,d1
		bcs.s	loc_1CA98
		addq.w	#1,d2
		bra.s	loc_1CA90
; ===========================================================================

loc_1CA98:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1CAA2
		move.w	#1,d4

loc_1CAA2:
		tst.w	d4
		beq.s	Hud_ClrLives

loc_1CAA6:
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1CABC:
		addi.l	#$400000,d0
		dbf	d6,Hud_LivesLoop ; repeat 1 more time

		rts	
; ===========================================================================

Hud_ClrLives:
		tst.w	d6
		beq.s	loc_1CAA6
		moveq	#7,d5

Hud_ClrLivesLoop:
		move.l	#0,(a6)
		dbf	d5,Hud_ClrLivesLoop
		bra.s	loc_1CABC
; End of function Hud_Lives

; ===========================================================================
Art_Hud:	incbin	artunc\HUD.bin		; 8x16 pixel numbers on HUD
		even
Art_LivesNums:	incbin	artunc\livescnt.bin	; 8x8 pixel numbers on lives counter
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; When debug mode is currently in use
; ---------------------------------------------------------------------------

DebugMode:				; XREF: Obj01; Obj09
		moveq	#0,d0
		move.b	($FFFFFE08).w,d0
		move.w	Debug_Index(pc,d0.w),d1
		jmp	Debug_Index(pc,d1.w)
; ===========================================================================
Debug_Index:	dc.w Debug_Main-Debug_Index
		dc.w Debug_Skip-Debug_Index
; ===========================================================================

Debug_Main:				; XREF: Debug_Index
		addq.b	#2,($FFFFFE08).w
        clr.w   ($FFFFD000+$14).w ; Clear Inertia
        clr.w   ($FFFFD000+$12).w ; Clear X/Y Speed
        clr.w   ($FFFFD000+$10).w ; Clear X/Y Speed
		move.w	($FFFFF72C).w,($FFFFFEF0).w ; buffer level x-boundary
		move.w	($FFFFF726).w,($FFFFFEF2).w ; buffer level y-boundary
		move.w	#0,($FFFFF72C).w
		move.w	#$720,($FFFFF726).w
		andi.w	#$7FF,($FFFFD00C).w
		andi.w	#$7FF,($FFFFF704).w
		andi.w	#$3FF,($FFFFF70C).w
		move.b	#0,$1A(a0)
		move.b	#0,$1C(a0)
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0

Debug_UseList:
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		cmp.b	($FFFFFE06).w,d6
		bhi.s	loc_1CF9E
		move.b	#0,($FFFFFE06).w

loc_1CF9E:
		bsr.w	Debug_ShowItem
		move.b	#$C,($FFFFFE0A).w
		move.b	#1,($FFFFFE0B).w

Debug_Skip:				; XREF: Debug_Index
		moveq	#6,d0
		moveq	#0,d0
		move.b	($FFFFFE10).w,d0
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		bsr.w	Debug_Control
		jmp	DisplaySprite

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Debug_Control:
		moveq	#0,d4
		move.w	#1,d1
		move.b	($FFFFF605).w,d4
		andi.w	#$F,d4		; is up/down/left/right	pressed?
		bne.s	loc_1D018	; if yes, branch
		move.b	($FFFFF604).w,d0
		andi.w	#$F,d0
		bne.s	loc_1D000
		move.b	#$C,($FFFFFE0A).w
		move.b	#$F,($FFFFFE0B).w
		bra.w	Debug_BackItem
; ===========================================================================

loc_1D000:
		subq.b	#1,($FFFFFE0A).w
		bne.s	loc_1D01C
		move.b	#1,($FFFFFE0A).w
		addq.b	#1,($FFFFFE0B).w
		bne.s	loc_1D018
		move.b	#-1,($FFFFFE0B).w

loc_1D018:
		move.b	($FFFFF604).w,d4

loc_1D01C:
		moveq	#0,d1
		move.b	($FFFFFE0B).w,d1
		addq.w	#1,d1
		swap	d1
		asr.l	#4,d1
		move.l	$C(a0),d2
		move.l	8(a0),d3
		btst	#0,d4		; is up	being pressed?
		beq.s	loc_1D03C	; if not, branch
		sub.l	d1,d2
		bcc.s	loc_1D03C
		moveq	#0,d2

loc_1D03C:
		btst	#1,d4		; is down being	pressed?
		beq.s	loc_1D052	; if not, branch
		add.l	d1,d2
		cmpi.l	#$7FF0000,d2
		bcs.s	loc_1D052
		move.l	#$7FF0000,d2

loc_1D052:
		btst	#2,d4
		beq.s	loc_1D05E
		sub.l	d1,d3
		bcc.s	loc_1D05E
		moveq	#0,d3

loc_1D05E:
		btst	#3,d4
		beq.s	loc_1D066
		add.l	d1,d3

loc_1D066:
		move.l	d2,$C(a0)
		move.l	d3,8(a0)

Debug_BackItem:
		btst	#6,($FFFFF604).w ; is button A pressed?
		beq.s	Debug_MakeItem	; if not, branch
		btst	#5,($FFFFF605).w ; is button C pressed?
		beq.s	Debug_NextItem	; if not, branch
		subq.b	#1,($FFFFFE06).w ; go back 1 item
		bcc.s	Debug_NoLoop
		add.b	d6,($FFFFFE06).w
		bra.s	Debug_NoLoop
; ===========================================================================

Debug_NextItem:
		btst	#6,($FFFFF605).w ; is button A pressed?
		beq.s	Debug_MakeItem	; if not, branch
		addq.b	#1,($FFFFFE06).w ; go forwards 1 item
		cmp.b	($FFFFFE06).w,d6
		bhi.s	Debug_NoLoop
		move.b	#0,($FFFFFE06).w ; loop	back to	first item

Debug_NoLoop:
		bra.w	Debug_ShowItem
; ===========================================================================

Debug_MakeItem:
		btst	#5,($FFFFF605).w ; is button C pressed?
		beq.s	Debug_Exit	; if not, branch
		jsr	SingleObjLoad
		bne.s	Debug_Exit
        clr.b	($FFFFFC02).w    ; clear 1st entry in object state table
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	4(a0),0(a1)	; create object
		move.b	1(a0),1(a1)
		move.b	1(a0),$22(a1)
		andi.b	#$7F,$22(a1)
		moveq	#0,d0
		move.b	($FFFFFE06).w,d0
		lsl.w	#3,d0
		move.b	4(a2,d0.w),$28(a1)
		rts	
; ===========================================================================

Debug_Exit:
		btst	#4,($FFFFF605).w ; is button B pressed?
		beq.s	Debug_DoNothing	; if not, branch
		moveq	#0,d0
		move.w	d0,($FFFFFE08).w ; deactivate debug mode
        bsr.w	Hud_Base
        move.b	#1,($FFFFFE1D).w
        move.b	#1,($FFFFFE1F).w
		move.l	#Map_Sonic,($FFFFD004).w
		move.w	#$780,($FFFFD002).w
		move.b	d0,($FFFFD01C).w
		move.w	d0,$A(a0)
		move.w	d0,$E(a0)
		move.w	($FFFFFEF0).w,($FFFFF72C).w ; restore level boundaries
		move.w	($FFFFFEF2).w,($FFFFF726).w

Debug_DoNothing:
		rts	
; End of function Debug_Control


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Debug_ShowItem:				; XREF: Debug_Main
		moveq	#0,d0
		move.b	($FFFFFE06).w,d0
		lsl.w	#3,d0
		move.l	(a2,d0.w),4(a0)	; load mappings	for item
		move.w	6(a2,d0.w),2(a0) ; load	VRAM setting for item
		move.b	5(a2,d0.w),$1A(a0) ; load frame	number for item
		rts	
; End of function Debug_ShowItem

; ===========================================================================
; ---------------------------------------------------------------------------
; Debug	list pointers
; ---------------------------------------------------------------------------
DebugList:
	include "_inc\Debug list pointers.asm"

; ---------------------------------------------------------------------------
; Debug	list - Green Hill
; ---------------------------------------------------------------------------
Debug_GHZ:
	include "_inc\Debug list - GHZ.asm"

; ---------------------------------------------------------------------------
; Main level load blocks
; ---------------------------------------------------------------------------
MainLoadBlocks:
	include "_inc\Main level load blocks.asm"

; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------
ArtLoadCues:
	include "_inc\Pattern load cues.asm"

Nem_SegaLogo:	incbin	artnem\segalogo.bin	; large Sega logo
		even
Eni_SegaLogo:	incbin	mapeni\segalogo.bin	; large Sega logo (mappings)
		even
Eni_Title:	incbin	mapeni\titlescr.bin	; title screen foreground (mappings)
		even
Nem_TitleFg:	incbin	artnem\titlefor.bin	; title screen foreground
		even
; ---------------------------------------------------------------------------
; Sprite mappings - Sonic
; ---------------------------------------------------------------------------
Map_Sonic:
	include "_maps\Sonic.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	loading	array for Sonic
; ---------------------------------------------------------------------------
SonicDynPLC:
	include "_inc\Sonic dynamic pattern load cues.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
Art_Sonic:	incbin	artunc\sonic.bin	; Sonic
		even
Art_Dust	incbin	artunc\spindust.bin
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Shield:	incbin	artnem\shield.bin	; shield
		even
Nem_Stars:	incbin	artnem\invstars.bin	; invincibility stars
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Swing:	incbin	artnem\ghzswing.bin	; GHZ swinging platform
		even
Nem_Bridge:	incbin	artnem\ghzbridg.bin	; GHZ bridge
		even
Nem_Spikes:	incbin	artnem\spikes.bin	; spikes
		even
Nem_GhzWall1:	incbin	artnem\ghzwall1.bin
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
Nem_Bumper:	incbin	artnem\syzbumpe.bin	; SYZ bumper
		even
Nem_LzSwitch:	incbin	artnem\switch.bin	; LZ/SYZ/SBZ switch
		even
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_Motobug:	incbin	artnem\motobug.bin	; moto bug
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	incbin	artnem\ttlcards.bin	; title cards
		even
Nem_Hud:	incbin	artnem\hud.bin		; HUD (rings, time, score)
		even
Nem_Lives:	incbin	artnem\lifeicon.bin	; life counter icon
		even
Nem_Ring:	incbin	artnem\rings.bin	; rings
		even
Nem_Monitors:	incbin	artnem\monitors.bin	; monitors
		even
Nem_Explode:	incbin	artnem\explosio.bin	; explosion
		even
Nem_Points:	incbin	artnem\points.bin	; points from destroyed enemy or object
		even
Nem_GameOver:	incbin	artnem\gameover.bin	; game over / time over
		even
Nem_HSpring:	incbin	"Objects/Springs/Vertical Tiles.nem"	; horizontal spring
		even
Nem_VSpring:	incbin	"Objects/Springs/Horizontal Tiles.nem"	; vertical spring
		even
Nem_SignPost:	incbin	artnem\signpost.bin	; end of level signpost
		even
Nem_Lamp:	incbin	artnem\lamppost.bin	; lamppost
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	incbin	artnem\rabbit.bin	; rabbit
		even
Nem_Chicken:	incbin	artnem\chicken.bin	; chicken
		even
Nem_BlackBird:	incbin	artnem\blackbrd.bin	; blackbird
		even
Nem_Seal:	incbin	artnem\seal.bin		; seal
		even
Nem_Pig:	incbin	artnem\pig.bin		; pig
		even
Nem_Flicky:	incbin	artnem\flicky.bin	; flicky
		even
Nem_Squirrel:	incbin	artnem\squirrel.bin	; squirrel
		even
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------

Blk16_GHZ:	incbin	map16\ghz.bin
		even
Kos_GHZ:	incbin	artkos\8x8ghz.bin	; GHZ primary patterns
		even
Blk256_GHZ:	incbin	map256\ghz.bin
		even

; ---------------------------------------------------------------------------
; Compressed graphics - bosses
; ---------------------------------------------------------------------------
Nem_Eggman:	incbin	artnem\bossmain.bin	; boss main patterns
		even
Nem_Prison:	incbin	artnem\prison.bin	; prison capsule
		even
Nem_Exhaust:	incbin	artnem\bossflam.bin	; boss exhaust flame
		even

; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	incbin	collide\anglemap.bin	; floor angle map
		even
CollArray1:	incbin	collide\carray_n.bin	; normal collision array
		even
CollArray2:	incbin	collide\carray_r.bin	; rotated collision array
		even
Col_GHZ_1:	incbin	collide\ghz1.bin	; GHZ index 1
		even
Col_GHZ_2:	incbin	collide\ghz2.bin	; GHZ index 2
		even
; ---------------------------------------------------------------------------
; Level	layout index
; ---------------------------------------------------------------------------
Level_Index:	dc.l Level_GHZ1, Level_GHZbg, byte_68D70	; MJ: Table needs to be read in long-word as the layouts are now bigger
		dc.l Level_GHZ2, Level_GHZbg, byte_68E3C

Level_GHZ1:	incbin	levels\ghz1.bin
		even
byte_68D70:	dc.b 0,	0, 0, 0
Level_GHZ2:	incbin	levels\ghz2.bin
		even
byte_68E3C:	dc.b 0,	0, 0, 0
Level_GHZbg:	incbin	levels\ghzbg.bin
		even

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:	dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0
ObjPos_GHZ1:	incbin	objpos\ghz1.bin
		even
ObjPos_GHZ2:	incbin	objpos\ghz2.bin
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0
; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
RingPos_Index:	dc.w Rings_GHZ1-RingPos_Index, Rings_Null-RingPos_Index
		dc.w Rings_GHZ2-RingPos_Index, Rings_Null-RingPos_Index
Rings_GHZ1:	incbin	"Ring Layouts/ghz1_INDIVIDUAL.bin"
		even
Rings_GHZ2:	incbin	"Ring Layouts/ghz2_INDIVIDUAL.bin"
		even
Rings_Null:	dc.b $FF, $FF, 0, 0

; ---------------------------------------------------------------------------

Go_SoundTypes:	dc.l SoundTypes		; XREF: Sound_Play
Go_SoundD0:	dc.l SoundD0Index	; XREF: Sound_D0toDF
Go_MusicIndex:	dc.l MusicIndex		; XREF: Sound_81to9F
Go_SoundIndex:	dc.l SoundIndex		; XREF: Sound_A0toCF
off_719A0:	dc.l byte_71A94		; XREF: Sound_81to9F
Go_PSGIndex:	dc.l PSG_Index		; XREF: sub_72926
; ---------------------------------------------------------------------------
; PSG instruments used in music
; ---------------------------------------------------------------------------
PSG_Index:	dc.l PSG1, PSG2, PSG3
		dc.l PSG4, PSG5, PSG6
		dc.l PSG7, PSG8, PSG9
PSG1:		incbin	sound\psg1.bin
PSG2:		incbin	sound\psg2.bin
PSG3:		incbin	sound\psg3.bin
PSG4:		incbin	sound\psg4.bin
PSG6:		incbin	sound\psg6.bin
PSG5:		incbin	sound\psg5.bin
PSG7:		incbin	sound\psg7.bin
PSG8:		incbin	sound\psg8.bin
PSG9:		incbin	sound\psg9.bin

byte_71A94:	dc.b 7,	$72, $73, $26, $15, 8, $FF, 5
; ---------------------------------------------------------------------------
; Music	Pointers
; ---------------------------------------------------------------------------
MusicIndex:	dc.l Music81, Music82
		dc.l Music83, Music84
		dc.l Music85, Music86
		dc.l Music87, Music88
		dc.l Music89, Music8A
		dc.l Music8B, Music8C
		dc.l Music8D, Music8E
		dc.l Music8F, Music90
		dc.l Music91, Music92
		dc.l Music93
; ---------------------------------------------------------------------------
; Type of sound	being played ($90 = music; $70 = normal	sound effect)
; ---------------------------------------------------------------------------
SoundTypes:	dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$90
		dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$80
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $68, $70, $70, $70, $60, $70,	$70
		dc.b $60, $70, $60, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $7F,	$60
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $70,	$80
		dc.b $80, $80, $80, $80, $80, $80, $80,	$80, $80, $80, $80, $80, $80, $80, $80,	$90
		dc.b $90, $90, $90, $90

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71B4C:				; XREF: loc_B10; PalToCRAM
		move.w	#$100,($A11100).l ; stop the Z80
		nop	
		nop	
		nop	

loc_71B5A:
		btst	#0,($A11100).l
		bne.s	loc_71B5A

		btst	#7,($A01FFD).l
		beq.s	loc_71B82
		move.w	#0,($A11100).l	; start	the Z80
		nop	
		nop	
		nop	
		nop	
		nop	
		bra.s	sub_71B4C
; ===========================================================================

loc_71B82:
		lea	($FFF000).l,a6
		clr.b	$E(a6)
		tst.b	3(a6)		; is music paused?
		bne.w	loc_71E50	; if yes, branch
		subq.b	#1,1(a6)
		bne.s	loc_71B9E
		jsr	sub_7260C(pc)

loc_71B9E:
		move.b	4(a6),d0
		beq.s	loc_71BA8
		jsr	sub_72504(pc)

loc_71BA8:
		tst.b	$24(a6)
		beq.s	loc_71BB2
		jsr	sub_7267C(pc)

loc_71BB2:
		tst.w	$A(a6)		; is music or sound being played?
		beq.s	loc_71BBC	; if not, branch
		jsr	Sound_Play(pc)

loc_71BBC:
		cmpi.b	#$80,9(a6)
		beq.s	loc_71BC8
		jsr	Sound_ChkValue(pc)

loc_71BC8:
		tst.b	($FFFFC901).w
		beq.s	@cont
		subq.b	#1,($FFFFC901).w
		
@cont:
		lea	$40(a6),a5
		tst.b	(a5)
		bpl.s	loc_71BD4
		jsr	sub_71C4E(pc)

loc_71BD4:
		clr.b	8(a6)
		moveq	#5,d7

loc_71BDA:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BE6
		jsr	sub_71CCA(pc)

loc_71BE6:
		dbf	d7,loc_71BDA

		moveq	#2,d7

loc_71BEC:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BF8
		jsr	sub_72850(pc)

loc_71BF8:
		dbf	d7,loc_71BEC

		move.b	#$80,$E(a6)
		moveq	#2,d7

loc_71C04:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C10
		jsr	sub_71CCA(pc)

loc_71C10:
		dbf	d7,loc_71C04

		moveq	#2,d7

loc_71C16:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C22
		jsr	sub_72850(pc)

loc_71C22:
		dbf	d7,loc_71C16
		move.b	#$40,$E(a6)
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C38
		jsr	sub_71CCA(pc)

loc_71C38:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C44
		jsr	sub_72850(pc)

loc_71C44:
		move.w	#0,($A11100).l ; start the Z80
		btst	#6,($FFFFFFF8).w ; is Megadrive PAL?
		beq.s	@end ; if not, branch
		cmpi.b	#5,($FFFFFFBF).w ; 5th frame?
		bne.s	@end ; if not, branch
		move.b	#0,($FFFFFFBF).w ; reset counter
		bra.w	sub_71B4C ; run sound driver again

@end:
		addq.b	#1,($FFFFFFBF).w ; add 1 to frame count
		rts
; End of function sub_71B4C


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71C4E:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	locret_71CAA
		move.b	#$80,8(a6)
		movea.l	4(a5),a4

loc_71C5E:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71C6E
		jsr	sub_72A5A(pc)
		bra.s	loc_71C5E
; ===========================================================================

loc_71C6E:
		tst.b	d5
		bpl.s	loc_71C84
		move.b	d5,$10(a5)
		move.b	(a4)+,d5
		bpl.s	loc_71C84
		subq.w	#1,a4
		move.b	$F(a5),$E(a5)
		bra.s	loc_71C88
; ===========================================================================

loc_71C84:
		jsr	sub_71D40(pc)

loc_71C88:
		move.l	a4,4(a5)
		btst	#2,(a5)
		bne.s	locret_71CAA
		moveq	#0,d0
		move.b	$10(a5),d0
		cmpi.b	#$80,d0
		beq.s	locret_71CAA
		btst	#3,d0
		bne.s	loc_71CAC
		move.b	d0,($A01FFF).l

locret_71CAA:
		rts	
; ===========================================================================

loc_71CAC:
		subi.b	#$88,d0
		move.b	byte_71CC4(pc,d0.w),d0
		move.b	d0,($A000EA).l
		move.b	#$83,($A01FFF).l
		rts	
; End of function sub_71C4E

; ===========================================================================
byte_71CC4:	dc.b $12, $15, $1C, $1D, $FF, $FF

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CCA:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_71CE0
		bclr	#4,(a5)
		jsr	sub_71CEC(pc)
		jsr	sub_71E18(pc)
		bra.w	loc_726E2
; ===========================================================================

loc_71CE0:
		jsr	sub_71D9E(pc)
		jsr	sub_71DC6(pc)
		bra.w	loc_71E24
; End of function sub_71CCA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CEC:				; XREF: sub_71CCA
		movea.l	4(a5),a4
		bclr	#1,(a5)

loc_71CF4:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71D04
		jsr	sub_72A5A(pc)
		bra.s	loc_71CF4
; ===========================================================================

loc_71D04:
		jsr	sub_726FE(pc)
		tst.b	d5
		bpl.s	loc_71D1A
		jsr	sub_71D22(pc)
		move.b	(a4)+,d5
		bpl.s	loc_71D1A
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_71D1A:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_71CEC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D22:				; XREF: sub_71CEC
		subi.b	#$80,d5
		beq.s	loc_71D58
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_72790(pc),a0
		move.w	(a0,d5.w),d6
		move.w	d6,$10(a5)
		rts	
; End of function sub_71D22


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D40:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		move.b	d5,d0
		move.b	2(a5),d1

loc_71D46:
		subq.b	#1,d1
		beq.s	loc_71D4E
		add.b	d5,d0
		bra.s	loc_71D46
; ===========================================================================

loc_71D4E:
		move.b	d0,$F(a5)
		move.b	d0,$E(a5)
		rts	
; End of function sub_71D40

; ===========================================================================

loc_71D58:				; XREF: sub_71D22
		bset	#1,(a5)
		clr.w	$10(a5)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D60:				; XREF: sub_71CEC; sub_72878; sub_728AC
		move.l	a4,4(a5)
		move.b	$F(a5),$E(a5)
		btst	#4,(a5)
		bne.s	locret_71D9C
		move.b	$13(a5),$12(a5)
		clr.b	$C(a5)
		btst	#3,(a5)
		beq.s	locret_71D9C
		movea.l	$14(a5),a0
		move.b	(a0)+,$18(a5)
		move.b	(a0)+,$19(a5)
		move.b	(a0)+,$1A(a5)
		move.b	(a0)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)

locret_71D9C:
		rts	
; End of function sub_71D60


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D9E:				; XREF: sub_71CCA; sub_72850
		tst.b	$12(a5)
		beq.s	locret_71DC4
		subq.b	#1,$12(a5)
		bne.s	locret_71DC4
		bset	#1,(a5)
		tst.b	1(a5)
		bmi.w	loc_71DBE
		jsr	sub_726FE(pc)
		addq.w	#4,sp
		rts	
; ===========================================================================

loc_71DBE:
		jsr	sub_729A0(pc)
		addq.w	#4,sp

locret_71DC4:
		rts	
; End of function sub_71D9E


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71DC6:				; XREF: sub_71CCA; sub_72850
		addq.w	#4,sp
		btst	#3,(a5)
		beq.s	locret_71E16
		tst.b	$18(a5)
		beq.s	loc_71DDA
		subq.b	#1,$18(a5)
		rts	
; ===========================================================================

loc_71DDA:
		subq.b	#1,$19(a5)
		beq.s	loc_71DE2
		rts	
; ===========================================================================

loc_71DE2:
		movea.l	$14(a5),a0
		move.b	1(a0),$19(a5)
		tst.b	$1B(a5)
		bne.s	loc_71DFE
		move.b	3(a0),$1B(a5)
		neg.b	$1A(a5)
		rts	
; ===========================================================================

loc_71DFE:
		subq.b	#1,$1B(a5)
		move.b	$1A(a5),d6
		ext.w	d6
		add.w	$1C(a5),d6
		move.w	d6,$1C(a5)
		add.w	$10(a5),d6
		subq.w	#4,sp

locret_71E16:
		rts	
; End of function sub_71DC6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71E18:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_71E48
		move.w	$10(a5),d6
		beq.s	loc_71E4A

loc_71E24:				; XREF: sub_71CCA
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_71E48
		move.w	d6,d1
		lsr.w	#8,d1
		move.b	#-$5C,d0
		jsr	sub_72722(pc)
		move.b	d6,d1
		move.b	#-$60,d0
		jsr	sub_72722(pc)

locret_71E48:
		rts	
; ===========================================================================

loc_71E4A:
		bset	#1,(a5)
		rts	
; End of function sub_71E18

; ===========================================================================

loc_71E50:				; XREF: sub_71B4C
		bmi.s	loc_71E94
		cmpi.b	#2,3(a6)
		beq.w	loc_71EFE
		move.b	#2,3(a6)
		moveq	#2,d3
		move.b	#-$4C,d0
		moveq	#0,d1

loc_71E6A:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.b	#1,d0
		dbf	d3,loc_71E6A

		moveq	#2,d3
		moveq	#$28,d0

loc_71E7C:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_71E7C

		jsr	sub_729B6(pc)
		bra.w	loc_71C44
; ===========================================================================

loc_71E94:				; XREF: loc_71E50
		clr.b	3(a6)
		moveq	#$30,d3
		lea	$40(a6),a5
		moveq	#6,d4

loc_71EA0:
		btst	#7,(a5)
		beq.s	loc_71EB8
		btst	#2,(a5)
		bne.s	loc_71EB8
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EB8:
		adda.w	d3,a5
		dbf	d4,loc_71EA0

		lea	$220(a6),a5
		moveq	#2,d4

loc_71EC4:
		btst	#7,(a5)
		beq.s	loc_71EDC
		btst	#2,(a5)
		bne.s	loc_71EDC
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EDC:
		adda.w	d3,a5
		dbf	d4,loc_71EC4

		lea	$340(a6),a5
		btst	#7,(a5)
		beq.s	loc_71EFE
		btst	#2,(a5)
		bne.s	loc_71EFE
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EFE:
		bra.w	loc_71C44

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_Play:				; XREF: sub_71B4C
		movea.l	(Go_SoundTypes).l,a0
		lea	$A(a6),a1	; load music track number
		move.b	0(a6),d3
		moveq	#2,d4

loc_71F12:
		move.b	(a1),d0		; move track number to d0
		move.b	d0,d1
		clr.b	(a1)+
		subi.b	#$81,d0
		bcs.s	loc_71F3E
		cmpi.b	#$80,9(a6)
		beq.s	loc_71F2C
		move.b	d1,$A(a6)
		bra.s	loc_71F3E
; ===========================================================================

loc_71F2C:
		andi.w	#$7F,d0
		move.b	(a0,d0.w),d2
		cmp.b	d3,d2
		bcs.s	loc_71F3E
		move.b	d2,d3
		move.b	d1,9(a6)	; set music flag

loc_71F3E:
		dbf	d4,loc_71F12

		tst.b	d3
		bmi.s	locret_71F4A
		move.b	d3,0(a6)

locret_71F4A:
		rts	
; End of function Sound_Play


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_ChkValue:				; XREF: sub_71B4C
		moveq	#0,d7
		move.b	9(a6),d7
		beq.w	Sound_E4
		bpl.s	locret_71F8C
		move.b	#$80,9(a6)	; reset	music flag
		cmpi.b	#$9F,d7
		bls.w	Sound_81to9F	; music	$81-$9F
		cmpi.b	#$A0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$CF,d7
		bls.w	Sound_A0toCF	; sound	$A0-$CF
		cmpi.b	#$D0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$D1,d7
		bcs.w	Sound_D0toDF	; sound	$D0
		cmpi.b	#$DF,d7
		blo.w	Sound_D1toDF	; sound	$D1-$DF
		cmpi.b	#$E4,d7
		bls.s	Sound_E0toE4	; sound	$E0-$E4

locret_71F8C:
		rts	
; ===========================================================================

Sound_E0toE4:				; XREF: Sound_ChkValue
		subi.b	#$E0,d7
		lsl.w	#2,d7
		jmp	Sound_ExIndex(pc,d7.w)
; ===========================================================================

Sound_ExIndex:
		bra.w	Sound_E0
; ===========================================================================
		bra.w	Sound_E1
; ===========================================================================
		bra.w	Sound_E2
; ===========================================================================
		bra.w	Sound_E3
; ===========================================================================
		bra.w	Sound_E4
; ===========================================================================
; ---------------------------------------------------------------------------
; Play "Say-gaa" PCM sound
; ---------------------------------------------------------------------------

Sound_E1:				  
		lea	(SegaPCM).l,a2			; Load the SEGA PCM sample into a2. It's important that we use a2 since a0 and a1 are going to be used up ahead when reading the joypad ports 
		move.l	#(SegaPCM_End-SegaPCM),d3			; Load the size of the SEGA PCM sample into d3 
		move.b	#$2A,($A04000).l		; $A04000 = $2A -> Write to DAC channel	  
PlayPCM_Loop:	  
		move.b	(a2)+,($A04001).l		; Write the PCM data (contained in a2) to $A04001 (YM2612 register D0) 
		move.w	#$14,d0				; Write the pitch ($14 in this case) to d0 
		dbf	d0,*				; Decrement d0; jump to itself if not 0. (for pitch control, avoids playing the sample too fast)  
		sub.l	#1,d3				; Subtract 1 from the PCM sample size 
		beq.s	return_PlayPCM			; If d3 = 0, we finished playing the PCM sample, so stop playing, leave this loop, and unfreeze the 68K 
		lea	($FFFFF604).w,a0		; address where JoyPad states are written 
		lea	($A10003).l,a1			; address where JoyPad states are read from 
		jsr	(Joypad_Read).w			; Read only the first joypad port. It's important that we do NOT do the two ports, we don't have the cycles for that 
		btst	#7,($FFFFF604).w		; Check for Start button 
		bne.s	return_PlayPCM			; If start is pressed, stop playing, leave this loop, and unfreeze the 68K 
		bra.s	PlayPCM_Loop			; Otherwise, continue playing PCM sample 
return_PlayPCM: 
		addq.w	#4,sp 
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Play music track $81-$9F
; ---------------------------------------------------------------------------

Sound_81to9F:				; XREF: Sound_ChkValue
		cmpi.b	#$88,d7		; is "extra life" music	played?
		bne.s	loc_72024	; if not, branch
		tst.b	$27(a6)
		bne.w	loc_721B6
		lea	$40(a6),a5
		moveq	#9,d0

loc_71FE6:
		bclr	#2,(a5)
		adda.w	#$30,a5
		dbf	d0,loc_71FE6

		lea	$220(a6),a5
		moveq	#5,d0

loc_71FF8:
		bclr	#7,(a5)
		adda.w	#$30,a5
		dbf	d0,loc_71FF8
		clr.b	0(a6)
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72012:
		move.l	(a0)+,(a1)+
		dbf	d0,loc_72012

		move.b	#$80,$27(a6)
		clr.b	0(a6)
		bra.s	loc_7202C
; ===========================================================================

loc_72024:
		clr.b	$27(a6)
		clr.b	$26(a6)

loc_7202C:
		jsr	sub_725CA(pc)
		movea.l	(off_719A0).l,a4
		subi.b	#$81,d7
		move.b	(a4,d7.w),$29(a6)
		movea.l	(Go_MusicIndex).l,a4
		lsl.w	#2,d7
		movea.l	(a4,d7.w),a4
		moveq	#0,d0
		move.w	(a4),d0
		add.l	a4,d0
		move.l	d0,$18(a6)
		move.b	5(a4),d0
		move.b	d0,$28(a6)
		tst.b	$2A(a6)
		beq.s	loc_72068
		move.b	$29(a6),d0

loc_72068:
		move.b	d0,2(a6)
		move.b	d0,1(a6)
		moveq	#0,d1
		movea.l	a4,a3
		addq.w	#6,a4
		move.b	4(a3),d4
		moveq	#$30,d6
		move.b	#1,d5
		moveq	#0,d7
		move.b	2(a3),d7
		beq.w	loc_72114
		subq.b	#1,d7
		move.b	#-$40,d1
		lea	$40(a6),a1
		lea	byte_721BA(pc),a2

loc_72098:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d1,$A(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		adda.w	d6,a1
		dbf	d7,loc_72098
		cmpi.b	#7,2(a3)
		bne.s	loc_720D8
		moveq	#$2B,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		bra.w	loc_72114
; ===========================================================================

loc_720D8:
		moveq	#$28,d0
		moveq	#6,d1
		jsr	sub_7272E(pc)
		move.b	#$42,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4A,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$46,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4E,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#-$4A,d0
		move.b	#-$40,d1
		jsr	sub_72764(pc)

loc_72114:
		moveq	#0,d7
		move.b	3(a3),d7
		beq.s	loc_72154
		subq.b	#1,d7
		lea	$190(a6),a1
		lea	byte_721C2(pc),a2

loc_72126:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		move.b	(a4)+,d0
		move.b	(a4)+,$B(a1)
		adda.w	d6,a1
		dbf	d7,loc_72126

loc_72154:
		lea	$220(a6),a1
		moveq	#5,d7

loc_7215A:
		tst.b	(a1)
		bpl.w	loc_7217C
		moveq	#0,d0
		move.b	1(a1),d0
		bmi.s	loc_7216E
		subq.b	#2,d0
		lsl.b	#2,d0
		bra.s	loc_72170
; ===========================================================================

loc_7216E:
		lsr.b	#3,d0

loc_72170:
		lea	dword_722CC(pc),a0
		movea.l	(a0,d0.w),a0
		bset	#2,(a0)

loc_7217C:
		adda.w	d6,a1
		dbf	d7,loc_7215A

		tst.w	$340(a6)
		bpl.s	loc_7218E
		bset	#2,$100(a6)

loc_7218E:
		tst.w	$370(a6)
		bpl.s	loc_7219A
		bset	#2,$1F0(a6)

loc_7219A:
		lea	$70(a6),a5
		moveq	#5,d4

loc_721A0:
		jsr	sub_726FE(pc)
		adda.w	d6,a5
		dbf	d4,loc_721A0
		moveq	#2,d4

loc_721AC:
		jsr	sub_729A0(pc)
		adda.w	d6,a5
		dbf	d4,loc_721AC

loc_721B6:
		addq.w	#4,sp
		rts	
; ===========================================================================
byte_721BA:	dc.b 6,	0, 1, 2, 4, 5, 6, 0
		even
byte_721C2:	dc.b $80, $A0, $C0, 0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Play normal sound effect
; ---------------------------------------------------------------------------
Sound_D1toDF:
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		clr.b	($FFFFC900).w
		cmp.b	#$D1,d7		; is this the Spin Dash sound?
		bne.s	@cont3	; if not, branch
		move.w	d0,-(sp)
		move.b	($FFFFC902).w,d0	; store extra frequency
		tst.b	($FFFFC901).w	; is the Spin Dash timer active?
		bne.s	@cont1		; if it is, branch
		move.b	#-1,d0		; otherwise, reset frequency (becomes 0 on next line)
		
@cont1:
		addq.b	#1,d0
		cmp.b	#$C,d0		; has the limit been reached?
		bcc.s	@cont2		; if it has, branch
		move.b	d0,($FFFFC902).w	; otherwise, set new frequency
		
@cont2:
		move.b	#1,($FFFFC900).w	; set flag
		move.b	#60,($FFFFC901).w	; set timer
		move.w	(sp)+,d0
		
@cont3:
		movea.l	(Go_SoundIndex).l,a0
		sub.b	#$A1,d7
		bra	SoundEffects_Common

Sound_A0toCF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		clr.b	($FFFFC900).w
		cmpi.b	#$B5,d7		; is ring sound	effect played?
		bne.s	Sound_notB5	; if not, branch
		tst.b	$2B(a6)
		bne.s	loc_721EE
		move.b	#$CE,d7		; play ring sound in left speaker

loc_721EE:
		bchg	#0,$2B(a6)	; change speaker

Sound_notB5:
		cmpi.b	#$A7,d7		; is "pushing" sound played?
		bne.s	Sound_notA7	; if not, branch
		tst.b	$2C(a6)
		bne.w	locret_722C4
		move.b	#$80,$2C(a6)

Sound_notA7:
		movea.l	(Go_SoundIndex).l,a0
		subi.b	#$A0,d7
SoundEffects_Common:		
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d1
		move.w	(a1)+,d1
		add.l	a3,d1
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72228:
		moveq	#0,d3
		move.b	1(a1),d3
		move.b	d3,d4
		bmi.s	loc_72244
		subq.w	#2,d3
		lsl.w	#2,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		bra.s	loc_7226E
; ===========================================================================

loc_72244:
		lsr.w	#3,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		cmpi.b	#$C0,d4
		bne.s	loc_7226E
		move.b	d4,d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l
		bchg	#5,d0
		move.b	d0,($C00011).l

loc_7226E:
		lea	dword_722EC(pc),a5
		movea.l	(a5,d3.w),a5
		movea.l	a5,a2
		moveq	#$B,d0

loc_72276:
		clr.l	(a2)+
		dbf	d0,loc_72276

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		tst.b	($FFFFC900).w	; is the Spin Dash sound playing?
		beq.s	@cont		; if not, branch
		move.w	d0,-(sp)
		move.b	($FFFFC902).w,d0
		add.b	d0,8(a5)
		move.w	(sp)+,d0
		
@cont:
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_722A8
		move.b	#$C0,$A(a5)
		move.l	d1,$20(a5)

loc_722A8:
		dbf	d7,loc_72228

		tst.b	$250(a6)
		bpl.s	loc_722B8
		bset	#2,$340(a6)

loc_722B8:
		tst.b	$310(a6)
		bpl.s	locret_722C4
		bset	#2,$370(a6)

locret_722C4:
		rts	
; ===========================================================================

loc_722C6:
		clr.b	0(a6)
		rts	
; ===========================================================================
dword_722CC:	dc.l $FFF0D0
		dc.l 0
		dc.l $FFF100
		dc.l $FFF130
		dc.l $FFF190
		dc.l $FFF1C0
		dc.l $FFF1F0
		dc.l $FFF1F0
dword_722EC:	dc.l $FFF220
		dc.l 0
		dc.l $FFF250
		dc.l $FFF280
		dc.l $FFF2B0
		dc.l $FFF2E0
		dc.l $FFF310
		dc.l $FFF310
; ===========================================================================
; ---------------------------------------------------------------------------
; Play GHZ waterfall sound
; ---------------------------------------------------------------------------

Sound_D0toDF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	locret_723C6
		tst.b	4(a6)
		bne.w	locret_723C6
		tst.b	$24(a6)
		bne.w	locret_723C6
		movea.l	(Go_SoundD0).l,a0
		subi.b	#$D0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,$20(a6)
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72348:
		move.b	1(a1),d4
		bmi.s	loc_7235A
		bset	#2,$100(a6)
		lea	$340(a6),a5
		bra.s	loc_72364
; ===========================================================================

loc_7235A:
		bset	#2,$1F0(a6)
		lea	$370(a6),a5

loc_72364:
		movea.l	a5,a2
		moveq	#$B,d0

loc_72368:
		clr.l	(a2)+
		dbf	d0,loc_72368

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_72396
		move.b	#$C0,$A(a5)

loc_72396:
		dbf	d7,loc_72348

		tst.b	$250(a6)
		bpl.s	loc_723A6
		bset	#2,$340(a6)

loc_723A6:
		tst.b	$310(a6)
		bpl.s	locret_723C6
		bset	#2,$370(a6)
		ori.b	#$1F,d4
		move.b	d4,($C00011).l
		bchg	#5,d4
		move.b	d4,($C00011).l

locret_723C6:
		rts	
; End of function Sound_ChkValue

; ===========================================================================
		dc.l $FFF100
		dc.l $FFF1F0
		dc.l $FFF250
		dc.l $FFF310
		dc.l $FFF340
		dc.l $FFF370

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut1:				; XREF: Sound_E0
		clr.b	0(a6)
		lea	$220(a6),a5
		moveq	#5,d7

loc_723EA:
		tst.b	(a5)
		bpl.w	loc_72472
		bclr	#7,(a5)
		moveq	#0,d3
		move.b	1(a5),d3
		bmi.s	loc_7243C
		jsr	sub_726FE(pc)
		cmpi.b	#4,d3
		bne.s	loc_72416
		tst.b	$340(a6)
		bpl.s	loc_72416
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72428
; ===========================================================================

loc_72416:
		subq.b	#2,d3
		lsl.b	#2,d3
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		movea.l	(a0,d3.w),a5
		movea.l	$18(a6),a1

loc_72428:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5
		bra.s	loc_72472
; ===========================================================================

loc_7243C:
		jsr	sub_729A0(pc)
		lea	$370(a6),a0
		cmpi.b	#$E0,d3
		beq.s	loc_7245A
		cmpi.b	#$C0,d3
		beq.s	loc_7245A
		lsr.b	#3,d3
		lea	dword_722CC(pc),a0
		movea.l	(a0,d3.w),a0

loc_7245A:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72472
		move.b	$1F(a0),($C00011).l

loc_72472:
		adda.w	#$30,a5
		dbf	d7,loc_723EA

		rts	
; End of function Snd_FadeOut1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut2:				; XREF: Sound_E0
		lea	$340(a6),a5
		tst.b	(a5)
		bpl.s	loc_724AE
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	loc_724AE
		jsr	loc_7270A(pc)
		lea	$100(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	loc_724AE
		movea.l	$18(a6),a1
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_724AE:
		lea	$370(a6),a5
		tst.b	(a5)
		bpl.s	locret_724E4
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	locret_724E4
		jsr	loc_729A6(pc)
		lea	$1F0(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	locret_724E4
		cmpi.b	#-$20,1(a5)
		bne.s	locret_724E4
		move.b	$1F(a5),($C00011).l

locret_724E4:
		rts	
; End of function Snd_FadeOut2

; ===========================================================================
; ---------------------------------------------------------------------------
; Fade out music
; ---------------------------------------------------------------------------

Sound_E0:				; XREF: Sound_ExIndex
		jsr	Snd_FadeOut1(pc)
		jsr	Snd_FadeOut2(pc)
		move.b	#3,6(a6)
		move.b	#$28,4(a6)
		clr.b	$40(a6)
		clr.b	$2A(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72504:				; XREF: sub_71B4C
		move.b	6(a6),d0
		beq.s	loc_72510
		subq.b	#1,6(a6)
		rts	
; ===========================================================================

loc_72510:
		subq.b	#1,4(a6)
		beq.w	Sound_E4
		move.b	#3,6(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_72524:
		tst.b	(a5)
		bpl.s	loc_72538
		addq.b	#1,9(a5)
		bpl.s	loc_72534
		bclr	#7,(a5)
		bra.s	loc_72538
; ===========================================================================

loc_72534:
		jsr	sub_72CB4(pc)

loc_72538:
		adda.w	#$30,a5
		dbf	d7,loc_72524

		moveq	#2,d7

loc_72542:
		tst.b	(a5)
		bpl.s	loc_72560
		addq.b	#1,9(a5)
		cmpi.b	#$10,9(a5)
		bcs.s	loc_72558
		bclr	#7,(a5)
		bra.s	loc_72560
; ===========================================================================

loc_72558:
		move.b	9(a5),d6
		jsr	sub_7296A(pc)

loc_72560:
		adda.w	#$30,a5
		dbf	d7,loc_72542

		rts	
; End of function sub_72504


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7256A:				; XREF: Sound_E4; sub_725CA
		moveq	#2,d3
		moveq	#$28,d0

loc_7256E:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_7256E

		moveq	#$40,d0
		moveq	#$7F,d1
		moveq	#2,d4

loc_72584:
		moveq	#3,d3

loc_72586:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.w	#4,d0
		dbf	d3,loc_72586

		subi.b	#$F,d0
		dbf	d4,loc_72584

		rts	
; End of function sub_7256A

; ===========================================================================
; ---------------------------------------------------------------------------
; Stop music
; ---------------------------------------------------------------------------

Sound_E4:				; XREF: Sound_ChkValue; Sound_ExIndex; sub_72504
		moveq	#$2B,d0
		move.b	#$80,d1
		jsr	sub_7272E(pc)
		moveq	#$27,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		movea.l	a6,a0
		move.w	#$E3,d0

loc_725B6:
		clr.l	(a0)+
		dbf	d0,loc_725B6

		move.b	#$80,9(a6)	; set music to $80 (silence)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_725CA:				; XREF: Sound_ChkValue
		movea.l	a6,a0
		move.b	0(a6),d1
		move.b	$27(a6),d2
		move.b	$2A(a6),d3
		move.b	$26(a6),d4
		move.w	$A(a6),d5
		move.w	#$87,d0

loc_725E4:
		clr.l	(a0)+
		dbf	d0,loc_725E4

		move.b	d1,0(a6)
		move.b	d2,$27(a6)
		move.b	d3,$2A(a6)
		move.b	d4,$26(a6)
		move.w	d5,$A(a6)
		move.b	#$80,9(a6)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6
; End of function sub_725CA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7260C:				; XREF: sub_71B4C
		move.b	2(a6),1(a6)
		lea	$4E(a6),a0
		moveq	#$30,d0
		moveq	#9,d1

loc_7261A:
		addq.b	#1,(a0)
		adda.w	d0,a0
		dbf	d1,loc_7261A

		rts	
; End of function sub_7260C

; ===========================================================================
; ---------------------------------------------------------------------------
; Speed	up music
; ---------------------------------------------------------------------------

Sound_E2:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7263E
		move.b	$29(a6),2(a6)
		move.b	$29(a6),1(a6)
		move.b	#$80,$2A(a6)
		rts	
; ===========================================================================

loc_7263E:
		move.b	$3C9(a6),$3A2(a6)
		move.b	$3C9(a6),$3A1(a6)
		move.b	#$80,$3CA(a6)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Change music back to normal speed
; ---------------------------------------------------------------------------

Sound_E3:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7266A
		move.b	$28(a6),2(a6)
		move.b	$28(a6),1(a6)
		clr.b	$2A(a6)
		rts	
; ===========================================================================

loc_7266A:
		move.b	$3C8(a6),$3A2(a6)
		move.b	$3C8(a6),$3A1(a6)
		clr.b	$3CA(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7267C:				; XREF: sub_71B4C
		tst.b	$25(a6)
		beq.s	loc_72688
		subq.b	#1,$25(a6)
		rts	
; ===========================================================================

loc_72688:
		tst.b	$26(a6)
		beq.s	loc_726D6
		subq.b	#1,$26(a6)
		move.b	#2,$25(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_7269E:
		tst.b	(a5)
		bpl.s	loc_726AA
		subq.b	#1,9(a5)
		jsr	sub_72CB4(pc)

loc_726AA:
		adda.w	#$30,a5
		dbf	d7,loc_7269E
		moveq	#2,d7

loc_726B4:
		tst.b	(a5)
		bpl.s	loc_726CC
		subq.b	#1,9(a5)
		move.b	9(a5),d6
		cmpi.b	#$10,d6
		bcs.s	loc_726C8
		moveq	#$F,d6

loc_726C8:
		jsr	sub_7296A(pc)

loc_726CC:
		adda.w	#$30,a5
		dbf	d7,loc_726B4
		rts	
; ===========================================================================

loc_726D6:
		bclr	#2,$40(a6)
		clr.b	$24(a6)

		tst.b	$40(a6)					; is the DAC channel running?
		bpl.s	Resume_NoDAC				; if not, branch

		moveq	#$FFFFFFB6,d0				; prepare FM channel 3/6 L/R/AMS/FMS address
		move.b	$4A(a6),d1				; load DAC channel's L/R/AMS/FMS value
		jmp	sub_72764(pc)				; write to FM 6

Resume_NoDAC:
		rts
; End of function sub_7267C

; ===========================================================================

loc_726E2:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_726FC
		btst	#2,(a5)
		bne.s	locret_726FC
		moveq	#$28,d0
		move.b	1(a5),d1
		ori.b	#-$10,d1
		bra.w	sub_7272E
; ===========================================================================

locret_726FC:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_726FE:				; XREF: sub_71CEC; sub_71D9E; Sound_ChkValue; Snd_FadeOut1
		btst	#4,(a5)
		bne.s	locret_72714
		btst	#2,(a5)
		bne.s	locret_72714

loc_7270A:				; XREF: Snd_FadeOut2
		moveq	#$28,d0
		move.b	1(a5),d1
		bra.w	sub_7272E
; ===========================================================================

locret_72714:
		rts	
; End of function sub_726FE

; ===========================================================================

loc_72716:				; XREF: sub_72A5A
		btst	#2,(a5)
		bne.s	locret_72720
		bra.w	sub_72722
; ===========================================================================

locret_72720:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72722:				; XREF: sub_71E18; sub_72C4E; sub_72CB4
		btst	#2,1(a5)
		bne.s	loc_7275A
		add.b	1(a5),d0
; End of function sub_72722


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7272E:				; XREF: loc_71E6A
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_7272E
		move.b	d0,($A04000).l
		nop	
		nop	
		nop	

loc_72746:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_72746

		move.b	d1,($A04001).l
		rts	
; End of function sub_7272E

; ===========================================================================

loc_7275A:				; XREF: sub_72722
		move.b	1(a5),d2
		bclr	#2,d2
		add.b	d2,d0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72764:				; XREF: loc_71E6A; Sound_ChkValue; sub_7256A; sub_72764
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_72764
		move.b	d0,($A04002).l
		nop	
		nop	
		nop	

loc_7277C:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_7277C

		move.b	d1,($A04003).l
		rts	
; End of function sub_72764

; ===========================================================================
word_72790:	dc.w $25E, $284, $2AB, $2D3, $2FE, $32D, $35C, $38F, $3C5
		dc.w $3FF, $43C, $47C, $A5E, $A84, $AAB, $AD3, $AFE, $B2D
		dc.w $B5C, $B8F, $BC5, $BFF, $C3C, $C7C, $125E,	$1284
		dc.w $12AB, $12D3, $12FE, $132D, $135C,	$138F, $13C5, $13FF
		dc.w $143C, $147C, $1A5E, $1A84, $1AAB,	$1AD3, $1AFE, $1B2D
		dc.w $1B5C, $1B8F, $1BC5, $1BFF, $1C3C,	$1C7C, $225E, $2284
		dc.w $22AB, $22D3, $22FE, $232D, $235C,	$238F, $23C5, $23FF
		dc.w $243C, $247C, $2A5E, $2A84, $2AAB,	$2AD3, $2AFE, $2B2D
		dc.w $2B5C, $2B8F, $2BC5, $2BFF, $2C3C,	$2C7C, $325E, $3284
		dc.w $32AB, $32D3, $32FE, $332D, $335C,	$338F, $33C5, $33FF
		dc.w $343C, $347C, $3A5E, $3A84, $3AAB,	$3AD3, $3AFE, $3B2D
		dc.w $3B5C, $3B8F, $3BC5, $3BFF, $3C3C,	$3C7C

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72850:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_72866
		bclr	#4,(a5)
		jsr	sub_72878(pc)
		jsr	sub_728DC(pc)
		bra.w	loc_7292E
; ===========================================================================

loc_72866:
		jsr	sub_71D9E(pc)
		jsr	sub_72926(pc)
		jsr	sub_71DC6(pc)
		jsr	sub_728E2(pc)
		rts	
; End of function sub_72850


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72878:				; XREF: sub_72850
		bclr	#1,(a5)
		movea.l	4(a5),a4

loc_72880:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#$E0,d5
		bcs.s	loc_72890
		jsr	sub_72A5A(pc)
		bra.s	loc_72880
; ===========================================================================

loc_72890:
		tst.b	d5
		bpl.s	loc_728A4
		jsr	sub_728AC(pc)
		move.b	(a4)+,d5
		tst.b	d5
		bpl.s	loc_728A4
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_728A4:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_72878


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728AC:				; XREF: sub_72878
		subi.b	#$81,d5
		bcs.s	loc_728CA
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_729CE(pc),a0
		move.w	(a0,d5.w),$10(a5)
		bra.w	sub_71D60
; ===========================================================================

loc_728CA:
		bset	#1,(a5)
		move.w	#-1,$10(a5)
		jsr	sub_71D60(pc)
		bra.w	sub_729A0
; End of function sub_728AC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728DC:				; XREF: sub_72850
		move.w	$10(a5),d6
		bmi.s	loc_72920
; End of function sub_728DC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728E2:				; XREF: sub_72850
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_7291E
		btst	#1,(a5)
		bne.s	locret_7291E
		move.b	1(a5),d0
		cmpi.b	#$E0,d0
		bne.s	loc_72904
		move.b	#$C0,d0

loc_72904:
		move.w	d6,d1
		andi.b	#$F,d1
		or.b	d1,d0
		lsr.w	#4,d6
		andi.b	#$3F,d6
		move.b	d0,($C00011).l
		move.b	d6,($C00011).l

locret_7291E:
		rts	
; End of function sub_728E2

; ===========================================================================

loc_72920:				; XREF: sub_728DC
		bset	#1,(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72926:				; XREF: sub_72850
		tst.b	$B(a5)
		beq.w	locret_7298A

loc_7292E:				; XREF: sub_72850
		move.b	9(a5),d6
		moveq	#0,d0
		move.b	$B(a5),d0
		beq.s	sub_7296A
		movea.l	(Go_PSGIndex).l,a0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a0,d0.w),a0
		move.b	$C(a5),d0
		move.b	(a0,d0.w),d0
		addq.b	#1,$C(a5)
		btst	#7,d0
		beq.s	loc_72960
		cmpi.b	#$80,d0
		beq.s	loc_7299A

loc_72960:
		add.w	d0,d6
		cmpi.b	#$10,d6
		bcs.s	sub_7296A
		moveq	#$F,d6
; End of function sub_72926


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7296A:				; XREF: sub_72504; sub_7267C; sub_72926
		btst	#1,(a5)
		bne.s	locret_7298A
		btst	#2,(a5)
		bne.s	locret_7298A
		btst	#4,(a5)
		bne.s	loc_7298C

loc_7297C:
		or.b	1(a5),d6
		addi.b	#$10,d6
		move.b	d6,($C00011).l

locret_7298A:
		rts	
; ===========================================================================

loc_7298C:
		tst.b	$13(a5)
		beq.s	loc_7297C
		tst.b	$12(a5)
		bne.s	loc_7297C
		rts	
; End of function sub_7296A

; ===========================================================================

loc_7299A:				; XREF: sub_72926
		subq.b	#1,$C(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729A0:				; XREF: sub_71D9E; Sound_ChkValue; Snd_FadeOut1; sub_728AC
		btst	#2,(a5)
		bne.s	locret_729B4

loc_729A6:				; XREF: Snd_FadeOut2
		move.b	1(a5),d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l

locret_729B4:
		rts	
; End of function sub_729A0


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729B6:				; XREF: loc_71E7C
		lea	($C00011).l,a0
		move.b	#$9F,(a0)
		move.b	#$BF,(a0)
		move.b	#$DF,(a0)
		move.b	#$FF,(a0)
		rts	
; End of function sub_729B6

; ===========================================================================
word_729CE:	dc.w $356, $326, $2F9, $2CE, $2A5, $280, $25C, $23A, $21A
		dc.w $1FB, $1DF, $1C4, $1AB, $193, $17D, $167, $153, $140
		dc.w $12E, $11D, $10D, $FE, $EF, $E2, $D6, $C9,	$BE, $B4
		dc.w $A9, $A0, $97, $8F, $87, $7F, $78,	$71, $6B, $65
		dc.w $5F, $5A, $55, $50, $4B, $47, $43,	$40, $3C, $39
		dc.w $36, $33, $30, $2D, $2B, $28, $26,	$24, $22, $20
		dc.w $1F, $1D, $1B, $1A, $18, $17, $16,	$15, $13, $12
		dc.w $11, 0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72A5A:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		subi.w	#$E0,d5
		lsl.w	#2,d5
		jmp	loc_72A64(pc,d5.w)
; End of function sub_72A5A

; ===========================================================================

loc_72A64:
		bra.w	loc_72ACC
; ===========================================================================
		bra.w	loc_72AEC
; ===========================================================================
		bra.w	loc_72AF2
; ===========================================================================
		bra.w	loc_72AF8
; ===========================================================================
		bra.w	loc_72B14
; ===========================================================================
		bra.w	loc_72B9E
; ===========================================================================
		bra.w	loc_72BA4
; ===========================================================================
		bra.w	loc_72BAE
; ===========================================================================
		bra.w	loc_72BB4
; ===========================================================================
		bra.w	loc_72BBE
; ===========================================================================
		bra.w	loc_72BC6
; ===========================================================================
		bra.w	loc_72BD0
; ===========================================================================
		bra.w	loc_72BE6
; ===========================================================================
		bra.w	loc_72BEE
; ===========================================================================
		bra.w	loc_72BF4
; ===========================================================================
		bra.w	loc_72C26
; ===========================================================================
		bra.w	loc_72D30
; ===========================================================================
		bra.w	loc_72D52
; ===========================================================================
		bra.w	loc_72D58
; ===========================================================================
		bra.w	loc_72E06
; ===========================================================================
		bra.w	loc_72E20
; ===========================================================================
		bra.w	loc_72E26
; ===========================================================================
		bra.w	loc_72E2C
; ===========================================================================
		bra.w	loc_72E38
; ===========================================================================
		bra.w	loc_72E52
; ===========================================================================
		bra.w	loc_72E64
; ===========================================================================

loc_72ACC:				; XREF: loc_72A64
		move.b	(a4)+,d1
		tst.b	1(a5)
		bmi.s	locret_72AEA
		move.b	$A(a5),d0
		andi.b	#$37,d0
		or.b	d0,d1
		move.b	d1,$A(a5)
		move.b	#$B4,d0
		bra.w	loc_72716
; ===========================================================================

locret_72AEA:
		rts	
; ===========================================================================

loc_72AEC:				; XREF: loc_72A64
		move.b	(a4)+,$1E(a5)
		rts	
; ===========================================================================

loc_72AF2:				; XREF: loc_72A64
		move.b	(a4)+,7(a6)
		rts	
; ===========================================================================

loc_72AF8:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		movea.l	(a5,d0.w),a4
		move.l	#0,(a5,d0.w)
		addq.w	#2,a4
		addq.b	#4,d0
		move.b	d0,$D(a5)
		rts	
; ===========================================================================

loc_72B14:				; XREF: loc_72A64
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72B1E:
		move.l	(a1)+,(a0)+
		dbf	d0,loc_72B1E

		bset	#2,$40(a6)
		movea.l	a5,a3
		move.b	#$28,d6
		sub.b	$26(a6),d6
		moveq	#5,d7
		lea	$70(a6),a5

loc_72B3A:
		btst	#7,(a5)
		beq.s	loc_72B5C
		bset	#1,(a5)
		add.b	d6,9(a5)
		btst	#2,(a5)
		bne.s	loc_72B5C
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		jsr	sub_72C4E(pc)

loc_72B5C:
		adda.w	#$30,a5
		dbf	d7,loc_72B3A

		moveq	#2,d7

loc_72B66:
		btst	#7,(a5)
		beq.s	loc_72B78
		bset	#1,(a5)
		jsr	sub_729A0(pc)
		add.b	d6,9(a5)

loc_72B78:
		adda.w	#$30,a5
		dbf	d7,loc_72B66
		movea.l	a3,a5
		tst.b	$40(a6)			; is the DAC channel running?
		bmi.s	Restore_NoFM6		; if it is, branch

		moveq	#$2B,d0			; DAC enable/disable register
		moveq	#0,d1			; Disable DAC
		jsr	sub_7272E(pc)

Restore_NoFM6:
		move.b	#$80,$24(a6)
		move.b	#$28,$26(a6)
		clr.b	$27(a6)
		move.w	#0,($A11100).l
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72B9E:				; XREF: loc_72A64
		move.b	(a4)+,2(a5)
		rts	
; ===========================================================================

loc_72BA4:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		bra.w	sub_72CB4
; ===========================================================================

loc_72BAE:				; XREF: loc_72A64
		bset	#4,(a5)
		rts	
; ===========================================================================

loc_72BB4:				; XREF: loc_72A64
		move.b	(a4),$12(a5)
		move.b	(a4)+,$13(a5)
		rts	
; ===========================================================================

loc_72BBE:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,8(a5)
		rts	
; ===========================================================================

loc_72BC6:				; XREF: loc_72A64
		move.b	(a4),2(a6)
		move.b	(a4)+,1(a6)
		rts	
; ===========================================================================

loc_72BD0:				; XREF: loc_72A64
		lea	$40(a6),a0
		move.b	(a4)+,d0
		moveq	#$30,d1
		moveq	#9,d2

loc_72BDA:
		move.b	d0,2(a0)
		adda.w	d1,a0
		dbf	d2,loc_72BDA

		rts	
; ===========================================================================

loc_72BE6:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		rts	
; ===========================================================================

loc_72BEE:				; XREF: loc_72A64
		clr.b	$2C(a6)
		rts	
; ===========================================================================

loc_72BF4:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		jsr	sub_726FE(pc)
		tst.b	$250(a6)
		bmi.s	loc_72C22
		movea.l	a5,a3
		lea	$100(a6),a5
		movea.l	$18(a6),a1
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5

loc_72C22:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72C26:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	d0,$B(a5)
		btst	#2,(a5)
		bne.w	locret_72CAA
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	sub_72C4E
		movea.l	$20(a5),a1
		tst.b	$E(a6)
		bmi.s	sub_72C4E
		movea.l	$20(a6),a1

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72C4E:				; XREF: Snd_FadeOut1; et al
		subq.w	#1,d0
		bmi.s	loc_72C5C
		move.w	#$19,d1

loc_72C56:
		adda.w	d1,a1
		dbf	d0,loc_72C56

loc_72C5C:
		move.b	(a1)+,d1
		move.b	d1,$1F(a5)
		move.b	d1,d4
		move.b	#$B0,d0
		jsr	sub_72722(pc)
		lea	byte_72D18(pc),a2
		moveq	#$13,d3

loc_72C72:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		jsr	sub_72722(pc)
		dbf	d3,loc_72C72
		moveq	#3,d5
		andi.w	#7,d4
		move.b	byte_72CAC(pc,d4.w),d4
		move.b	9(a5),d3

loc_72C8C:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72C96
		add.b	d3,d1

loc_72C96:
		jsr	sub_72722(pc)
		dbf	d5,loc_72C8C
		move.b	#$B4,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

locret_72CAA:
		rts	
; End of function sub_72C4E

; ===========================================================================
byte_72CAC:	dc.b 8,	8, 8, 8, $A, $E, $E, $F

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72CB4:				; XREF: sub_72504; sub_7267C; loc_72BA4
		btst	#2,(a5)
		bne.s	locret_72D16
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	loc_72CD8
		movea.l	$20(a6),a1
		tst.b	$E(a6)
		bmi.s	loc_72CD8
		movea.l	$20(a6),a1

loc_72CD8:
		subq.w	#1,d0
		bmi.s	loc_72CE6
		move.w	#$19,d1

loc_72CE0:
		adda.w	d1,a1
		dbf	d0,loc_72CE0

loc_72CE6:
		adda.w	#$15,a1
		lea	byte_72D2C(pc),a2
		move.b	$1F(a5),d0
		andi.w	#7,d0
		move.b	byte_72CAC(pc,d0.w),d4
		move.b	9(a5),d3
		bmi.s	locret_72D16
		moveq	#3,d5

loc_72D02:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72D12
		add.b	d3,d1
		bcs.s	loc_72D12
		jsr	sub_72722(pc)

loc_72D12:
		dbf	d5,loc_72D02

locret_72D16:
		rts	
; End of function sub_72CB4

; ===========================================================================
byte_72D18:	dc.b $30, $38, $34, $3C, $50, $58, $54,	$5C, $60, $68
		dc.b $64, $6C, $70, $78, $74, $7C, $80,	$88, $84, $8C
byte_72D2C:	dc.b $40, $48, $44, $4C
; ===========================================================================

loc_72D30:				; XREF: loc_72A64
		bset	#3,(a5)
		move.l	a4,$14(a5)
		move.b	(a4)+,$18(a5)
		move.b	(a4)+,$19(a5)
		move.b	(a4)+,$1A(a5)
		move.b	(a4)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)
		rts	
; ===========================================================================

loc_72D52:				; XREF: loc_72A64
		bset	#3,(a5)
		rts	
; ===========================================================================

loc_72D58:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		tst.b	1(a5)
		bmi.s	loc_72D74
		tst.b	8(a6)
		bmi.w	loc_72E02
		jsr	sub_726FE(pc)
		bra.s	loc_72D78
; ===========================================================================

loc_72D74:
		jsr	sub_729A0(pc)

loc_72D78:
		tst.b	$E(a6)
		bpl.w	loc_72E02
		clr.b	0(a6)
		moveq	#0,d0
		move.b	1(a5),d0
		bmi.s	loc_72DCC
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		cmpi.b	#4,d0
		bne.s	loc_72DA8
		tst.b	$340(a6)
		bpl.s	loc_72DA8
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72DB8
; ===========================================================================

loc_72DA8:
		subq.b	#2,d0
		lsl.b	#2,d0
		movea.l	(a0,d0.w),a5
		tst.b	(a5)
		bpl.s	loc_72DC8
		movea.l	$18(a6),a1

loc_72DB8:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_72DC8:
		movea.l	a3,a5
		bra.s	loc_72E02
; ===========================================================================

loc_72DCC:
		lea	$370(a6),a0
		tst.b	(a0)
		bpl.s	loc_72DE0
		cmpi.b	#$E0,d0
		beq.s	loc_72DEA
		cmpi.b	#$C0,d0
		beq.s	loc_72DEA

loc_72DE0:
		lea	dword_722CC(pc),a0
		lsr.b	#3,d0
		movea.l	(a0,d0.w),a0

loc_72DEA:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72E02
		move.b	$1F(a0),($C00011).l

loc_72E02:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72E06:				; XREF: loc_72A64
		move.b	#$E0,1(a5)
		move.b	(a4)+,$1F(a5)
		btst	#2,(a5)
		bne.s	locret_72E1E
		move.b	-1(a4),($C00011).l

locret_72E1E:
		rts	
; ===========================================================================

loc_72E20:				; XREF: loc_72A64
		bclr	#3,(a5)
		rts	
; ===========================================================================

loc_72E26:				; XREF: loc_72A64
		move.b	(a4)+,$B(a5)
		rts	
; ===========================================================================

loc_72E2C:				; XREF: loc_72A64
		move.b	(a4)+,d0
		lsl.w	#8,d0
		move.b	(a4)+,d0
		adda.w	d0,a4
		subq.w	#1,a4
		rts	
; ===========================================================================

loc_72E38:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	(a4)+,d1
		tst.b	$24(a5,d0.w)
		bne.s	loc_72E48
		move.b	d1,$24(a5,d0.w)

loc_72E48:
		subq.b	#1,$24(a5,d0.w)
		bne.s	loc_72E2C
		addq.w	#2,a4
		rts	
; ===========================================================================

loc_72E52:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		subq.b	#4,d0
		move.l	a4,(a5,d0.w)
		move.b	d0,$D(a5)
		bra.s	loc_72E2C
; ===========================================================================

loc_72E64:				; XREF: loc_72A64
		move.b	#$88,d0
		move.b	#$F,d1
		jsr	sub_7272E(pc)
		move.b	#$8C,d0
		move.b	#$F,d1
		bra.w	sub_7272E
; ===========================================================================
Kos_Z80:	incbin	sound\z80_1.bin
		dc.w ((SegaPCM&$FF)<<8)+((SegaPCM&$FF00)>>8)
		dc.b $21
		dc.w (((EndOfRom-SegaPCM)&$FF)<<8)+(((EndOfRom-SegaPCM)&$FF00)>>8)
		incbin	sound\z80_2.bin
		even
Music81:	incbin	sound\music81.bin
		even
Music82:	incbin	sound\music82.bin
		even
Music83:	incbin	sound\music83.bin
		even
Music84:	incbin	sound\music84.bin
		even
Music85:	incbin	sound\music85.bin
		even
Music86:	incbin	sound\music86.bin
		even
Music87:	incbin	sound\music87.bin
		even
Music88:	incbin	sound\music88.bin
		even
Music89:	incbin	sound\music89.bin
		even
Music8A:	incbin	sound\music8A.bin
		even
Music8B:	incbin	sound\music8B.bin
		even
Music8C:	incbin	sound\music8C.bin
		even
Music8D:	incbin	sound\music8D.bin
		even
Music8E:	incbin	sound\music8E.bin
		even
Music8F:	incbin	sound\music8F.bin
		even
Music90:	incbin	sound\music90.bin
		even
Music91:	incbin	sound\music91.bin
		even
Music92:	incbin	sound\music92.bin
		even
Music93:	incbin	sound\music93.bin
		even
; ---------------------------------------------------------------------------
; Sound	effect pointers
; ---------------------------------------------------------------------------
SoundIndex:	dc.l SoundA0, SoundA1, SoundA2
		dc.l SoundA3, SoundA4, SoundA5
		dc.l SoundA6, SoundA7, SoundA8
		dc.l SoundA9, SoundAA, SoundAB
		dc.l SoundAC, SoundAD, SoundAE
		dc.l SoundAF, SoundB0, SoundB1
		dc.l SoundB2, SoundB3, SoundB4
		dc.l SoundB5, SoundB6, SoundB7
		dc.l SoundB8, SoundB9, SoundBA
		dc.l SoundBB, SoundBC, SoundBD
		dc.l SoundBE, SoundBF, SoundC0
		dc.l SoundC1, SoundC2, SoundC3
		dc.l SoundC4, SoundC5, SoundC6
		dc.l SoundC7, SoundC8, SoundC9
		dc.l SoundCA, SoundCB, SoundCC
		dc.l SoundCD, SoundCE, SoundCF
		dc.l SoundD1
SoundD0Index:	dc.l SoundD0
SoundA0:	incbin	sound\soundA0.bin
		even
SoundA1:	incbin	sound\soundA1.bin
		even
SoundA2:	incbin	sound\soundA2.bin
		even
SoundA3:	incbin	sound\soundA3.bin
		even
SoundA4:	incbin	sound\soundA4.bin
		even
SoundA5:	incbin	sound\soundA5.bin
		even
SoundA6:	incbin	sound\soundA6.bin
		even
SoundA7:	incbin	sound\soundA7.bin
		even
SoundA8:	incbin	sound\soundA8.bin
		even
SoundA9:	incbin	sound\soundA9.bin
		even
SoundAA:	incbin	sound\soundAA.bin
		even
SoundAB:	incbin	sound\soundAB.bin
		even
SoundAC:	incbin	sound\soundAC.bin
		even
SoundAD:	incbin	sound\soundAD.bin
		even
SoundAE:	incbin	sound\soundAE.bin
		even
SoundAF:	incbin	sound\soundAF.bin
		even
SoundB0:	incbin	sound\soundB0.bin
		even
SoundB1:	incbin	sound\soundB1.bin
		even
SoundB2:	incbin	sound\soundB2.bin
		even
SoundB3:	incbin	sound\soundB3.bin
		even
SoundB4:	incbin	sound\soundB4.bin
		even
SoundB5:	incbin	sound\soundB5.bin
		even
SoundB6:	incbin	sound\soundB6.bin
		even
SoundB7:	incbin	sound\soundB7.bin
		even
SoundB8:	incbin	sound\soundB8.bin
		even
SoundB9:	incbin	sound\soundB9.bin
		even
SoundBA:	incbin	sound\soundBA.bin
		even
SoundBB:	incbin	sound\soundBB.bin
		even
SoundBC:	incbin	sound\soundBC.bin
		even
SoundBD:	incbin	sound\soundBD.bin
		even
SoundBE:	incbin	sound\soundBE.bin
		even
SoundBF:	incbin	sound\soundBF.bin
		even
SoundC0:	incbin	sound\soundC0.bin
		even
SoundC1:	incbin	sound\soundC1.bin
		even
SoundC2:	incbin	sound\soundC2.bin
		even
SoundC3:	incbin	sound\soundC3.bin
		even
SoundC4:	incbin	sound\soundC4.bin
		even
SoundC5:	incbin	sound\soundC5.bin
		even
SoundC6:	incbin	sound\soundC6.bin
		even
SoundC7:	incbin	sound\soundC7.bin
		even
SoundC8:	incbin	sound\soundC8.bin
		even
SoundC9:	incbin	sound\soundC9.bin
		even
SoundCA:	incbin	sound\soundCA.bin
		even
SoundCB:	incbin	sound\soundCB.bin
		even
SoundCC:	incbin	sound\soundCC.bin
		even
SoundCD:	incbin	sound\soundCD.bin
		even
SoundCE:	incbin	sound\soundCE.bin
		even
SoundCF:	incbin	sound\soundCF.bin
		even
SoundD0:	incbin	sound\soundD0.bin
		even
SoundD1:	incbin	sound\soundD1.bin
		even
SegaPCM:	incbin	sound\segapcm.bin
SegaPCM_End	even

	include	"Error/Error Handler.asm"

EndOfRom:
		END
