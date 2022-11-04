; ---------------------------------------------------------------------------
; Pattern load cues - index
; ---------------------------------------------------------------------------
	dc.w PLC_Main-ArtLoadCues, PLC_Main2-ArtLoadCues
	dc.w PLC_Explode-ArtLoadCues, PLC_GameOver-ArtLoadCues
	dc.w PLC_TZ-ArtLoadCues, PLC_TZ2-ArtLoadCues
	dc.w PLC_TitleCard-ArtLoadCues
	dc.w PLC_Signpost-ArtLoadCues
	dc.w PLC_TZAnimals-ArtLoadCues
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 1
; ---------------------------------------------------------------------------
PLC_Main:	dc.w 4
		dc.l Nem_Lamp		; lamppost
		dc.w $D800
		dc.l Nem_Hud		; HUD
		dc.w $D940
		dc.l Nem_Lives		; lives	counter
		dc.w $FA80
		dc.l Nem_Ring		; rings
		dc.w $F640
		dc.l Nem_Points		; points from enemy
		dc.w $F2E0
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 2
; ---------------------------------------------------------------------------
PLC_Main2:	dc.w 2
		dc.l Nem_Monitors	; monitors
		dc.w $D000
		dc.l Nem_Shield		; shield
		dc.w $A820
		dc.l Nem_Stars		; invincibility	stars
		dc.w $AB80
; ---------------------------------------------------------------------------
; Pattern load cues - explosion
; ---------------------------------------------------------------------------
PLC_Explode:	dc.w 0
		dc.l Nem_Explode	; explosion
		dc.w $B400
; ---------------------------------------------------------------------------
; Pattern load cues - game/time	over
; ---------------------------------------------------------------------------
PLC_GameOver:	dc.w 0
		dc.l Nem_GameOver	; game/time over
		dc.w $ABC0
; ---------------------------------------------------------------------------
; Pattern load cues - Green Hill
; ---------------------------------------------------------------------------
PLC_TZ:	dc.w 3
		dc.l Nem_Motobug	; motobug enemy
		dc.w $9E00
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l Nem_HSpring	; horizontal spring
		dc.w $A460
		dc.l Nem_VSpring	; vertical spring
		dc.w $A660
PLC_TZ2:	dc.w 2
		dc.l Nem_Swing		; swinging platform
		dc.w $7000
		dc.l Nem_Bridge		; bridge
		dc.w $71C0
		dc.l Nem_GhzWall1	; breakable wall
		dc.w $A1E0
; ---------------------------------------------------------------------------
; Pattern load cues - title card
; ---------------------------------------------------------------------------
PLC_TitleCard:	dc.w 0
		dc.l Nem_TitleCard
		dc.w $B000
; ---------------------------------------------------------------------------
; Pattern load cues - act 1/2 signpost
; ---------------------------------------------------------------------------
PLC_Signpost:	dc.w 0
		dc.l Nem_SignPost	; signpost
		dc.w $D000
; ---------------------------------------------------------------------------
; Pattern load cues - GHZ animals
; ---------------------------------------------------------------------------
PLC_TZAnimals:	dc.w 1
		dc.l Nem_Rabbit		; rabbit
		dc.w $B000
		dc.l Nem_Flicky		; flicky
		dc.w $B240
		even