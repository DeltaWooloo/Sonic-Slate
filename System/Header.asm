; ====================================================================================================
; SEGA Mega Drive ROM Header
; ====================================================================================================

; --------------------------------------------------
; M68k Exceptions vector table
; --------------------------------------------------
System_VectorTbl:
	dc.l	Sys_StackPtr&$FFFFFF, Program_Entry, Error_Bus, Error_Address
	dc.l	Error_Illegal, Error_Div0, Error_CHK, Error_TRAPV
	dc.l	Error_PrivelegeVio, Error_TRACE, Error_LineAEmu, Error_LineFEmu
	dc.l	Error_Misc, Error_Misc, Error_Misc, Error_Misc
	dc.l	Error_Misc, Error_Misc, Error_Misc, Error_Misc
	dc.l	Error_Misc, Error_Misc, Error_Misc, Error_Misc
	dc.l	Error_Misc, Error_Trap, Error_Trap, Error_Trap
	dc.l	HInt, Error_Trap, VInt, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
	dc.l	Error_Trap, Error_Trap, Error_Trap, Error_Trap
; --------------------------------------------------

; --------------------------------------------------
; ROM info
; --------------------------------------------------
Header_System:
	dc.b	"SEGA MEGA DRIVE "	; 16 bytes. System ID. SEGA is necessary for console start up.

Header_Copyright:
	dc.b	"(R)NAME 2000.JAN"	; 16 bytes. (Copyright)Developer Year.Month.

Header_DomTitle:
	dc.b	"SONIC SLATE             "	; 48 bytes. Title in Asian territories.
	dc.b	"                        "

Header_IntTitle:
	dc.b	"SONIC SLATE             "	; 48 bytes. Title in American and European territories.
	dc.b	"                        "

Header_SerialID:
	dc.b	"RH 00000000-00"	; 14 bytes. Program type Serial ID-Revision.
	; RH is a custom type standing for ROM Hack.

Header_Checksum:
	dc.w	0	; 2 bytes. Unused.

Header_IOSupport
	dc.b	"J               "	; 16 bytes. Supported I/O devices.

Header_ROMRange:
	dc.l	ROM_Start	; 4 bytes. ROM start location
	dc.l	ROM_End-1	; 4 bytes. ROM end location

Header_RAMRange:
	dc.l	RAM_Start	; 4 bytes. RAM start address
	dc.l	RAM_End		; 4 bytes. RAM end address

Header_SRAMType:
	dc.b	"RA", $B0, $20	; 4 bytes. SRAM type. Currently set to no saving on even 8-bit addresses. Change $B0 to $F0 to enable saving.

Header_SRAMRange:
	dc.l	SRAM_Start	; 4 bytes. SRAM start address
	dc.l	SRAM_End	; 4 bytes. SRAM end address

Header_ModemType:
	dc.b	"            "	; 12 bytes. Mega Modem support. MO Publisher Game ID, Version Region/Microphone.

Header_Notes:
	dc.b	"                                        "	; 40 bytes. For any comments.

Header_Regions:
	dc.b	"JUE             "	; 16 bytes. Supported regions. J = Japan, U = Americas, E = Europe.
; --------------------------------------------------

; ====================================================================================================