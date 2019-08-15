local respective_signatures = {
    sig01 = {"sBx"},
    sig0 = {"A"},
    sig1 = {"A", "B"},
    sig2 = {"A", "Bx"},
    sig3 = {"A", "C"},
    sig4 = {"A", "sBx"},
    sig5 = {"A", "B", "C"}
}

local settings = {
    sBx_fix = false,
    opcode_change = 0,
    structure_corrections = {},
    tables = {
        opargs_sig_table = respective_signatures
    },
    instructions = {
        {opcode = 0, opname = "move", opargs = respective_signatures.sig1},
        {opcode = 1, opname = "loadk", opargs = respective_signatures.sig2},
        {opcode = 2, opname = "loadbool", opargs = respective_signatures.sig5},
        {opcode = 3, opname = "loadnil", opargs = respective_signatures.sig1},
        {opcode = 4, opname = "getupval", opargs = respective_signatures.sig1},
        {opcode = 5, opname = "getglobal", opargs = respective_signatures.sig2},
        {opcode = 6, opname = "gettable", opargs = respective_signatures.sig5},
        {opcode = 7, opname = "setglobal", opargs = respective_signatures.sig2},
        {opcode = 8, opname = "setupval", opargs = respective_signatures.sig1},
        {opcode = 9, opname = "settable", opargs = respective_signatures.sig5},
        {opcode = 10, opname = "newtable", opargs = respective_signatures.sig5},
        {opcode = 11, opname = "self", opargs = respective_signatures.sig5},
        {opcode = 12, opname = "add", opargs = respective_signatures.sig5},
        {opcode = 13, opname = "sub", opargs = respective_signatures.sig5},
        {opcode = 14, opname = "mul", opargs = respective_signatures.sig5},
        {opcode = 15, opname = "div", opargs = respective_signatures.sig5},
        {opcode = 16, opname = "mod", opargs = respective_signatures.sig5},
        {opcode = 17, opname = "pow", opargs = respective_signatures.sig5},
        {opcode = 18, opname = "unm", opargs = respective_signatures.sig1},
        {opcode = 19, opname = "not", opargs = respective_signatures.sig1},
        {opcode = 20, opname = "len", opargs = respective_signatures.sig1},
        {opcode = 21, opname = "concat", opargs = respective_signatures.sig5},
        {opcode = 22, opname = "jmp", opargs = respective_signatures.sig01},
        {opcode = 23, opname = "eq", opargs = respective_signatures.sig5},
        {opcode = 24, opname = "lt", opargs = respective_signatures.sig5},
        {opcode = 25, opname = "le", opargs = respective_signatures.sig5},
        {opcode = 26, opname = "test", opargs = respective_signatures.sig3},
        {opcode = 27, opname = "testset", opargs = respective_signatures.sig5},
        {opcode = 28, opname = "call", opargs = respective_signatures.sig5},
        {opcode = 29, opname = "tailcall", opargs = respective_signatures.sig5},
        {opcode = 30, opname = "return", opargs = respective_signatures.sig1},
        {opcode = 31, opname = "forloop", opargs = respective_signatures.sig4},
        {opcode = 32, opname = "forprep", opargs = respective_signatures.sig4},
        {opcode = 33, opname = "tforloop", opargs = respective_signatures.sig3},
        {opcode = 34, opname = "setlist", opargs = respective_signatures.sig5},
        {opcode = 35, opname = "close", opargs = respective_signatures.sig0},
        {opcode = 36, opname = "closure", opargs = respective_signatures.sig2},
        {opcode = 37, opname = "vararg", opargs = respective_signatures.sig1}
    }
}

return settings
