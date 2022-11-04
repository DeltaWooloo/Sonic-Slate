; ====================================================================================================
; Game Constants
; ====================================================================================================

; --------------------------------------------------
; Scene IDs
; --------------------------------------------------
    rsreset
ScnID_SEGA      rs.l 1
ScnID_Title     rs.l 1
ScnID_Level     rs.l 1
; --------------------------------------------------

; --------------------------------------------------
; Palette IDs
; --------------------------------------------------
    rsreset
PalID_Title     rs.b 1
PalID_LevSel    rs.b 1
PalID_Sonic     rs.b 1
PalID_GHZ       rs.b 1
; --------------------------------------------------

; --------------------------------------------------
; PLC IDs
; --------------------------------------------------
    rsreset
PLCID_Main1         rs.b 1
PLCID_Main2         rs.b 1
PLCID_Explode       rs.b 1
PLCID_GameOver      rs.b 1
PLCID_GHZ1          rs.b 1
PLCID_GHZ2          rs.b 1
PLCID_TtlCard       rs.b 1
PLCID_LevelEnd      rs.b 1
PLCID_GHZAnimals    rs.b 1
; --------------------------------------------------

; --------------------------------------------------
; Music IDs
; --------------------------------------------------
    rsset $81
MusID_GHZ       rs.b 1
MusID_LZ        rs.b 1
MusID_MZ        rs.b 1
MusID_SLZ       rs.b 1
MusID_SYZ       rs.b 1
MusID_SBZ       rs.b 1
MusID_Invinc    rs.b 1
MusID_1Up       rs.b 1
MusID_Special   rs.b 1
MusID_Title     rs.b 1
MusID_Ending    rs.b 1
MusID_Boss      rs.b 1
MusID_FZ        rs.b 1
MusID_ActClear  rs.b 1
MusID_GameOver  rs.b 1
MusID_Continue  rs.b 1
MusID_Credits   rs.b 1
MusID_Drowning  rs.b 1
MusID_GotEmrld  rs.b 1
; --------------------------------------------------

; --------------------------------------------------
; SFX IDs
; --------------------------------------------------

; --------------------------------------------------

; --------------------------------------------------
; Object IDs
; --------------------------------------------------
    rsset 1

; Players + player children
ObID_Sonic      rs.b 1
ObID_Tails      rs.b 1
ObID_TailsTails rs.b 1
ObID_Knuckles   rs.b 1
ObID_DustSplash rs.b 1

; Shields
ObID_NormShield rs.b 1
ObID_FireShield rs.b 1
ObID_ElecShield rs.b 1
ObID_ElecSparks rs.b 1
ObID_BblShield  rs.b 1

; Invisible stuff
ObID_InvisBlock rs.b 1
ObID_InvisHarm  rs.b 1
ObID_PthSwapper rs.b 1
ObID_SpnTrigger rs.b 1

; Display cards
ObID_TitleCard  rs.b 1
ObID_GameOver   rs.b 1
ObID_Results    rs.b 1

; Generic objects
ObID_Ring       rs.b 1
ObID_DropRing   rs.b 1
ObID_AttrctRing rs.b 1
ObID_Monitor    rs.b 1
ObID_PowerUp    rs.b 1
ObID_Sring      rs.b 1
ObID_Spikes     rs.b 1
ObID_Checkpoint rs.b 1
ObID_EneExplode rs.b 1
ObID_BssExplode rs.b 1
ObID_Points     rs.b 1
ObID_Animals    rs.b 1
ObID_Signpost   rs.b 1
ObID_AnmlCapsl  rs.b 1
ObID_Bubbles    rs.b 1
ObID_DrownBbls  rs.b 1
ObID_Bumper     rs.b 1
ObID_Switch     rs.b 1
ObID_Platform   rs.b 1
ObID_SwingPltfm rs.b 1
ObID_Bridge     rs.b 1
ObID_CllpsPltfm rs.b 1
ObID_PushBlock  rs.b 1
ObID_SmashWall  rs.b 1

; Enemies and bosses
ObID_ExmpEnemy  rs.b 1
ObID_ExmpBoss   rs.b 1

; --------------------------------------------------

; --------------------------------------------------
; OST
; --------------------------------------------------
Obj_Size
Obj_Next        equ $40

Obj_ID          equ 0
Obj_Render      equ 1
Obj_ArtTile     equ 2
Obj_Mappings    equ 4
Obj_XPosition   equ 8
Obj_YPosition   equ $C
Obj_XSubpixel   equ $A
Obj_YSubpixel   equ $E
Obj_XScrPos     equ 8
Obj_YScrpos     equ $A
Obj_XVelocity   equ $10
Obj_YVelocity   equ $12
Obj_RespawnIdx  equ $14
Obj_YHitbox     equ $16
Obj_XHitbox     equ $17
Obj_Priority    equ $18
Obj_Frame       equ $1A
Obj_AnimFrame   equ $1B
Obj_Animation   equ $1C
Obj_AnimRstrt   equ $1D
Obj_AnimTimer   equ $1E
Obj_Inertia     equ $20
Obj_CollType    equ $20
Obj_CollSpecial equ $21
Obj_Status      equ $22
Obj_SprWidth    equ $23
Obj_Routine     equ $24
Obj_Routine2nd  equ $25
Obj_Angle       equ $26
Obj_Subtype     equ $28
Obj_Parent      equ $3E
; --------------------------------------------------

; --------------------------------------------------
; Sub sprites OST
; --------------------------------------------------
Obj_SubSprSize
Obj_NextSubSpr  equ 6

Obj_MainFrame   equ $B
Obj_MainWidth   equ $E
Obj_ChildCount  equ $F
Obj_MainHeight  equ $14
Obj_Sub1XPos    equ $10
Obj_Sub1YPos    equ $12
Obj_Sub1Frame   equ $15
Obj_Sub2XPos    equ $16
Obj_Sub2YPos    equ $18
Obj_Sub2Frame   equ $1B
Obj_Sub3XPos    equ $1C
Obj_Sub3YPos    equ $1E
Obj_Sub3Frame   equ $21
Obj_Sub4XPos    equ $22
Obj_Sub4YPos    equ $24
Obj_Sub4Frame   equ $27
Obj_Sub5XPos    equ $28
Obj_Sub5YPos    equ $2A
Obj_Sub5Frame   equ $2D
Obj_Sub6XPos    equ $2E
Obj_Sub6YPos    equ $30
Obj_Sub6Frame   equ $33
Obj_Sub7XPos    equ $34
Obj_Sub7YPos    equ $36
Obj_Sub7Frame   equ $39
Obj_Sub8XPos    equ $3A
Obj_Sub8YPos    equ $3C
Obj_Sub8Frame   equ $3F
; --------------------------------------------------

; --------------------------------------------------
; Player object variables
; --------------------------------------------------
Plyr_AirLeft    equ $28
Plyr_InvulnTime equ $30
Plyr_InvincTime equ $32
Plyr_SpeedTime  equ $34
Plyr_FrontAngle equ $36
Plyr_BackAngle  equ $37
Plyr_StckToSrfc equ $38
Plyr_SpnDshFlag equ $39
Plyr_SpnDshChrg equ $3A
Plyr_Jumped     equ $3C
Plyr_ObjOnTopOf equ $3D
Plyr_CtrlLock   equ $3E
; --------------------------------------------------

; --------------------------------------------------
; Boss object variables
; --------------------------------------------------
Boss_HitCount   equ $20
Boss_XPosition  equ $30
Boss_YPosition  equ $38
Boss_FlashTime  equ $3E
; --------------------------------------------------

; ====================================================================================================