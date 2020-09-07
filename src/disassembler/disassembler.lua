local disassembler = {
	loaded_settings = {},
	disassembled = ""
}

-- REQUIRES
local TextStream = require("disassembler\\textstream")

function disassembler:load_settings(settings)
    disassembler.loaded_settings = settings
end

function disassembler:reverse_indexes(t)
    local a, b = 1, #t
    while a < b do
        t[a], t[b] = t[b], t[a]
        a = b + 1
        a = b - 1
    end
end

function disassembler:get_bits(input, n, n2)
	if n2 then
		local total = 0
		local digitn = 0
		for i = n, n2 do
			total = total + 2^digitn*disassembler:get_bits(input, i)
			digitn = digitn + 1
		end
		return total
	else
		local pn = 2^(n-1)
		return (input % (pn + pn) >= pn) and 1 or 0
	end
end

function disassembler:disassemble_file(file, fileloc)
	local file = assert(io.open(file, 'rb'))
	local str = file:read("*a")
	disassembler:disassemble(str, fileloc)
end

function disassembler:disassemble(bytecode, fileloc)
	local index = 1
	local big_endian = false
    local int_size;
    local size_t;

    -- Actual binary decoding functions. Dependant on the bytecode.
    local get_int, get_size_t;

	-- Binary decoding helper functions
	local get_int8, get_int32, get_int64, get_float64, get_string;
	do
		function get_int8()
			local a = bytecode:byte(index, index);
			index = index + 1
			return a
		end
		function get_int32()
            local a, b, c, d = bytecode:byte(index, index + 3);
            index = index + 4;
            return d * 16777216 + c * 65536 + b * 256 + a
        end
        function get_int64()
            local a = get_int32();
            local b = get_int32();
            return b * 4294967296 + a;
        end

		function get_float64()
			local a = get_int32()
			local b = get_int32()
			return (-2 * disassembler:get_bits(b, 32) + 1) * (2 ^ (disassembler:get_bits(b, 21, 31) - 1023)) *
			       ((disassembler:get_bits(b, 1, 20) * (2 ^ 32) + a) / (2 ^ 52)+1)
        end
        
		function get_string(len)
			local str;
            if len then
	            str = bytecode:sub(index, index + len - 1);
	            index = index + len;
            else
                len = get_size_t();
	            if len == 0 then return; end
	            str = bytecode:sub(index, index + len - 1);
	            index = index + len;
            end
            return str;
        end
    end
    
	local function decode_chunk()
		local chunk_info = TextStream:new()
		local constant_info = TextStream:new()
		local instruction_info = TextStream:new()
		constant_info.columnMargin = 1

		local chunk;
		local instructions = {};
		local constants    = {};
		local prototypes   = {};
		local debug = {
			lines = {};
		};

		chunk = {
			instructions = instructions;
			constants    = constants;
			prototypes   = prototypes;
			debug = debug;
		};

		-- big brain hack
		local function applyJumpLines(stream, jumpTo, jumpFrom)
			local step = 1
			if jumpTo < jumpFrom then step = -1 end
			for i = jumpFrom, jumpTo, step do
				local jumpText = ""
				if i == jumpFrom then
					jumpText = '+---'
				elseif i == jumpTo then
					jumpText = 'o-->'
				else
					if step == -1 then
						if i < jumpFrom and i > jumpTo then jumpText = '|' end
					else
						if i > jumpFrom and i < jumpTo then jumpText = '|' end
					end
				end
				stream:changeColumn(i, 3, jumpText)
			end
		end

		local num;

		get_string();-- Function name
		local func_offset = index
		chunk.first_line = get_int();	-- First line
		chunk.last_line  = get_int();	-- Last  line

        if chunk.name then chunk.name = chunk.name:sub(1, -2); end

		chunk.upvalues  = get_int8();
		chunk.arguments = get_int8();
		chunk.varg      = get_int8();
		chunk.stack     = get_int8();

		chunk_info:addToRow(1, 1, "func_" .. string.format("%4.8X", func_offset) .. '[NUPV ' .. chunk.upvalues .. ', ' .. 'NARG ' .. chunk.arguments .. ']')
        -- TODO: realign lists to 1
		-- Decode instructions
		do
			num = get_int();
			for i = 1, num do
				local instruction = {
					-- opcode = opcode number;
					-- type   = [ABC, ABx, AsBx]
					-- A, B, C, Bx, or sBx depending on type
				};

				local data   = get_int32();
                local opcode = disassembler:get_bits(data, 
                    disassembler.loaded_settings.deserialization.instruction.opcode[1]+1, 
                    disassembler.loaded_settings.deserialization.instruction.opcode[2]+1);

				instruction.address = index
				instruction.opcode = opcode;

                instruction.A = disassembler:get_bits(data, 
                    disassembler.loaded_settings.deserialization.instruction.reg_a[1]+1, 
                    disassembler.loaded_settings.deserialization.instruction.reg_a[1]+1);
				instruction.B = disassembler:get_bits(data, 
					disassembler.loaded_settings.deserialization.instruction.reg_b[1]+1, 
					disassembler.loaded_settings.deserialization.instruction.reg_b[2]+1);
				instruction.C = disassembler:get_bits(data, 
					disassembler.loaded_settings.deserialization.instruction.reg_c[1]+1, 
					disassembler.loaded_settings.deserialization.instruction.reg_c[2]+1);
				instruction.Bx = disassembler:get_bits(data, 
					disassembler.loaded_settings.deserialization.instruction.reg_bx[1]+1, 
					disassembler.loaded_settings.deserialization.instruction.reg_bx[2]+1);
				instruction.sBx = disassembler:get_bits(data, 
					disassembler.loaded_settings.deserialization.instruction.reg_bx[1]+1, 
					disassembler.loaded_settings.deserialization.instruction.reg_bx[2]+1) - disassembler.loaded_settings.deserialization.instruction.sub_sbx;

				instructions[i] = instruction;
			end
		end

		-- Decode constants
		do
			num = get_int();
			for i = 1, num do
				local constant = {
					-- type = constant type;
					-- data = constant data;
				};
				local type = get_int8();
				constant.type = type;

				if type == 1 then
					constant.data = (get_int8() ~= 0);
				elseif type == 3 then
					constant.data = get_float64();
				elseif type == 4 then
					constant.data = get_string():sub(1, -2);
				end

				constant_info:addToRow(i+1, 1, '.constant')
				constant_info:addToRow(i+1, 2, tostring(constant.data))
				
				constants[i-1] = constant;
			end
		end

		-- Decode Prototypes
		do
			num = get_int();
			for i = 1, num do
				prototypes[i-1] = decode_chunk();
			end
		end

		-- Decode debug info
        -- Not all of which is used yet.
		do
			-- line numbers
			local data = debug.lines
			num = get_int();
			for i = 1, num do
				data[i] = get_int32();
			end

			-- locals
			num = get_int();
			for i = 1, num do
				get_string():sub(1, -2);	-- local name
				get_int32();	-- local start PC
				get_int32();	-- local end   PC
			end

			-- upvalues
			num = get_int();
			for i = 1, num do
				get_string();	-- upvalue name
			end
		end

		disassembler.disassembled = disassembler.disassembled .. chunk_info:toString()
		disassembler.disassembled = disassembler.disassembled .. constant_info:toString()
		for i,instruction in pairs(chunk.instructions) do
			local opname = disassembler.loaded_settings:get_opname(instruction.opcode)
			local info = disassembler.loaded_settings:get_instruction(instruction.opcode)
			instruction_info:addToRow(i, 1, string.format("0x%4.6X", instruction.address))
			instruction_info:addToRow(i, 2, "[" .. instruction.opcode .. "]")
			instruction_info:addToRow(i, 3, '')
			instruction_info:addToRow(i, 4, opname)

			if opname == 'jmp' then
				applyJumpLines(instruction_info, i + instruction.sBx + 1, i)
			elseif opname == 'loadk' then
				instruction_info:addToRow(i, 6, '; pushes constant: ' .. chunk.constants[instruction.Bx].data .. ' onto the stack')
			elseif opname == 'eq' then
				local A, B, C = instruction.A, instruction.B, instruction.C
				A = A ~= 0
				B = B > 255 and chunk.constants[B-256].data or 'stack[' .. B .. ']'
				C = C > 255 and chunk.constants[C-256].data or 'stack[' .. C .. ']'
				instruction_info:addToRow(i, 6, '; if ((' .. B .. ' == ' .. C ..') ~= ' .. tostring(A) .. ') PC++')
			elseif opname == 'lt' then
				local A, B, C = instruction.A, instruction.B, instruction.C
				A = A ~= 0
				B = B > 255 and chunk.constants[B-256].data or 'stack[' .. B .. ']'
				C = C > 255 and chunk.constants[C-256].data or 'stack[' .. C .. ']'
				instruction_info:addToRow(i, 6, '; if ((' .. B .. ' < ' .. C ..') ~= ' .. tostring(A) .. ') PC++')
			elseif opname == 'le' then
				local A, B, C = instruction.A, instruction.B, instruction.C
				A = A ~= 0
				B = B > 255 and chunk.constants[B-256].data or 'stack[' .. B .. ']'
				C = C > 255 and chunk.constants[C-256].data or 'stack[' .. C .. ']'
				instruction_info:addToRow(i, 6, '; if ((' .. B .. ' <= ' .. C ..') ~= ' .. tostring(A) .. ') PC++')
			elseif opname == 'getglobal' then
				instruction_info:addToRow(i, 6, '; pushes global: ' .. chunk.constants[instruction.Bx].data .. ' onto the stack')
			end

			local args = ""
			local opsig = info.opargs
			for i = 1, #opsig do
				args = args .. (function() 
					if instruction[opsig[i]] > 255 then
						return instruction[opsig[i]] - 256
					end
					return instruction[opsig[i]] 
				end)()
				if i ~= #opsig then
					args = args .. ", "
				end
			end
			
			instruction_info:addToRow(i, 5, args)
		end

		disassembler.disassembled = disassembler.disassembled .. instruction_info:toString()

		return chunk;
	end

	-- get bytecode header
	do
		assert(get_string(4) == "\27Lua", "Lua bytecode expected.");
		assert(get_int8() == 0x51, "Only Lua 5.1 is supported.");
		get_int8(); 	-- Oficial bytecode
		big_endian = (get_int8() == 0);
        int_size = get_int8();
        size_t   = get_int8();

        if int_size == 4 then
            get_int = get_int32;
        elseif int_size == 8 then
            get_int = get_int64;
        else
            error("Unsupported bytecode target platform");
        end

        if size_t == 4 then
            get_size_t = get_int32;
        elseif size_t == 8 then
            get_size_t = get_int64;
        else
            error("Unsupported bytecode target platform");
        end

        assert(get_string(3) == "\4\8\0",
	           "Unsupported bytecode target platform");
	end

    local mainchunk = decode_chunk()
    print("[reddisassembler] disassembling main chunk...")
    print("[reddisassembler] main chunk:")
    print("\tchunk->sizep: " .. #mainchunk.prototypes)
    print("\tchunk->sizek: " .. #mainchunk.constants)
	print("\tchunk->sizecode: " .. #mainchunk.instructions)

	print('\n')
	local file = io.open(fileloc, 'w')
    io.output(file)
    io.write('')
    io.close(file)
    file = io.open(fileloc, 'w')
    io.output(file)
    io.write(disassembler.disassembled)
    io.close(file)
end

return disassembler
