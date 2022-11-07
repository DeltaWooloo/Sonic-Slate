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
RNG_Variable    rs.w 1
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
    rs.w    1
Level_DLERoutine    rs.b 1
    rs.b    1
Camera_ScrollDsbl   rs.b 1
    rs.b    5

Camera_X_pos_last = $FFFFFE2A
Camera_Y_pos_last = $FFFFF76E

; ====================================================================================================