-- Disassembler driver: needs fixtures/build.sh to have been run.

local H = require("helpers")
local disasm = require("neomax.configs.asm.disasm")
local lines = require("neomax.configs.asm.lines")

local C = H.binary("demo")
if not C then
  return H.skip("disasm", "fixtures/build.sh has not been run")
end

local r = H.sync(function(cb)
  disasm.disassemble(C, { symbol = "sum_squares" }, cb)
end)
local m, err = r[1], r[2]
H.ok(m ~= nil, "disassembles a symbol", err)
H.ok(m and m.has_debug_info, "detects the line table")
H.eq(m and #m.syms, 1, "narrowed to one symbol")

-- the range comes from the ELF symbol size, so nothing spills past the symbol
local lo, hi = math.huge, 0
for _, row in ipairs(m.rows) do
  if row.kind == "insn" then
    lo, hi = math.min(lo, row.addr), math.max(hi, row.addr)
  end
end
local sym = H.sync(function(cb)
  disasm.symbols(C, cb)
end)[1]
local ss
for _, s in ipairs(sym) do
  if s.name == "sum_squares" then
    ss = s
  end
end
H.eq(lo, ss.addr, "disassembly starts at the symbol")
H.ok(hi < ss.addr + ss.size, "and stops at its end")

-- caching keyed on artifact identity
local before = vim.tbl_count(disasm.cache)
H.ok(H.sync(function(cb)
  disasm.disassemble(C, { symbol = "sum_squares" }, cb)
end)[1] == m, "a repeat call is served from cache")
H.eq(vim.tbl_count(disasm.cache), before, "the cache does not grow on a hit")
disasm.invalidate(C)
H.eq(vim.tbl_count(disasm.cache), 0, "invalidate clears the artifact")

-- errors are reported, not swallowed
H.ok(H.sync(function(cb)
  disasm.disassemble("/nonexistent/xyz", {}, cb)
end)[2]
  :match("no such artifact") ~= nil, "a missing artifact is reported")
H.ok(H.sync(function(cb)
  disasm.disassemble(C, { symbol = "no_such_fn" }, cb)
end)[2]
  :match("symbol not found") ~= nil, "an unknown symbol is reported")

-- === Zig: symbol names with commas break --disassemble-symbols= ===
-- That flag takes a comma-separated list, so generic instantiations matched
-- nothing. Resolving to an address range instead is name-agnostic.
local Z = H.binary("demo-zig")
if Z then
  local zsyms = H.sync(function(cb)
    disasm.symbols(Z, cb)
  end)[1]
  H.ok(zsyms and #zsyms > 100, "reads a large symbol table", zsyms and #zsyms)

  local awkward
  for _, s in ipairs(zsyms or {}) do
    if s.name:find(",", 1, true) and s.size > 0 and not awkward then
      awkward = s
    end
  end
  H.ok(awkward ~= nil, "finds a symbol with a comma in its name")
  if awkward then
    local zr = H.sync(function(cb)
      disasm.disassemble(Z, { symbol = awkward.name }, cb)
    end)
    H.ok(zr[1] ~= nil, "a comma-bearing symbol still disassembles", zr[2])
  end

  local zidx = H.sync(function(cb)
    lines.load(Z, cb)
  end)[1]
  H.ok(zidx ~= nil, "reads the Zig line table")
else
  H.skip("zig disassembly", "build/demo-zig absent")
end

-- a stripped binary reports the missing line table rather than failing oddly
local stripped = vim.fn.tempname()
os.execute(("cp %s %s && strip %s 2>/dev/null"):format(C, stripped, stripped))
local sr = H.sync(function(cb)
  lines.load(stripped, cb)
end)
H.ok(sr[1] == nil and sr[2] and sr[2]:match("no line table"), "a stripped binary reports missing debug info", sr[2])
