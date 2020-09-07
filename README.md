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
