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
PalID_LZ        rs.b 1
PalID_MZ        rs.b 1
PalID_SLZ       rs.b 1
PalID_SYZ       rs.b 1
PalID_SBZ1      rs.b 1
PalID_LZWater   rs.b 1
PalID_SBZ3      rs.b 1
PalID_SBZ3Water rs.b 1
PalID_SBZ2      rs.b 1
PalID_LZSonic   rs.b 1
PalID_SBZ3Sonic rs.b 1
; --------------------------------------------------

; --------------------------------------------------
; PLC IDs
; --------------------------------------------------
    rsreset
PLCID_Main1     rs.b 1
PLCID_Main2     rs.b 1
PLCID_Explode   rs.b 1
PLCID_GameOver  rs.b 1
PLCID_GHZ1      rs.b 1
PLCID_GHZ2      rs.b 1
PLCID_LZ1       rs.b 1
PLCID_LZ2       rs.b 1
PLCID_MZ1       rs.b 1
PLCID_MZ2       rs.b 1
PLCID_SLZ1      rs.b 1
PLCID_SLZ2      rs.b 1
PLCID_SYZ1      rs.b 1
PLCID_SYZ2      rs.b 1
PLCID_SBZ1      rs.b 1
PLCID_SBZ2      rs.b 1
PLCID_TtlCard   rs.b 1
PLCID_Boss      rs.b 1
PLCID_LevelEnd  rs.b 1
PLCID_GHZAnimals    rs.b 1
PLCID_LZAnimals     rs.b 1
PLCID_MZAnimals     rs.b 1
PLCID_SLZAnimals    rs.b 1
PLCID_SYZAnimals    rs.b 1
PLCID_SBZAnimals    rs.b 1
PLCID_SBZ2Ctscn rs.b 1
PLCID_FZBoss    rs.b 1
; --------------------------------------------------

; --------------------------------------------------
; Object IDs
; --------------------------------------------------
    rsset 1
ObID_Sonic      rs.b 1
                rs.b 1
ObjID_PthSwppr  rs.b 1
                rs.b 1
ObID_Dust       rs.b 1
                rs.b 1
ObID_AttrctRing rs.b 1
                rs.b 1
ObID_SSPlayer   rs.b 1
ObID_DrownBbls  rs.b 1
ObID_LZPole     rs.b 1
ObID_LZFlpDoor  rs.b 1
ObID_Sign       rs.b 1
ObID_TitleSonic rs.b 1
ObID_TitlePSBTM rs.b 1
                rs.b 1
ObID_GHZBridge  rs.b 1
ObID_SYZLamp    rs.b 1
ObID_FrBllSpn   rs.b 1
ObID_FireBall   rs.b 1
ObID_SwingPtfm  rs.b 1
ObID_LZHarpoon  rs.b 1
ObID_GHZHelix   rs.b 1
ObID_Platform   rs.b 1
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
Obj_Subtype
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