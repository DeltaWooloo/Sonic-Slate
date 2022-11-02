@echo off
"_bin/AXM68k.exe" /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- "Main.asm", "Output.gen", "Error/Symbols.sym", "Error/Listing.lst"
"_bin/ConvSym.exe" "Error/Listing.lst" "Output.gen" -input asm68k_lst -inopt "/localSign=@ /localJoin=. /ignoreMacroDefs+ /ignoreMacroExp- /addMacrosAsOpcodes+" -a
pause