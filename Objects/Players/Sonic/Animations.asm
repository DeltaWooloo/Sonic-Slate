; ---------------------------------------------------------------------------
; Animation script - Sonic
; ---------------------------------------------------------------------------
		dc.w SonAni_Walk-SonicAniData
		dc.w SonAni_Run-SonicAniData
		dc.w SonAni_Roll-SonicAniData
		dc.w SonAni_Roll2-SonicAniData
		dc.w SonAni_Push-SonicAniData
		dc.w SonAni_Wait-SonicAniData
		dc.w SonAni_Balance-SonicAniData
		dc.w SonAni_LookUp-SonicAniData
		dc.w SonAni_Duck-SonicAniData
		dc.w SonAni_Warp1-SonicAniData
		dc.w SonAni_Warp2-SonicAniData
		dc.w SonAni_Warp3-SonicAniData
		dc.w SonAni_Warp4-SonicAniData
		dc.w SonAni_Stop-SonicAniData
		dc.w SonAni_Float1-SonicAniData
		dc.w SonAni_Float2-SonicAniData
		dc.w SonAni_Spring-SonicAniData
		dc.w SonAni_LZHang-SonicAniData
		dc.w SonAni_Leap1-SonicAniData
		dc.w SonAni_Leap2-SonicAniData
		dc.w SonAni_Surf-SonicAniData
		dc.w SonAni_Bubble-SonicAniData
		dc.w SonAni_Death1-SonicAniData
		dc.w SonAni_Drown-SonicAniData
		dc.w SonAni_Death2-SonicAniData
		dc.w SonAni_Shrink-SonicAniData
		dc.w SonAni_Hurt-SonicAniData
		dc.w SonAni_LZSlide-SonicAniData
		dc.w SonAni_Blank-SonicAniData
		dc.w SonAni_Float3-SonicAniData
		dc.w SonAni_Float4-SonicAniData
		dc.w SonAni_SpinDash-SonicAniData	;1F
SonAni_Walk:	dc.b $FF, 9, $A, $B, $C, 7, 8, $FF
SonAni_Run:	dc.b $FF, $1F, $20, $21, $22, $FF, $FF,	$FF
SonAni_Roll:	dc.b $FE, $2F, $30, $31, $32, $33, $FF,	$FF
SonAni_Roll2:	dc.b $FE, $2F, $30, $33, $31, $32, $33,	$FF
SonAni_Push:	dc.b $FD, $3C, $3D, $3E, $3F, $FF, $FF,	$FF
SonAni_Wait:	dc.b $17, 1, 1,	1, 1, 1, 1, 1, 1, 1, 1,	1, 1, 3, 2, 2, 2, 3, 4, $FE, 2, 0
SonAni_Balance:	dc.b $1F, $40, $41, $FF
SonAni_LookUp:	dc.b $3F, 5, $FF, 0
SonAni_Duck:	dc.b $3F, 6, $FF, 0
SonAni_Warp1:	dc.b $3F, $33, $FF, 0
SonAni_Warp2:	dc.b $3F, $34, $FF, 0
SonAni_Warp3:	dc.b $3F, $35, $FF, 0
SonAni_Warp4:	dc.b $3F, $36, $FF, 0
SonAni_Stop:	dc.b 7,	$3A, $3B, $FF
SonAni_Float1:	dc.b 7,	$3C, $3F, $FF
SonAni_Float2:	dc.b 7,	$4A, $4B, $4C, $4D, $4E, $FF, 0
SonAni_Spring:	dc.b $2F, $42, $FD, 0
SonAni_LZHang:	dc.b 4,	$4F, $50, $FF
SonAni_Leap1:	dc.b $F, $43, $43, $43,	$FE, 1
SonAni_Leap2:	dc.b $F, $43, $44, $FE,	1, 0
SonAni_Surf:	dc.b $3F, $49, $FF, 0
SonAni_Bubble:	dc.b $B, $45, $45, $B, $C, $FD,	0, 0
SonAni_Death1:	dc.b $20, $4B, $FF, 0
SonAni_Drown:	dc.b $2F, $49, $FF, 0
SonAni_Death2:	dc.b 3,	$48, $FF, 0
SonAni_Shrink:	dc.b 3,	$4E, $4F, $50, $51, $52, 0, $FE, 1, 0
SonAni_Hurt:	dc.b 3,	$46, $FF, 0
SonAni_LZSlide:	dc.b 7, $46, $47, $FF
SonAni_Blank:	dc.b $77, 0, $FD, 0
SonAni_Float3:	dc.b 3,	$3C, $3D, $53, $3E, $54, $FF, 0
SonAni_Float4:	dc.b 3,	$3C, $FD, 0
SonAni_SpinDash:	dc.b 0, $34, $35, $34, $36, $34, $37, $34, $38, $34, $39, $FF
		even