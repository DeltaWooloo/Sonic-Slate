; ---------------------------------------------------------------------------
; Main level load blocks
;
; ===FORMAT===
; level	patterns + (1st	PLC num	* 10^6)
; 16x16	mappings + (2nd	PLC num	* 10^6)
; 256x256 mappings
; blank, music (unused), pal index (unused), pal index
; ---------------------------------------------------------------------------
	dc.l TZ_Tiles+$4000000
	dc.l TZ_Blocks+$5000000
	dc.l TZ_Chunks
	dc.b 0,	$81, PalID_TZ, PalID_TZ
	even