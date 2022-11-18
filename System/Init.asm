; ====================================================================================================
; SEGA Mega Drive System Initialization
; ====================================================================================================

Program_Entry:
	tst.l	(IO_Ctrl1-1).l	; Check if the controller ports have been initialized.
	bne.s	@Port1_Passed	; If so, we'll skip initialization so we don't waste time.
	tst.w	(IO_CtrlEXT-1).l

@Port1_Passed:
	bne.s	Init_Skip
	lea	Init_Values(pc),a5
	movem.w	(a5)+,d5-d7
	movem.l	(a5)+,a0-a4
	move.b	Sys_Version-Z80_BusLn(a1),d0	; Fetch the hardware version.
	andi.b	#$F,d0	; Check if it's a version with TMSS.
	beq.s	@SkipTMSS	; If not, we don't need to activate TMSS.
	move.l	#"SEGA",Sys_TMSS-Z80_BusLn(a1)

@SkipTMSS:
	move.w	(a4),d0	; Check to see if the VDP is active.
	moveq	#0,d0	; Clear d0, a6, and the usp.
	movea.l	d0,a6
	move.l	a6,usp
	moveq	#$18-1,d1	; Set VDP register init loop count.

@Init_VDPRegisters:
	move.b	(a5)+,d5	; Add the VDP register value to the actual register.
	move.w	d5,(a4)		; Write the register to the VDP.
	add.w	d7,d5		; Go to the next register.
	dbf	d1,@Init_VDPRegisters

	move.l	(a5)+,(a4)	; Set VDP command to VRAM DMA.
	move.w	d0,(a3)	; Clear the entirety of VRAM.
	move.w	d7,(a1)	; Stop the Z80.
	move.w	d7,(a2)	; Reset the Z80.

@Z80_Wait:
	btst	d0,(a1)	; Wait for the Z80 to stop.
	bne.s	@Z80_Wait
	moveq	#$26-1,d2	; Set Z80 initialization loop.

@Init_Z80:
	move.b	(a5)+,(a0)+	; Write Z80 instructions to Z80 RAM.
	dbf	d2,@Init_Z80
	move.w	d0,(a2)	; Stop Z80 reset.
	move.w	d0,(a1)	; Start the Z80.
	move.w	d7,(a2)	; Reset the Z80.

@Clear_RAM:
	move.l	d0,-(a6)	; Clear RAM. d0 was already 0 and by going backwards in a6 we end up in RAM space.
	dbf	d6,@Clear_RAM	; d6 was set when we loaded Init_Values into dregs.

	move.l	(a5)+,(a4)	; Set VDP display mode and auto increment.

	move.l	(a5)+,(a4)	; Set VDP to CRAM write
	moveq	#(CRAM_Size/4)-1,d3

@Clear_CRAM:
	move.l	d0,(a3)	; Clear CRAM.
	dbf	d3,@Clear_CRAM

	move.l	(a5)+,(a4)	; Set VDP to VSRAM write
	moveq	#(VSRAM_Size/4)-1,d4

@Clear_VSRAM:
	move.l	d0,(a3)	; Clear VSRAM.
	dbf	d4,@Clear_VSRAM

	moveq	#4-1,d5

@Init_PSG:
	move.b	(a5)+,PSG_Port-VDP_Data(a3)	; Set the PSG's initial volumes
	dbf	d5,@Init_PSG

	move.w	d0,(a2)	; Stop Z80 reset.
	movem.l	(a6),d0-a6	; Clear all dregs and aregs.
	move	#$2700,sr

Init_Skip:
	bra.s	Game_Entry
	
; --------------------------------------------------
; Program initialization values and addresses.
; --------------------------------------------------
Init_Values:
	; These values will be placed in d5, d6, and d7 respectively.
	dc.w	VReg_Mode1
	dc.w	(RAM_End-RAM_Start)/4
	dc.w	VReg_Next

	; These addresses will be placed in a0, a1, a2, a3, and a4 respectively.
	dc.l	Z80_RAM
	dc.l	Z80_BusLn
	dc.l	Z80_ResetLn
	dc.l	VDP_Data
	dc.l	VDP_Control

	; VDP register values. Gets added into the upper byte of d5 (Current VDP register)
	dc.b	4, $14, $30, $3C
	dc.b	7, $6C, 0, 0
	dc.b	0, 0, $FF, 0
	dc.b	$81, $37, 0, 1
	dc.b	1, 0, 0, $FF
	dc.b	$FF, 0, 0, $80

	dc.l	VComm_VRAMDMA	; VDP command for clearing out VRAM.

	; Z80 initialization program.
	cpu	Z80
	obj 0
	xor	a
	ld	bc,((Z80_RAMEnd-Z80_RAM)-Init_Z80End)-1
	ld	de,Init_Z80End+1
	ld	hl,Init_Z80End
	ld	sp,hl
	ld	(hl),a
	ldir
	pop	ix
	pop	iy
	ld	i,a
	ld	r,a
	pop	de
	pop	hl
	pop	af
	ex	af,af
	exx
	pop	bc
	pop	de
	pop	hl
	pop	af
	ld	sp,hl
	di
	im	1
	ld	(hl),0E9h
	jp	(hl)

Init_Z80End:
	cpu	68000
	objend

	; Misc registers and commands.
	dc.w VReg_Mode2|%00000100
	dc.w VReg_AutoInc|2
	dc.l VComm_CRAMWrite
	dc.l VComm_VSRAMWrite

	; PSG initial volumes.
	; $90|(Channel<<5)|Volume
	dc.b $90|(0<<5)|$F, $90|(1<<5)|$F, $90|(2<<5)|$F, $90|(3<<5)|$F
	even
; --------------------------------------------------

; ====================================================================================================