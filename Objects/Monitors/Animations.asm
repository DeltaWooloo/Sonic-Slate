; ---------------------------------------------------------------------------
; Animation script - monitors
; ---------------------------------------------------------------------------
	dc.w	MonAni_Blank-Ani_Obj26
	dc.w	MonAni_Ring-Ani_Obj26
	dc.w	MonAni_Shield-Ani_Obj26
	dc.w	MonAni_Flame-Ani_Obj26
	dc.w	MonAni_Elec-Ani_Obj26
	dc.w	MonAni_Bubble-Ani_Obj26
	dc.w	MonAni_Invinc-Ani_Obj26
	dc.w	MonAni_Shoe-Ani_Obj26
	dc.w	MonAni_1Up-Ani_Obj26
	dc.w	MonAni_Eggman-Ani_Obj26
	dc.w	MonAni_Super-Ani_Obj26
	dc.w	MonAni_Broken-Ani_Obj26

MonAni_Blank:
	dc.b	$7F, 0, $FF

MonAni_Ring:
	dc.b	1, 1, 1, 1, 0, $FF

MonAni_Shield:
	dc.b	1, 2, 2, 2, 0, $FF

MonAni_Flame:
	dc.b	1, 3, 3, 3, 0, $FF

MonAni_Elec:
	dc.b	1, 4, 4, 4, 0, $FF

MonAni_Bubble:
	dc.b	1, 5, 5, 5, 0, $FF

MonAni_Invinc:
	dc.b	1, 6, 6, 6, 0, $FF

MonAni_Shoe:
	dc.b	1, 7, 7, 7, 0, $FF

MonAni_1Up:
	dc.b	1, 8, 8, 8, 0, $FF

MonAni_Eggman:
	dc.b	1, 9, 9, 9, 0, $FF

MonAni_Super:
	dc.b	1, $A, $A, $A, 0, $FF

MonAni_Broken:
	dc.b	6, 0, $B, $FE, 1, 0
	even