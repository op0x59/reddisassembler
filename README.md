# reddisassembler v3 [rebirth]
rewritten again, was bored and forget about the rewrite so this kinda just sat around on my desktop for 2-3 months.

# changes from original
deserializer:
  - deserialization was actually added (original depended on lbi.lua)
    - deserialization is mainly based from lbi.lua with some modifications.
  - deserialization now has settings for things like instruction bits. (lua obfuscators tend to use lbi and change the bytecode around)
disassembler:
  - disassembler now has an instruction lookup table.
  - disassembler has register field sorting (so it displays only the used registers).
  - disassembler now supports jump lines ->
    - jump lines support going backward (this took me a while until i realized i was dumb.
    - added instruction addresses. 
    - prototypes will be referenced by addresses as prototype names are almost never in the bytecode.
textstream:
  - textstreams were finally implemented allowing me to do column text properly without any hastle.
  - this allows for organized output from the disassembler with equal spacing all the way through.
  - sadly the old jump line characters were not working kindly with the textstream so i had to compromise on the
    '+---', 'o-->' and '|' lines for showing jump lines.
  - added some new stuff to the textstream to allow support for backwards jumping also made a hacky method in the
    disassembler.
    
# output
feeding the disassembler the bytecode of:
```lua
if 1 == 2 then
	print('hi')
end
print('noob')
```
will reward you with the following disassembled code formatted beautifully.
```asm
func_00000044[NUPV 0, NARG 0]    
                
.constant 1     
.constant 2     
.constant print 
.constant hi    
.constant noob  
0x000058    [23]            eq           0, 0, 1    ; if ((1 == 2) ~= false) PC++             
0x00005C    [22]    +---    jmp          3                                                    
0x000060    [5]     |       getglobal    0, 2       ; pushes global: print onto the stack     
0x000064    [1]     |       loadk        1, 3       ; pushes constant: hi onto the stack      
0x000068    [28]    |       call         0, 2, 1                                              
0x00006C    [5]     o-->    getglobal    0, 2       ; pushes global: print onto the stack     
0x000070    [1]             loadk        1, 4       ; pushes constant: noob onto the stack    
0x000074    [28]            call         0, 2, 1                                              
0x000078    [30]            return       0, 1                                                 
```

# ways to use
## files
```lua
local disassembler = require("disassembler\\disassembler")
local settings = require("disassembler\\settings")

disassembler:load_settings(settings)
disassembler:disassemble_file('C:\\Users\\morph\\Desktop\\Stuff\\LuaBinaries\\luac.out', 'dis.out')
```
## bytecode
```lua
local disassembler = require("disassembler\\disassembler")
local settings = require("disassembler\\settings")

disassembler:load_settings(settings)
disassembler:disassemble(
    "\27\76\117\97\81\0\1\4\4\4\8\0\67\0\0\0\105\102\32\50\32\126\61\32\49\32\116\104\101\110\32\10\32\32\112\114\105\110\116\40\39\104\105\39\41\10\101\108\115\101\10\32\32\112\114\105\110\116\40\39\121\111\117\32\97\114\101\32\115\111\32\99\111\111\108\39\41\10\101\110\100\10\0\0\0\0\0\0\0\0\0\0\0\2\2\10\0\0\0\87\64\64\128\22\192\0\128\5\128\0\0\65\192\0\0\28\64\0\1\22\128\0\128\5\128\0\0\65\0\1\0\28\64\0\1\30\0\128\0\5\0\0\0\3\0\0\0\0\0\0\0\64\3\0\0\0\0\0\0\240\63\4\6\0\0\0\112\114\105\110\116\0\4\3\0\0\0\104\105\0\4\16\0\0\0\121\111\117\32\97\114\101\32\115\111\32\99\111\111\108\0\0\0\0\0\10\0\0\0\1\0\0\0\1\0\0\0\2\0\0\0\2\0\0\0\2\0\0\0\2\0\0\0\4\0\0\0\4\0\0\0\4\0\0\0\5\0\0\0\0\0\0\0\0\0\0\0"
, 'dis.out')
```
