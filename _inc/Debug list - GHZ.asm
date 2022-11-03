; ---------------------------------------------------------------------------
; Debug	list - Green Hill
; ---------------------------------------------------------------------------
	dc.w 5			; number of items in list
	dc.l Map_obj25+$25000000	; mappings pointer, object type * 10^6
	dc.b 0,	0, $27,	$B2		; subtype, frame, VRAM setting (2 bytes)
	dc.l Map_obj26+$26000000
	dc.b 0,	0, 6, $80
	dc.l Map_obj18+$18000000
	dc.b 0,	0, $40,	0
	dc.l Map_obj40+$40000000
	dc.b 0,	0, 4, $F0
	dc.l Map_obj41+$41000000
	dc.b 0,	0, 5, $23
	even