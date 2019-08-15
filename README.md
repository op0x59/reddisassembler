# chunkdecompiler
rewritten and better lol how else do i put it.

## Sample preview of output
```lua
_G.yeet = true
if _G.yeet == true then 
  local cool_upvalue = 1
  (function()
    print(cool_upvalue)
  end)()
else 
  print("aww no yeet")
end 
```

```assembly
; red disassembler:tm: by red developers 😎
; red disassembler output is not meant to give exact results of what the code is
; red disassembler output is in luas bytecode format there could be a possible conversion 
; to a lua source but it would not be exact 
; big brain disassembler lmao also supports nɐnl h

 main[NUPV 1, NARG 0, PC 0, IC 4, CC 0, FLIN 4]
.constant	'print'

0x1	[5]			    getglobal		0 0 		; print
0x2	[4]			    getupval		1 0 	
0x3	[28]		    call			0 2 1 	
0x4	[30]		    return			0 1 

chunk[NUPV 0, NARG 0, PC 0, IC 16, CC 5, FLIN 0]
.constant	'yeet'
.constant	'true'
.constant	1
.constant	'print'
.constant	'aww no yeet'
.constant	'_G'

0x1	 [5]			    getglobal		0 0 	; _G
0x2	 [9]			    settable		0 1 2 	
0x3	 [5]			    getglobal		0 0 	; _G
0x4	 [6]			    gettable		0 0 1 	
0x5	 [23]		        eq				0 0 2 	
0x6	 [22]		    ╔== jmp				6 		; Jump to Address 0xD
0x7	 [1]			|   loadk			0 3 	; 1
0x8	 [36]		    |   closure			1 0 	; 00B07428
0x9	 [0]			|   move			0 0 
0xA	 [28]		    |   call			1 1 1 	
0xB	 [35]		    |   close			0 
0xC	 [22]		    ╔== jmp				3 		; Jump to Address 0x10
0xD	 [5]			╚=> getglobal		0 4 	; print
0xE	 [1]			|   loadk			1 5 	; "aww no yeet"
0xF	 [28]		    |   call			0 2 1 	
0x10 [30]		    ╚=> return		    0 1 
```

tdlr i spend way to much time at night working on stupid stuff
![IMG1](https://cdn.zuros.info/uploader/0x59/files/mloyvbs7rtlycs1.png)
