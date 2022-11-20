InvStar_Routine	equ $A

Obj_InvStars:
	moveq	#0,d0
	move.b	InvStar_Routine(a0),d0
	move.w	InvStars_Index(pc,d0.w),d1
	jmp	InvStars_Index(pc,d1.w)
; ===========================================================================
InvStars_Index:
		dc.w InvStars_Init-InvStars_Index
		dc.w loc_1DA0C-InvStars_Index
		dc.w loc_1DA80-InvStars_Index

off_1D992:
	dc.l byte_1DB8F
	dc.w $B
	dc.l byte_1DBA4
	dc.w $160D
	dc.l byte_1DBBD
	dc.w $2C0D
; ===========================================================================

InvStars_Init:
	; Load invincibility star tiles into VRAM address $A820
	moveq	#0,d2
	lea	off_1D992-6(pc),a2
	lea	(a0),a1
	moveq	#3,d1

@CreateStars:
	move.b	Obj_ID(a0),Obj_ID(a1)
	move.b	#4,InvStar_Routine(a1)
	move.l	#InvStars_Mappings,Obj_Mappings(a1)
	move.w	#$A820/32,Obj_ArtTile(a1)
	move.b	#%01000100,Obj_Render(a1)
	move.b	#$10,Obj_MainWidth(a1)
	move.b	#2,Obj_ChildCount(a1)
	move.w	Obj_Parent(a0),Obj_Parent(a1)
	move.b	d2,$36(a1)
	addq.w	#1,d2
	move.l	(a2)+,$30(a1)
	move.w	(a2)+,$34(a1)
	lea	Obj_Next(a1),a1 ; a1=object
	dbf	d1,@CreateStars

	move.b	#2,InvStar_Routine(a0)		; => loc_1DA0C
	move.b	#4,$34(a0)

loc_1DA0C:
;	tst.b	(Super_Flag).w
;	bne.w	DeleteObject
	movea.w	Obj_Parent(a0),a1 ; a1=character
	tst.b	($FFFFFE2D).w
	beq.w	DeleteObject
	move.w	Obj_XPosition(a1),d0
	move.w	d0,Obj_XPosition(a0)
	move.w	Obj_YPosition(a1),d1
	move.w	d1,Obj_YPosition(a0)
	lea	Obj_Sub1XPos(a0),a2
	lea	byte_1DB82(pc),a3
	moveq	#0,d5

loc_1DA34:
	move.w	$38(a0),d2
	move.b	(a3,d2.w),d5
	bpl.s	loc_1DA44
	clr.w	$38(a0)
	bra.s	loc_1DA34
; ===========================================================================

loc_1DA44:
	addq.w	#1,$38(a0)
	lea	byte_1DB42(pc),a6
	move.b	$34(a0),d6
	jsr	loc_1DB2C(pc)
	move.w	d2,(a2)+	; sub2_x_pos
	move.w	d3,(a2)+	; sub2_y_pos
	move.w	d5,(a2)+	; sub2_mapframe
	addi.w	#$20,d6
	jsr	loc_1DB2C(pc)
	move.w	d2,(a2)+	; sub3_x_pos
	move.w	d3,(a2)+	; sub3_y_pos
	move.w	d5,(a2)+	; sub3_mapframe
	moveq	#$12,d0
	btst	#0,Obj_Status(a1)
	beq.s	loc_1DA74
	neg.w	d0

loc_1DA74:
	add.b	d0,$34(a0)
	move.w	#$80,d0
	bra.w	DisplaySprite3
; ===========================================================================

loc_1DA80:
;	tst.b	(Super_Flag).w
;	bne.w	DeleteObject
	movea.w	Obj_Parent(a0),a1 ; a1=character
	tst.b	($FFFFFE2D).w
	beq.w	DeleteObject
	lea	($FFFFF7A8).w,a5
	lea	(Plyr_PrvPosBffr).w,a6
	move.b	$36(a0),d1
	lsl.b	#2,d1
	move.w	d1,d2
	add.w	d1,d1
	add.w	d2,d1
	move.w	(a5),d0
	sub.b	d1,d0
	lea	(a6,d0.w),a2
	move.w	(a2)+,d0
	move.w	(a2)+,d1
	move.w	d0,Obj_XPosition(a0)
	move.w	d1,Obj_YPosition(a0)
	lea	Obj_Sub1XPos(a0),a2
	movea.l	$30(a0),a3

loc_1DAD4:
	move.w	$38(a0),d2
	move.b	(a3,d2.w),d5
	bpl.s	loc_1DAE4
	clr.w	$38(a0)
	bra.s	loc_1DAD4
; ===========================================================================

loc_1DAE4:
	swap	d5
	add.b	$35(a0),d2
	move.b	(a3,d2.w),d5
	addq.w	#1,$38(a0)
	lea	byte_1DB42(pc),a6
	move.b	$34(a0),d6
	jsr	loc_1DB2C(pc)
	move.w	d2,(a2)+	; sub2_x_pos
	move.w	d3,(a2)+	; sub2_y_pos
	move.w	d5,(a2)+	; sub2_mapframe
	addi.w	#$20,d6
	swap	d5
	jsr	loc_1DB2C(pc)
	move.w	d2,(a2)+	; sub3_x_pos
	move.w	d3,(a2)+	; sub3_y_pos
	move.w	d5,(a2)+	; sub3_mapframe
	moveq	#2,d0
	btst	#0,Obj_Status(a1)
	beq.s	loc_1DB20
	neg.w	d0

loc_1DB20:
	add.b	d0,$34(a0)
	move.w	#$80,d0
	bra.w	DisplaySprite3
; ===========================================================================

loc_1DB2C:
	andi.w	#$3E,d6
	move.b	(a6,d6.w),d2
	move.b	1(a6,d6.w),d3
	ext.w	d2
	ext.w	d3
	add.w	d0,d2
	add.w	d1,d3
	rts
; ===========================================================================
; unknown
byte_1DB42:	dc.w   $F00,  $F03,  $E06,  $D08,  $B0B,  $80D,  $60E,  $30F
		dc.w    $10, -$3F1, -$6F2, -$8F3, -$BF5, -$DF8, -$EFA, -$FFD
		dc.w  $F000, -$F04, -$E07, -$D09, -$B0C, -$80E, -$60F, -$310
		dc.w   -$10,  $3F0,  $6F1,  $8F2,  $BF4,  $DF7,  $EF9,  $FFC

byte_1DB82:	dc.b   8,  5,  7,  6,  6,  7,  5,  8,  6,  7,  7,  6,$FF
	even
byte_1DB8F:	dc.b   8,  7,  6,  5,  4,  3,  4,  5,  6,  7,$FF
		dc.b   3,  4,  5,  6,  7,  8,  7,  6,  5,  4
	even
byte_1DBA4:	dc.b   8,  7,  6,  5,  4,  3,  2,  3,  4,  5,  6,  7,$FF
		dc.b   2,  3,  4,  5,  6,  7,  8,  7,  6,  5,  4,  3
	even
byte_1DBBD:	dc.b   7,  6,  5,  4,  3,  2,  1,  2,  3,  4,  5,  6,$FF
		dc.b   1,  2,  3,  4,  5,  6,  7,  6,  5,  4,  3,  2
	even

InvStars_Tiles:
	incbin	"Objects/Invincibility Stars/Tiles.unc"
	even

InvStars_Mappings:
	include	"Objects/Invincibility Stars/Mappings.asm"