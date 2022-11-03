Obj_SpinTrigger:
	moveq	#0,d0
	move.b	Obj_Routine(a0),d0
	move.w	SpinTrigger_Index(pc,d0.w),d1
	jsr	SpinTrigger_Index(pc,d1.w)
		move.w	Obj_XPosition(a0),d0
		andi.w	#$FF80,d0
		move.w	($FFFFF700).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	SpinTrigger_MarkChkGone
        tst.w	($FFFFFE08).w
        beq.s   @Return
        jmp DisplaySprite

@Return:
        rts

SpinTrigger_MarkChkGone:
		jmp	Mark_ChkGone
; ===========================================================================
; off_21170: SpinTrigger_States:
SpinTrigger_Index:
		dc.w SpinTrigger_Init-SpinTrigger_Index	; 0
		dc.w SpinTrigger_MainX-SpinTrigger_Index	; 2
		dc.w SpinTrigger_MainY-SpinTrigger_Index	; 4
; ===========================================================================
; loc_21176:
SpinTrigger_Init:
	addq.b	#2,Obj_Routine(a0) ; => SpinTrigger_MainX
	move.l	#Pathswapper_Maps,Obj_Mappings(a0)
	move.w	#$7B2,Obj_ArtTile(a0)
	ori.b	#4,Obj_Render(a0)
	move.b	#$10,Obj_SprWidth(a0)
	move.w	#$280,Obj_Priority(a0)
	move.b	Obj_Subtype(a0),d0
	btst	#2,d0
	beq.s	SpinTrigger_Init_CheckX
	addq.b	#2,Obj_Routine(a0) ; => SpinTrigger_MainY
	andi.w	#7,d0
	move.b	d0,Obj_Frame(a0)
	andi.w	#3,d0
	add.w	d0,d0
	move.w	word_211E8(pc,d0.w),$32(a0)
	move.w	Obj_YPosition(a0),d1
	lea	($FFFFD000).w,a1 ; a1=character
	cmp.w	Obj_YPosition(a1),d1
	bhs.s	@NotInYRange
	move.b	#1,$34(a0)

@NotInYRange:
;	lea	(Sidekick).w,a1 ; a1=character
;	cmp.w	Obj_YPosition(a1),d1
;	bhs.s	+
;	move.b	#1,$35(a0)
;+
	bra.w	SpinTrigger_MainY
; ===========================================================================
word_211E8:
	dc.w   $20
	dc.w   $40	; 1
	dc.w   $80	; 2
	dc.w  $100	; 3
; ===========================================================================
; loc_211F0:
SpinTrigger_Init_CheckX:
	andi.w	#3,d0
	move.b	d0,Obj_Frame(a0)
	add.w	d0,d0
	move.w	word_211E8(pc,d0.w),$32(a0)
	move.w	Obj_XPosition(a0),d1
	lea	($FFFFD000).w,a1 ; a1=character
	cmp.w	Obj_XPosition(a1),d1
	bhs.s	@NotInXRange
	move.b	#1,$34(a0)

@NotInXRange:
;	lea	(Sidekick).w,a1 ; a1=character
;	cmp.w	Obj_XPosition(a1),d1
;	bhs.s	SpinTrigger_MainX
;	move.b	#1,$35(a0)

; loc_21224:
SpinTrigger_MainX:

	tst.w	($FFFFFE08).w
	bne.s	return_21284
	move.w	Obj_XPosition(a0),d1
	lea	$34(a0),a2 ; a2=object
	lea	($FFFFD000).w,a1 ; a1=character
;	bsr.s	+
;	lea	(Sidekick).w,a1 ; a1=character
;	cmpi.w	#4,(Tails_CPU_Obj_Routine).w	; TailsCPU_Flying
;	beq.s	return_21284

;+	
    tst.b	(a2)+
	bne.s	SpinTrigger_MainX_Alt
	cmp.w	Obj_XPosition(a1),d1
	bhi.s	return_21284
	move.b	#1,-1(a2)
	move.w	Obj_YPosition(a0),d2
	move.w	d2,d3
	move.w	$32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	Obj_YPosition(a1),d4
	cmp.w	d2,d4
	blo.s	return_21284
	cmp.w	d3,d4
	bhs.s	return_21284
	btst	#0,Obj_Render(a0)
	bne.s	@DisableForcedRoll
	move.b	#1,Plyr_SpnDshFlag(a1) ; enable must-roll "pinball mode"
	bra.s	loc_212C4
; ---------------------------------------------------------------------------
@DisableForcedRoll:
    move.b	#0,Plyr_SpnDshFlag(a1) ; disable pinball mode

return_21284:
	rts
; ===========================================================================
; loc_21286:
SpinTrigger_MainX_Alt:
	cmp.w	Obj_XPosition(a1),d1
	bls.s	return_21284
	move.b	#0,-1(a2)
	move.w	Obj_YPosition(a0),d2
	move.w	d2,d3
	move.w	$32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	Obj_YPosition(a1),d4
	cmp.w	d2,d4
	blo.s	return_21284
	cmp.w	d3,d4
	bhs.s	return_21284
	btst	#0,Obj_Render(a0)
	beq.s	@DisableForcedRoll
	move.b	#1,Plyr_SpnDshFlag(a1)
	bra.s	loc_212C4
; ---------------------------------------------------------------------------
@DisableForcedRoll:
    move.b	#0,Plyr_SpnDshFlag(a1)
	rts
; ===========================================================================

loc_212C4:
	btst	#2,Obj_Status(a1)
	beq.s	@NotAlreadyRolling
	rts
; ---------------------------------------------------------------------------
@NotAlreadyRolling:
    bset	#2,Obj_Status(a1)
	move.b	#$E,Obj_YHitbox(a1)
	move.b	#7,Obj_XHitbox(a1)
	move.b	#2,Obj_Animation(a1)
	addq.w	#5,Obj_YPosition(a1)
		move.w	#$BE,d0
		jmp (PlaySound_Special).l ;	play rolling sound

; ===========================================================================
; loc_212F6:
SpinTrigger_MainY:

	tst.w	($FFFFFE08).w
	bne.s	return_21350
	move.w	Obj_YPosition(a0),d1
	lea	$34(a0),a2 ; a2=object
	lea	($FFFFD000).w,a1 ; a1=character
;	bsr.s	+
;	lea	(Sidekick).w,a1 ; a1=character
;+
	tst.b	(a2)+
	bne.s	SpinTrigger_MainY_Alt
	cmp.w	Obj_YPosition(a1),d1
	bhi.s	return_21350
	move.b	#1,-1(a2)
	move.w	Obj_XPosition(a0),d2
	move.w	d2,d3
	move.w	$32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	Obj_XPosition(a1),d4
	cmp.w	d2,d4
	blo.s	return_21350
	cmp.w	d3,d4
	bhs.s	return_21350
	btst	#0,Obj_Render(a0)
	bne.s	@DisableForcedRoll
	move.b	#1,Plyr_SpnDshFlag(a1)
	bra.w	loc_212C4
; ---------------------------------------------------------------------------
@DisableForcedRoll:
    move.b	#0,Plyr_SpnDshFlag(a1)

return_21350:
	rts
; ===========================================================================
; loc_21352:
SpinTrigger_MainY_Alt:
	cmp.w	Obj_YPosition(a1),d1
	bls.s	return_21350
	move.b	#0,-1(a2)
	move.w	Obj_XPosition(a0),d2
	move.w	d2,d3
	move.w	$32(a0),d4
	sub.w	d4,d2
	add.w	d4,d3
	move.w	Obj_XPosition(a1),d4
	cmp.w	d2,d4
	blo.s	return_21350
	cmp.w	d3,d4
	bhs.s	return_21350
	btst	#0,Obj_Render(a0)
	beq.s	@DisableForcedRoll
	move.b	#1,Plyr_SpnDshFlag(a1)
	bra.w	loc_212C4
; ---------------------------------------------------------------------------
@DisableForcedRoll:
    move.b	#0,Plyr_SpnDshFlag(a1)
	rts