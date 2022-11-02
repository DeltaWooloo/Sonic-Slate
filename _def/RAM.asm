; Temporary
VDP_CmdBffr equ $FFFFC800
VDP_CmdBffrSlot equ VDP_CmdBffr+7*$12*2

Max_Rings = 500 ; default. maximum number possible is 759
Rings_Space = (Max_Rings+1)*2

Object_Respawn_Table = $FFFF8000
Camera_X_pos_last = $FFFFFE2A
Camera_Y_pos_last = $FFFFF76E

Ring_Positions = $FFFF8300
Ring_start_addr_ROM = Ring_Positions+Rings_Space
Ring_end_addr_ROM = Ring_Positions+Rings_Space+4
Ring_start_addr_RAM = Ring_Positions+Rings_Space+8
Perfect_rings_left = Ring_Positions+Rings_Space+$A
Rings_manager_routine = Ring_Positions+Rings_Space+$C
Ring_consumption_table = Ring_Positions+Rings_Space+$E