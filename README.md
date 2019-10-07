# reddisassembler
rewritten and better lol how else do i put it.
also v3 coming soon cause i don't like v2, and this time it's like an actual disassembler, not a hook.

## how this works
yea so i just hook deserialization for any lbi variant.
then the main parser handles the rest.
pretty neat i guess, not real disassembling but im working on it so.

## features
 - jump line detection (some bugs but will be worked out eventually)
 - structure key correction
 - catch undefined instructions
 - add more than base lua instruction set to disassembler

## sample preview of output
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

tldr i spend way to much time at night working on stupid stuff
![IMG1](https://arilis.dev/uploader/0x59/files/6424tz5dy47j64s.png)
