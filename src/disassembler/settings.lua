local op_signature = {
    sig0 = {"sBx"},
    sig1 = {"A"},
    sig2 = {"A", "B"},
    sig3 = {"A", "Bx"},
    sig4 = {"A", "C"},
    sig5 = {"A", "sBx"},
    sig6 = {"A", "B", "C"}
}

local instructions = {
    {opcode = 0, opname = "move", opargs = op_signature.sig1},
    {opcode = 1, opname = "loadk", opargs = op_signature.sig3},
    {opcode = 2, opname = "loadbool", opargs = op_signature.sig5},
    {opcode = 3, opname = "loadnil", opargs = op_signature.sig1},
    {opcode = 4, opname = "getupval", opargs = op_signature.sig1},
    {opcode = 5, opname = "getglobal", opargs = op_signature.sig3},
    {opcode = 6, opname = "gettable", opargs = op_signature.sig5},
    {opcode = 7, opname = "setglobal", opargs = op_signature.sig2},
    {opcode = 8, opname = "setupval", opargs = op_signature.sig1},
    {opcode = 9, opname = "settable", opargs = op_signature.sig5},
    {opcode = 10, opname = "newtable", opargs = op_signature.sig5},
    {opcode = 11, opname = "self", opargs = op_signature.sig5},
    {opcode = 12, opname = "add", opargs = op_signature.sig5},
    {opcode = 13, opname = "sub", opargs = op_signature.sig5},
    {opcode = 14, opname = "mul", opargs = op_signature.sig5},
    {opcode = 15, opname = "div", opargs = op_signature.sig5},
    {opcode = 16, opname = "mod", opargs = op_signature.sig5},
    {opcode = 17, opname = "pow", opargs = op_signature.sig5},
    {opcode = 18, opname = "unm", opargs = op_signature.sig1},
    {opcode = 19, opname = "not", opargs = op_signature.sig1},
    {opcode = 20, opname = "len", opargs = op_signature.sig1},
    {opcode = 21, opname = "concat", opargs = op_signature.sig5},
    {opcode = 22, opname = "jmp", opargs = op_signature.sig0},
    {opcode = 23, opname = "eq", opargs = op_signature.sig6},
    {opcode = 24, opname = "lt", opargs = op_signature.sig5},
    {opcode = 25, opname = "le", opargs = op_signature.sig5},
    {opcode = 26, opname = "test", opargs = op_signature.sig3},
    {opcode = 27, opname = "testset", opargs = op_signature.sig5},
    {opcode = 28, opname = "call", opargs = op_signature.sig6},
    {opcode = 29, opname = "tailcall", opargs = op_signature.sig5},
    {opcode = 30, opname = "return", opargs = op_signature.sig2},
    {opcode = 31, opname = "forloop", opargs = op_signature.sig4},
    {opcode = 32, opname = "forprep", opargs = op_signature.sig4},
    {opcode = 33, opname = "tforloop", opargs = op_signature.sig3},
    {opcode = 34, opname = "setlist", opargs = op_signature.sig5},
    {opcode = 35, opname = "close", opargs = op_signature.sig0},
    {opcode = 36, opname = "closure", opargs = op_signature.sig2},
    {opcode = 37, opname = "vararg", opargs = op_signature.sig1}
}

local settings = {
    deserialization = {
        instruction = {
            opcode = {0, 5},   -- {0+1, 5+1}
            reg_a = {6, 13},   -- {6+1, 13+1}
            reg_b = {23, 31},  -- {23+1, 31+1}
            reg_c = {14, 22},  -- {14+1, 22+1}
            reg_bx = {14, 31}, -- {14+1, 31+1}
            sub_sbx = 131071
        },
        constant = {
            constant_type = "table"
        }
    },
    tables = {
        op_sigs = op_signature
    },
    get_opname = function(vxdwd, opcode)
        for k,v in pairs(instructions) do
            if v.opcode == opcode then
                return v.opname
            end
        end
        return "unknown"
    end,
    get_instruction = function(cjwsijdw, opcode)
        for k,v in pairs(instructions) do
            if v.opcode == opcode then
                return v
            end
        end
        return nil
    end
}

return settings
