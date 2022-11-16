; ====================================================================================================
; Game RAM Definitions
; ====================================================================================================

    rsset   RAM_Start
Decomp_Buffer   rs.b 0
Chunk_Mappings  rs.b $8000
    rs.b    $FF000000   ; Necessary for ASM68k.
Obj_RespawnTbl  rs.b $300
Rings_PosTable  rs.b (Rings_Max+1)*2
Rings_StartROM  rs.l 1
Rings_EndROM    rs.l 1
Rings_StartRAM  rs.w 1
Rings_Left      rs.w 1
Rings_MngrRtn   rs.w 1
Rings_CllctTbl  rs.w 1
    rs.b    $1D06
Level_Layout    rs.l 1
    rs.b    $5FC
NemDec_Buffer   rs.b $200
Sprite_InputTbl rs.b $400
Block_Mappings  rs.b $1800
VDP_ComBffr     rs.b 7*$12*2
VDP_ComBffrSlot rs.w 1
    rs.b    $202
Plyr_PrvPosBffr rs.b $100
HScrll_Buffer   rs.b $400
ObMem_Reserved  rs.b 0
ObMem_Player    rs.b Obj_Size
ObMem_Sidekick  rs.b Obj_Size
ObMem_Tails     rs.b Obj_Size
ObMem_PlyrDust  rs.b Obj_Size
ObMem_SdkcDust  rs.b Obj_Size
ObMem_Shield    rs.b Obj_Size
ObMem_InvcStars rs.b Obj_Size
ObMem_PlyrBbls  rs.b Obj_Size*3
ObMem_SdkcBbls  rs.b Obj_Size*3
ObMem_TtlCards  rs.b Obj_Size*4
ObMem_Results   rs.b Obj_Size*7
    rs.b    Obj_Size*8  ; You have 8 reserved object slots!
ObMem_Dynamic   rs.b Obj_Size*$60
Sound_DrvrFlags rs.b $5C0   ; Note to self: Reference GitHub to make this more specific
    rs.b    $40
Game_Scene  rs.b 1
    rs.b    1
JPad_P1HeldLogic    rs.b 1
JPad_P1PressLogic   rs.b 1
JPad_P1Held         rs.b 1
JPad_P1Press        rs.b 1
JPad_P2Held         rs.b 1
JPad_P2Press        rs.b 1
JPad_P2HeldLogic    rs.b 1
JPad_P2PressLogic   rs.b 1
    rs.b    2
VDP_ComMode2    rs.w 1
    rs.b    6
Game_Timer  rs.w 1
VSRM_PlnAYPos   rs.w 1
VSRM_PlnBYPos   rs.w 1
HScrl_PlnAXPos  rs.w 1
HScrl_PlnBXPos  rs.w 1
Copy_PlnBYPos3  rs.w 1
Copy_PlnBXPos3  rs.w 1
    rs.w    1
HInt_CountBffr  rs.w 1
Pal_FadeVrbl    rs.w 1
VInt_RtnECount  rs.b 1
    rs.b    1
VInt_Routine    rs.b 1
    rs.b    1
Sprite_Count    rs.b 1
    rs.b    5
Pal_CycleOff    rs.w 1
Pal_CycleTimer  rs.w 1
RNG_Variable    rs.l 1
Game_Paused     rs.w 1
    rs.b    4
VDP_DMACommLo   rs.w 1
    rs.w    1
Water_HIntTnsfr rs.w 1
Water_Height    rs.w 1
Water_HeightAvg rs.w 1
Water_HeightTgt rs.w 1
Water_MoveDir   rs.b 1
Water_Routine   rs.b 1
Water_FullScrn  rs.b 1
HInt_RunSound   rs.b 1
    rs.b    $30
NemDec_ArtCue   rs.b 16*(2+4)
NemDec_CueVars  rs.b $20
PlaneA_XPos     rs.l 1
PlaneA_YPos     rs.l 1
PlaneB_XPos1    rs.l 1
PlaneB_YPos1    rs.l 1
PlaneB_XPos2    rs.l 1
PlaneB_YPos2    rs.l 1
PlaneB_XPos3    rs.l 1
PlaneB_YPos3    rs.l 1
Level_LeftBoundTgt      rs.w 1
Level_RightBoundTgt     rs.w 1
Level_TopBoundTgt       rs.w 1
Level_BottomBoundTgt    rs.w 1
Level_LeftBound         rs.w 1
Level_RightBound        rs.w 1
Level_TopBound          rs.w 1
Level_BottomBound       rs.w 1
    rs.b    $A
Camera_XPxScrolled  rs.w 1
Camera_YPxScrolled  rs.w 1
Camera_YPosRelative rs.w 1
    rs.b    2
Level_DLERoutine    rs.b 1
    rs.b    1
Camera_ScrollDsbl   rs.b 1
    rs.b    5
PlaneA_XRedrawFlag  rs.b 1
PlaneA_YRedrawFlag  rs.b 1
PlaneB_XRedrawFlag1 rs.b 1
PlaneB_YRedrawFlag1 rs.b 1
PlaneB_XRedrawFlag2 rs.b 1
PlaneB_YRedrawFlag2 rs.b 1
PlaneB_XRedrawFlag3 rs.b 1
PlaneB_YRedrawFlag3 rs.b 1
    rs.b    2
PlaneA_RedrawFlags  rs.b 1
    rs.b    1
PlaneB_RedrawFlags1 rs.b 1
    rs.b    1
PlaneB_RedrawFlags2 rs.b 1
    rs.b    1
PlaneB_RedrawFlags3 rs.b 1
    rs.b    1
Level_BtmBndMoving  rs.b 1
    rs.b    3
Plyr_TopSpeed   rs.w 1
Plyr_Decel      rs.w 1
Plyr_Accel      rs.w 1
Plyr_PrevFrame  rs.b 1
Plyr_ArtReload  rs.b 1
Plyr_AngleLeft  rs.b 1
    rs.b    1
Plyr_AngleRight rs.b 1
    rs.b    1
ObPos_Routine   rs.b 1
    rs.b    1
ObPos_PlnAXPos  rs.w 1
ObPos_Flags     rs.b $10
    rs.b    $14
Pal_FadeTimer   rs.w 1
Level_CollPointer   rs.l 1
    rs.b    $C
Boss_Flags  rs.b 1
Plyr_PrvPosIndex    rs.w 1
Plyr_RightSideLock  rs.b 1
    rs.b    5
AniTls_Offset1  rs.b 1
AniTls_Timer1   rs.b 1
AniTls_Offset2  rs.b 1
AniTls_Timer2   rs.b 1
AniTls_Offset3  rs.b 1
AniTls_Timer3   rs.b 1
AniTls_Offset4  rs.b 1
AniTls_Timer4   rs.b 1
AniTls_Offset5  rs.b 1
AniTls_Timer5   rs.b 1
AniTls_Offset6  rs.b 1
AniTls_Timer6   rs.b 1
AniTls_Offset7  rs.b 1
AniTls_Timer7   rs.b 1
    rs.b    $F
JPad_Lock       rs.b 1
    rs.b    3
Score_EnemyChain    rs.w 1
Score_TimeBonus     rs.w 1
Score_RingBonus     rs.w 1
HUD_UpdateBonuses   rs.b 1
    rs.b    9
Switch_Activated    rs.b $10    ; Use like (Switch_Activated+1)
HScrl_SectHeight1   rs.w 1
HScrl_SectHeight2   rs.w 1
HScrl_SectHeight3   rs.w 1
HScrl_SectHeight4   rs.w 1
    rs.b    8
Sprite_TblBuffer    rs.b $200
Pal_WaterTgt    rs.w $40
Pal_WaterBffr   rs.w $40
Pal_NormBffr    rs.w $40
Pal_NormTgt     rs.w $40
    rs.b    $100
Sys_Stack       rs.b $100
Sys_StackPtr    rs.w 1
Level_Reload    rs.w 1
Level_FrameCnt  rs.w 1
Debug_ObjID     rs.b 1
    rs.b    1
Debug_Active    rs.w 1
Debug_SpeedTmr  rs.b 1
Debug_MoveSpeed rs.b 1
VInt_Count      rs.l 1
Level_ZoneID    rs.b 1
Level_ActID     rs.b 1
Plyr_Lives      rs.b 1
    rs.b    1
Plyr_Air    rs.w 1
    rs.b    4
Game_TimeOver   rs.b 1
    rs.b    1
HUD_UpdateLives rs.b 1
HUD_UpdateRings rs.b 1
HUD_UpdateTimer rs.b 1
HUD_UpdateScore rs.b 1
Plyr_Rings  rs.w 1
Level_MinTimer  rs.w 1
Level_SecTimer  rs.b 1
Level_FrmTimer  rs.b 1
Plyr_Score  rs.l 1
    rs.b    2
Plyr_ShieldFlag rs.b 1
Plyr_InvincFlag rs.b 1
Plyr_SpeedFlag  rs.b 1
    rs.b    1
Chpt_Counter    rs.b 1
Chpt_CntCopy    rs.b 1
Chpt_PlyrXPos   rs.w 1
Chpt_PlyrYPos   rs.w 1
Chpt_Rings      rs.w 1
Chpt_Time       rs.l 1
Chpt_DLERoutine rs.w 1
Chpt_BtmBound   rs.w 1
Chpt_PlnAXpos   rs.w 1
Chpt_PlnAYPos   rs.w 1
Chpt_PlnBXPos1  rs.w 1
Chpt_PlnBYPos1  rs.w 1
Chpt_PlnBXPos2  rs.w 1
Chpt_PlnBYPos2  rs.w 1
Chpt_PlnBXPos3  rs.w 1
Chpt_PlnBYPos3  rs.w 1
Chpt_WaterHtAvg rs.w 1
Chpt_WaterRtn   rs.b 1
Chpt_WaterFullScrn  rs.b 1
    rs.b    $A
Osc_Values  rs.b $42
    rs.b    $22
Ring_AniTimer   rs.b 1
Ring_AniFrame   rs.b 1
    rs.b    2

Camera_X_pos_last = $FFFFFE2A
Camera_Y_pos_last = $FFFFF76E

; ====================================================================================================