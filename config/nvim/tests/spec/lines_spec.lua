-- DWARF line table reader. Pure: runs off a committed dwarfdump.

local H = require("helpers")
local lines = require("neomax.configs.asm.lines")
local model = require("neomax.configs.asm.model")

local idx = lines.parse(H.read_fixture("dwarfdump-c.txt"))

local demo
for f in pairs(idx.by_src) do
  if f:match("demo%.c$") then
    demo = f
  end
end

H.ok(demo ~= nil, "indexes the source file", vim.inspect(vim.tbl_keys(idx.by_src)))
H.ok(demo:sub(1, 1) == "/", "joins file_names with include_directories", demo)
local header = false
for f in pairs(idx.by_src) do
  if f:match("%.h$") then
    header = true
  end
end
H.ok(header, "indexes headers the code was inlined from")
H.ok(idx.by_src[demo][4] and #idx.by_src[demo][4] > 0, "line 4 has addresses")
H.eq(idx.by_src[demo][0], nil, "line 0 bookkeeping rows are dropped")

-- === agreement with the disassembly-based resolver ===
-- Both paths must give the same answer, or pin would behave differently
-- depending on which one happened to run.
local m = model.parse(H.read_fixture("objdump-c.txt"))
local mdemo
for f in pairs(m.by_src) do
  if f:match("demo%.c$") then
    mdemo = f
  end
end

-- the fixture's nm listing, derived from the dump's own symbol headers
local syms = {}
for _, s in ipairs(m.syms) do
  syms[#syms + 1] = { name = s.name, addr = s.addr, size = 0 }
end
table.sort(syms, function(a, b)
  return a.addr < b.addr
end)

local compared, agreed, diffs = 0, 0, {}
for line = 1, 20 do
  local a = model.symbol_near(m, mdemo, line)
  local b = lines.symbol_near(idx, syms, demo, line)
  if a or b then
    compared = compared + 1
    if a == b then
      agreed = agreed + 1
    else
      diffs[#diffs + 1] = ("line %d: model=%s lines=%s"):format(line, tostring(a), tostring(b))
    end
  end
end
H.ok(compared > 10, "compares a useful number of lines", compared)
H.eq(agreed, compared, "line table and disassembly agree on every line\n       " .. table.concat(diffs, "\n       "))
H.eq(lines.symbol_near(idx, syms, demo, 4), "sum_squares", "picks the narrowest symbol for an inlined line")

-- === address lookup boundaries ===
local ss
for _, s in ipairs(syms) do
  if s.name == "sum_squares" then
    ss = s
  end
end
H.eq(lines.symbol_for_addr(syms, ss.addr).name, "sum_squares", "address at a symbol start")
H.ok((lines.symbol_for_addr(syms, 0x1) or {}).name ~= "sum_squares", "address below every symbol")
H.eq(lines.symbol_for_addr({}, 0x1000), nil, "empty symbol table")
