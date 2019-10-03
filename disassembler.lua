local disassembler = {
    loaded_settings = {},
    decompiled_chunks = {},
    merged_registers = {},
    c_disassemble_instruction = nil,
    farthest_args = 0
}

-- disassembler modules


function disassembler:get_instruction_from_opcode(opcode)
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opcode == opcode then 
            return v
        end
    end 
    return nil
end 

function disassembler:get_instruction_index_from_opcode(opcode)
    local index = 1
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opcode == opcode then 
            return index
        end
        index = index + 1
    end 
    return nil
end

function disassembler:clear_opcode_listing()
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        v.opcode = math.random(-1, -9999) -- basically very low chance like really low that an instruction has this opcode
    end
end

function disassembler:add_new_instruction(instruction)
    if disassembler:get_instruction_from_opcode(instruction.opcode) then 
        disassembler.loaded_settings.instructions[disassembler:get_instruction_index_from_opcode(instruction.opcode)].opname = instruction.opname
    else 
        table.insert(disassembler.loaded_settings.instructions, instruction)
    end
end 

function disassembler:update_opcode_from_opcode(o_opcode, n_opcode)
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opcode == o_opcode then
            v.opcode = n_opcode
        end
    end 
end

function disassembler:update_opcode_from_opname(o_opname, n_opcode)
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opname == o_opname then
            v.opcode = n_opcode
        end
    end 
end

function disassembler:fix_struct_key(struct, original_key_name, new_key_name)
    local new_struct = {}
    for k,v in pairs(struct) do
        if k ~= original_key_name then
            new_struct[k] = v
        else
            new_struct[new_key_name] = v
        end
    end
    return new_struct
end

function disassembler:set_loaded_settings(settings)
    disassembler.loaded_settings = settings
end

function disassembler:get_instruction_from_name(name)
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opname == name then return v end
    end
end

function disassembler:get_instruction_from_opcode(opcode)
    for k,v in pairs(disassembler.loaded_settings.instructions) do
        if v.opcode == opcode then return v end
    end
end

function disassembler:get_instruction_jump_info(instruction, loaded_instruction, program_counter)
    -- should return { jump_start, jump_end, jump_length } 
    if loaded_instruction.opname == "jmp" then
        -- instruction is a jump instruction we can continue 
        return { 
            jump_start = program_counter, 
            jump_end = program_counter + instruction.sBx + 1, 
            jump_length = jump_end - jump_start 
        }
    end
    return { 
        jump_start = -1, 
        jump_end = -1, 
        jump_length = -1 
    } -- return table<-1> for error 
end 

function disassembler:is_instruction_at_jmp_end(pc, jmpinfos)
    for k,v in pairs(jmpinfos.end_jumps) do
        if v == pc then 
            return true
        end
    end 
    return false
end 

function disassembler:conv_to_str(int)
    local hexwheel = "0123456789ABCDEF"
    local hexstr = ""
    int = int + 1
    while int > 0 do
        local mod = math.fmod(int, 16)
        hexstr = string.sub(hexwheel, mod+1, mod+1) .. hexstr
        int = math.floor(int/16)
    end
    if hexstr == "" then return "0x0" end
    return "0x" .. hexstr
end

function disassembler:to_bit_table(n, ...)
    if (n or 0) == 0 then return ... end
    return disassembler:to_bit_table(math.floor(n/2), n%2, ...)
end

function disassembler:from_bit_table(t)
  local n = 0;
  for a, b in next, t do
    if b ~= 0 then
      n = n + (2 ^ (a - 1));
    end
  end
  return n
end

function disassembler:reverse_indexes(t)
    local a, b = 1, #t
    while a < b do
        t[a], t[b] = t[b], t[a]
        a = b + 1
        a = b - 1
    end
end

function disassembler:write_bit_table(n, t, pos)
  local in_bit_table = { disassembler:to_bit_table(n) };
  local out_bit_table = { };

  for a, b in next, in_bit_table do 
    out_bit_table[a] = b 
  end;

  for a, b in next, t do
    out_bit_table[pos + a] = t[a] or 0;
  end

  return disassembler:from_bit_table(out_bit_table)
end

function disassembler:round(num)
    local under = math.floor(num)
    local upper = math.floor(num) + 1
    local underV = -(under - num)
    local upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function disassembler:do_naming(chunk, loaded_instruction, program_counter, disassembled)
    if chunk.debug.jmplines.farthest_jump ~= nil then 
        if program_counter > chunk.debug.jmplines.farthest_jump then 
            disassembled = disassembled .. "\t    " .. loaded_instruction.opname
        else
            if disassembler:is_instruction_at_jmp_end(program_counter, chunk.debug.jmplines) then
                disassembled = disassembled .. "\t╚=> " .. loaded_instruction.opname
            else
                disassembled = disassembled .. "\t|   " .. loaded_instruction.opname
            end
        end
    else 
        disassembled = disassembled .. "\t    " .. loaded_instruction.opname
    end
    return disassembled
end 

function disassembler:get_args(chunk, instruction, loaded_instruction, program_counter)
    local argsres = ""
    local args = ""
    local opname = loaded_instruction.opname
    local argstable = loaded_instruction.opargs

    -- formatting stuff 
    if opname == "getglobal" or opname == "setglobal" then
        argsres = argsres .. "\t"
    end 
    if #opname < #"call" then 
        argsres = argsres .. "\t\t"
    elseif #opname < #"setupval" then 
        argsres = argsres .. "\t"
    end

    -- add args to output 
    for k,v in pairs(argstable) do
        pcall(function()
            if instruction[v] > 255 then
                args = args .. instruction[v]-256 .. " "
            else 
                args = args .. instruction[v] .. " "
            end
        end)
    end
    
    -- check if the args are far from the current #args 
    if disassembler.farthest_args <= #args then 
        disassembler.farthest_args = #args
        args = args .. "\t"
    end
    
    if opname == "jmp" then -- jmp info 
        args = args .. "\t\t; Jump to Address " .. disassembler:conv_to_str(program_counter + instruction.sBx + 1)
    elseif opname == "getglobal" then
        if instruction.Bx > #chunk.constants then args = args .. "\t; bx out of range for constants" return args end
        args = args .. "\t; " .. chunk.constants[instruction.Bx].data
    elseif opname == "loadk" then -- loadk info 
        if instruction.Bx == nil then args = args .. "\t\t; bx out of range for constants" return args end
        if instruction.Bx > #chunk.constants then args = args .. "\t\t; bx out of range for constants" return args end
        args = args .. "\t; "
        local key = chunk.constants[instruction.Bx].data
        if tonumber(key) ~= nil then else key = '"' .. key .. '"' end
        args = args .. key
    elseif opname == "setglobal" then -- setglobal info 
        if instruction.Bx > #chunk.constants then args = args .. "\t; bx out of range for constants" return args end
        args = args .. "\t; " .. chunk.constants[instruction.Bx].data
    elseif opname == "closure" then -- closure info 
        if instruction.Bx > #chunk.constants then args = args .. "\t; bx out of range for constants" return args end
        local key = string.upper(string.gsub(tostring(chunk.prototypes[instruction.Bx]), 'table: ', ''))
        key = string.gsub(key, "X", '0')
        args = args .. "\t; " .. key
    end

    return argsres .. args
end

function disassembler:disassemble_instruction(chunk, instruction, program_counter)
    local disassembled = disassembler:conv_to_str(program_counter)

    -- formatting stuff which this is the part that is practically perfect
    if #disassembled > 4 then disassembled = disassembled .. "\t" end
    disassembled = disassembled .. "\t[" .. instruction.opcode+disassembler.loaded_settings.opcode_change .. "]\t"
    if #tostring(instruction.opcode+disassembler.loaded_settings.opcode_change) < 2 then disassembled = disassembled .. "\t" end
    
    -- get instruction from loaded settings if possible 
    local loaded_instruction = nil
    xpcall(function()
        loaded_instruction = disassembler:get_instruction_from_opcode(instruction.opcode+disassembler.loaded_settings.opcode_change)
    end, function()
        -- if there is an index out of bounds error etc we will catch it and return 
        print("[reddisassembler] could not fetch instruction: " .. instruction.opcode)
        disassembled = disassembled .. "; could not fetch instruction"
        return disassembled
    end)
    
    -- actually disassemble stuff 
    if loaded_instruction ~= nil then 
        if loaded_instruction.opname == "jmp" then -- jmp subroutine 
            local jmpinfo = disassembler:get_instruction_jump_info(instruction, loaded_instruction, program_counter)
            if chunk.debug.jmplines.farthest_jump == nil then 
                disassembled = disassembled .. "\t╔== " .. loaded_instruction.opname
                chunk.debug.jmplines.farthest_jump = jmpinfo.jump_end
                table.insert(chunk.debug.jmplines.start_jumps, jmpinfo.jump_start)
                table.insert(chunk.debug.jmplines.end_jumps, jmpinfo.jump_end)
            else 
                disassembled = disassembled .. "\t╔== " .. loaded_instruction.opname
                if jmpinfo.jump_end > tonumber(chunk.debug.jmplines.farthest_jump) then
                    chunk.debug.jmplines.farthest_jump = jmpinfo.jump_end
                    table.insert(chunk.debug.jmplines.start_jumps, jmpinfo.jump_start)
                    table.insert(chunk.debug.jmplines.end_jumps, jmpinfo.jump_end)
                end
            end 
        else
            disassembled = disassembler:do_naming(chunk, loaded_instruction, program_counter, disassembled)
        end
    
        if loaded_instruction.opname ~= "setglobal" and loaded_instruction.opname ~= "getglobal" then -- getargs subroutine 
            disassembled = disassembled .. "\t\t" .. disassembler:get_args(chunk, instruction, loaded_instruction, program_counter)
        else
            disassembled = disassembled .. "\t" .. disassembler:get_args(chunk, instruction, loaded_instruction, program_counter)
        end
    else 
        -- unknown opcode subroutine 
        print("[reddisassembler] could not recognize opcode:", instruction.opcode)
        loaded_instruction = {opcode = instruction.opcode, opname = "unknown", nil}
        disassembled = disassembler:do_naming(chunk, loaded_instruction, program_counter, disassembled)
    end
    
    return disassembled
end

function disassembler:disassemble_chunk(chunk)
    local disassembled = ""
    local program_counter = 0
    local has_constants = false

    -- we can legit rekt any packer/virtualizer's obfuscated structures right here 
    local struct_fixes = disassembler.loaded_settings.structure_corrections
    if struct_fixes.chunk_struct ~= nil then 
        for o_key, n_key in pairs(struct_fixes.chunk_struct) do
            chunk = disassembler:fix_struct_key(chunk, o_key, n_key) -- fix chunk struct keys 
        end
    end 

    if struct_fixes.instruction_struct ~= nil then
        for o_key, n_key in pairs(struct_fixes.instruction_struct) do
            for k,v in pairs(chunk.instructions) do
                if disassembler.loaded_settings.register_merging and type(n_key) == "table" then
                    -- {"B", {"Bx", "sBx"}}
                    chunk.instructions[k] = disassembler:fix_struct_key(v, o_key, n_key[1])
                    for m1, m2 in pairs(n_key[2]) do
                        disassembler.merged_registers[m2] = n_key[1]
                    end 
                else
                    chunk.instructions[k] = disassembler:fix_struct_key(v, o_key, n_key) -- fix instruction struct keys 
                    if n_key == "Bx" then
                        chunk.instructions[k]["sBx"] = chunk.instructions[k]["Bx"] - (disassembler.loaded_settings.sBx_fix and 131071 or 0)
                    end 
                end 
            end 
        end 
    end 

    if struct_fixes.constant_struct ~= nil then 
        for o_key, n_key in pairs(struct_fixes.constant_struct) do
            for k,v in pairs(chunk.constants) do
                chunk.constants[k] = disassembler:fix_struct_key(v, o_key, n_key) -- fix constant struct keys 
            end 
        end 
    end 
    

    chunk.debug.jmplines = {
        farthest_jump = nil,
        start_jumps = {},
        end_jumps = {}
    }

    -- write chunk information and check if there is a protector 
    if #disassembler.decompiled_chunks == 0 then
        print("[reddisassembler] disassembling . . .")
        disassembled = disassembled .. "; red disassembler:tm: by red developers 😎\n"
        disassembled = disassembled .. "; red disassembler output is not meant to give exact results of what the code is\n"
        disassembled = disassembled .. "; red disassembler output is in luas bytecode format there could be a possible conversion \n"
        disassembled = disassembled .. "; to a lua source but it would not be exact \n"
        disassembled = disassembled .. "; big brain disassembler lmao also supports nɐnl h\n"
        disassembled = disassembled .. "\n"
        disassembled = disassembled .. " main["
        if disassembler.loaded_settings.structure_corrections.protected_by ~= nil then
            disassembled = disassembled .. "\"" .. disassembler.loaded_settings.structure_corrections.protected_by .. "\"" .. "]"
            print("[reddisassembler] assumed protector: " .. disassembler.loaded_settings.structure_corrections.protected_by)
        else
            disassembled = disassembled .. "NUPV " .. chunk.upvalues .. ", "
            disassembled = disassembled .. "NARG " .. chunk.arguments .. ", "
            disassembled = disassembled .. "PC " .. #chunk.prototypes .. ", "
            disassembled = disassembled .. "IC " .. #chunk.instructions .. ", "
            disassembled = disassembled .. "CC " .. #chunk.constants .. ", "
            disassembled = disassembled .. "FLIN " .. chunk.first_line .. "]"
        end
        print("[reddisassembler] disassembling main chunk . . .")
    else
        print("[reddisassembler] disassembling chunk . . .")
        disassembled = disassembled .. "chunk["
        if disassembler.loaded_settings.structure_corrections.protected_by == nil then
            disassembled = disassembled .. "NUPV " .. chunk.upvalues .. ", "
            disassembled = disassembled .. "NARG " .. chunk.arguments .. ", "
            disassembled = disassembled .. "PC " .. #chunk.prototypes .. ", "
            disassembled = disassembled .. "IC " .. #chunk.instructions .. ", "
            disassembled = disassembled .. "CC " .. #chunk.constants .. ", "
            disassembled = disassembled .. "FLIN " .. chunk.first_line .. "]"
        else
            disassembled = disassembled .. "]"
        end
    end

    disassembled = disassembled .. "\n"

    -- get constant info 
    for k,v in pairs(chunk.constants) do
        if disassembler.loaded_settings.constant_type == "table" then
            local data = v.data
            if tonumber(data) == nil then
                data = "'" .. tostring(data) .. "'"
            else
                chunk.constants[k].data = disassembler:round(tonumber(data))
                data = chunk.constants[k].data
            end
            disassembled = disassembled .. ".constant\t" .. data .. "\n"
            has_constants = true
        elseif disassembler.loaded_settings.constant_type == "value" then
            local data = v
            if tonumber(data) == nil then
                data = "'" .. tostring(data) .. "'"
            else
                chunk.constants[k] = disassembler:round(tonumber(data))
                data = chunk.constants[k]
            end
            disassembled = disassembled .. ".constant\t" .. data .. "\n"
            has_constants = true
        end
    end

    if has_constants then
        disassembled = disassembled .. "\n"
    end

    -- disassemble instructions 

    for k,v1 in pairs(chunk.instructions) do
        if disassembler.loaded_settings.register_merging then
            setmetatable(v1, {
                __index = function(t, k) -- t["Bx"]
                    if disassembler.merged_registers[k] ~= nil then
                        return t[disassembler.merged_registers[k]];
                    end
                end
            });
        end

        disassembled = disassembled ..  disassembler:disassemble_instruction(chunk, v1, program_counter) .. "\n"
        program_counter = program_counter + 1
    end

    -- write output to file this is pretty bad will rewrite later 
    table.insert(disassembler.decompiled_chunks, disassembled)
    local file = io.open("disassembled.dout", "w")
    io.output(file)
    io.write("")
    io.close(file)
    local file = io.open("disassembled.dout", "a")
    io.output(file)
    local dec = ""
    for k,v in pairs(disassembler.decompiled_chunks) do
        dec = dec .. v .. "\n"
    end 
    io.write(dec)
    io.close(file)

    print("[reddisassembler] finished disassembling chunk: " .. #disassembler.decompiled_chunks)

    return disassembled
end

return disassembler
