; ====================================================================================================
; SEGA Mega Drive System ports, constants, and macros
; ====================================================================================================

; --------------------------------------------------
; General
; --------------------------------------------------
RAM_Start   equ $FF0000
RAM_End     equ $FFFFFF
SRAM_Start  equ $200000
SRAM_End    equ $20FFFF

SRAM_Access equ $A130F1
Sys_Version equ $A10001
Sys_TMSS    equ $A14000
; --------------------------------------------------

; --------------------------------------------------
; Z80 Ports
; --------------------------------------------------
Z80_RAM     equ $A00000
Z80_BusLn   equ $A11100
Z80_ResetLn equ $A11200
; --------------------------------------------------

; --------------------------------------------------
; Macros
; --------------------------------------------------
Z80_Stop    macros
        move.w  #$100,(Z80_BusLn).l

Z80_Start   macros
        move.w  #0,(Z80_BusLn).l

Z80_StartReset  macros
        move.w  #$100,(Z80_ResetLn).l

Z80_StopReset   macros
        move.w  #0,(Z80_ResetLn).l

Z80_Wait    macro
@Wait\@:
		btst    #0,(Z80_BusLn).l
		bne.s   @Wait\@
    endm
; --------------------------------------------------

; --------------------------------------------------
; I/O Ports
; --------------------------------------------------
IO_Data1    equ $A10003
IO_Data2    equ $A10005
IO_DataEXT  equ $A10007
IO_Ctrl1    equ $A10009
IO_Ctrl2    equ $A1000B
IO_CtrlEXT  equ $A1000D
; --------------------------------------------------

; --------------------------------------------------
; I/O Constants
; --------------------------------------------------
IOBit_Up    equ 0
IOBit_Down  equ 1
IOBit_Left  equ 2
IOBit_Right equ 3
IOBit_B     equ 4
IOBit_C     equ 5
IOBit_A     equ 6
IOBit_Start equ 7

IOByte_Up       equ %00000001
IOByte_Down     equ %00000010
IOByte_Left     equ %00000100
IOByte_Right    equ %00001000
IOByte_B        equ %00010000
IOByte_C        equ %00100000
IOByte_A        equ %01000000
IOByte_Start    equ %10000000
; --------------------------------------------------

; --------------------------------------------------
; VDP Ports
; --------------------------------------------------
VDP_Data        equ $C00000
VDP_Control     equ $C00004
VDP_HVCount     equ $C00008
VDP_DBRegister  equ $C00018
VDP_DBAccess    equ $C0001C
; --------------------------------------------------

; --------------------------------------------------
; VDP Constants
; --------------------------------------------------
VComm_VRAMWrite     equ $40000000
VComm_VRAMRead      equ $00000000
VComm_VRAMDMA       equ $40000080
VComm_CRAMWrite     equ $C0000000
VComm_CRAMRead      equ $00000020
VComm_CRAMDMA       equ $C0000080
VComm_VSRAMWrite    equ $40000010
VComm_VSRAMRead     equ $00000010
VComm_VSRAMDMA      equ $40000090

VReg_Next       equ $100
VReg_Mode1      equ $8000
VReg_Mode2      equ $8100
VReg_PlnAAddr   equ $8200
VReg_WinAddr    equ $8300
VReg_PlnBAddr   equ $8400
VReg_SprAddr    equ $8500
VReg_SprBank    equ $8600
VReg_BGColor    equ $8700
VReg_HIntRate   equ $8A00
VReg_Mode3      equ $8B00
VReg_Mode4      equ $8C00
VReg_HScrlAddr  equ $8D00
VReg_AutoInc    equ $8F00
VReg_MapSize    equ $9000
VReg_WinXPos    equ $9100
VReg_WinYPos    equ $9200
VReg_DMALenLo   equ $9300
VReg_DMALenHi   equ $9400
VReg_DMASrcLo   equ $9500
VReg_DMASrcMid  equ $9600
VReg_DMASrcHi   equ $9700
; --------------------------------------------------

; --------------------------------------------------
; VDP Macros
; --------------------------------------------------
VDPCommand  macro   comm, addr, dest
    if narg>2
        move.l  #((addr&$3FFF)<<16)|((addr&$C000)>>14)+comm,dest
    else
        move.l  #((addr&$3FFF)<<16)|((addr&$C000)>>14)+comm,(VDP_Control).l
    endif
    endm
; --------------------------------------------------

; ====================================================================================================