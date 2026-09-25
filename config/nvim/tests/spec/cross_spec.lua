-- Cross-architecture coverage.
--
-- Nothing in the module names an instruction set: it parses objdump's output
-- format and the DWARF line table, and passes no target flags. These specs
-- hold that line, and pin the symbol-table filtering that RISC-V forced.

local H = require("helpers")
local disasm = require("neomax.configs.asm.disasm")
local lines = require("neomax.configs.asm.lines")
local model = require("neomax.configs.asm.model")

local TARGETS = {
  { name = "aarch64", binary = "demo-aarch64-linux" },
  { name = "riscv64", binary = "demo-riscv64-linux" },
}

for _, target in ipairs(TARGETS) do
  local bin = H.binary(target.binary)
  if not bin then
    H.skip(target.name, "fixtures/build.sh has not cross-compiled it")
  else
    local m = H.sync(function(cb)
      disasm.disassemble(bin, { symbol = "sumSquares" }, cb)
    end)[1]
    H.ok(m ~= nil, target.name .. ": disassembles a symbol")

    if m then
      local insns, mapped = 0, 0
      for _, row in ipairs(m.rows) do
        if row.kind == "insn" then
          insns = insns + 1
          if row.file and row.line then
            mapped = mapped + 1
          end
        end
      end
      H.ok(insns > 0, target.name .. ": parses instructions", insns)
      H.eq(mapped, insns, target.name .. ": every instruction carries a source position")

      -- mnemonics are whatever the target uses; we only require that the
      -- parser split them off cleanly rather than swallowing the operands
      local clean = true
      for _, row in ipairs(m.rows) do
        if row.kind == "insn" and (row.mnemonic == "" or row.mnemonic:find("%s")) then
          clean = false
        end
      end
      H.ok(clean, target.name .. ": mnemonics separated from operands")
    end

    -- === the symbol-table fix ===
    local syms = H.sync(function(cb)
      disasm.symbols(bin, cb)
    end)[1]
    H.ok(syms and #syms > 0, target.name .. ": reads the symbol table", syms and #syms)

    local internal = {}
    for _, s in ipairs(syms or {}) do
      if s.name:match("^%.L") or s.name:match("^%$[adtx]%.?") then
        internal[#internal + 1] = s.name
      end
    end
    H.eq(#internal, 0, target.name .. ": assembler-internal symbols filtered out")

    local ordered = true
    for i = 2, #syms do
      if syms[i].addr < syms[i - 1].addr then
        ordered = false
      end
    end
    H.ok(ordered, target.name .. ": symbols address-ordered")

    -- === resolution through the line table ===
    local idx = H.sync(function(cb)
      lines.load(bin, cb)
    end)[1]
    H.ok(idx ~= nil, target.name .. ": reads the DWARF line table")

    if idx and syms then
      local file
      for f in pairs(idx.by_src) do
        if f:match("main%.zig$") then
          file = f
        end
      end
      H.ok(file ~= nil, target.name .. ": indexes the source file")
      if file then
        -- Before the fix this returned ".L0" on RISC-V: 61k local labels sat
        -- at arbitrary addresses and shadowed the real function.
        H.eq(lines.symbol_near(idx, syms, file, 6), "sumSquares", target.name .. ": resolves the loop to sumSquares")
      end

      -- a global symbol wins over a local alias at the same address
      local ss
      for _, s in ipairs(syms) do
        if s.name == "sumSquares" then
          ss = s
        end
      end
      if ss then
        H.eq(lines.symbol_for_addr(syms, ss.addr).name, "sumSquares", target.name .. ": global beats local alias")
        H.eq(
          lines.symbol_for_addr(syms, ss.addr + ss.size - 1).name,
          "sumSquares",
          target.name .. ": last byte still inside the symbol"
        )
      end
    end

    -- === slicing works the same everywhere ===
    if m then
      local rows = model.slice(m, { kind = "symbol", name = "sumSquares" })
      H.ok(rows and #rows > 0, target.name .. ": slices the symbol")
      H.eq(m.rows[rows[1]].kind, "sym", target.name .. ": slice starts at the header")
    end
  end
end
