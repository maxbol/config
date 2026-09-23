-- Parser and indexing. Pure: runs off committed dumps, no toolchain needed.
-- This is the spec that guards against a compiler changing its output format.

local H = require("helpers")
local model = require("neomax.configs.asm.model")

local c = model.parse(H.read_fixture("objdump-c.txt"))

local function sym(m, name)
  for _, s in ipairs(m.syms) do
    if s.name == name then
      return s
    end
  end
end

local demo
for f in pairs(c.by_src) do
  if f:match("demo%.c$") then
    demo = f
  end
end

H.ok(#c.rows > 0, "parses rows")
H.eq(#c.syms, 13, "finds every symbol")
H.ok(demo ~= nil, "indexes the source file")
H.eq(sym(c, "sum_squares").addr, 0x11b0, "records symbol addresses")

-- atoi is inlined from a libc header: inlining across files is captured
local headers = 0
for _, f in ipairs(model.files(c)) do
  if f:match("%.h$") then
    headers = headers + 1
  end
end
H.ok(headers > 0, "indexes code inlined from headers")

-- square() at line 4 was inlined into sum_squares, and sum_squares in turn
-- inlined into main: one source line, two symbols. This is the case the
-- split view exists to show, so it is the load-bearing assertion here.
local inlined = c.by_src[demo][4]
H.eq(#inlined, 4, "line 4 produced four instructions")
local in_syms = {}
for _, idx in ipairs(inlined) do
  in_syms[c.rows[idx].sym] = true
end
H.eq(vim.tbl_count(in_syms), 2, "line 4 spans two symbols")
H.ok(in_syms.sum_squares and in_syms.main, "inlined into both sum_squares and main")
local mnems = {}
for _, idx in ipairs(inlined) do
  mnems[#mnems + 1] = c.rows[idx].mnemonic
end
H.eq(mnems, { "movl", "imull", "movl", "imull" }, "both copies are the same multiply")

-- the mapping is non-monotonic, which is why both directions need real indexes
local ss, seen = sym(c, "sum_squares"), {}
for i = ss.first_insn, ss.last_insn do
  local r = c.rows[i]
  if r.kind == "insn" and r.line and seen[#seen] ~= r.line then
    seen[#seen + 1] = r.line
  end
end
H.eq(seen, { 8, 7, 4, 8, 9, 8, 12, 7, 12 }, "source lines are revisited out of order")

-- a symbol built without debug info must not inherit the previous position
local init, bled = sym(c, "_init"), 0
for i = init.first_insn, init.last_insn do
  if c.rows[i].kind == "insn" and c.rows[i].file then
    bled = bled + 1
  end
end
H.eq(bled, 0, "source positions do not bleed across symbol boundaries")

H.ok(c.labels["L0"] ~= nil, "indexes local labels")
H.eq(model.insn_count(c, demo, 4), 4, "counts instructions per source line")
H.eq(model.insn_count(c, demo, 999), 0, "unmapped lines count zero")

-- === slices ===
local rows, err = model.slice(c, { kind = "symbol", name = "sum_squares" })
H.ok(rows ~= nil, "slices a symbol", err)
H.eq(c.rows[rows[1]].kind, "sym", "slice starts at the symbol header")
local strays = 0
for _, i in ipairs(rows) do
  if c.rows[i].kind == "insn" and c.rows[i].sym ~= "sum_squares" then
    strays = strays + 1
  end
end
H.eq(strays, 0, "slice holds only that symbol")
H.ok(select(1, model.slice(c, { kind = "symbol", name = "nope" })) == nil, "unknown symbol errors")
H.eq(#model.slice(c, { kind = "all" }), #c.rows, "whole-binary slice is every row")

local fslice = model.slice(c, { kind = "file", file = demo })
H.ok(fslice ~= nil and #fslice > 0, "slices a file")
local fsyms = {}
for _, i in ipairs(fslice) do
  if c.rows[i].kind == "insn" then
    fsyms[c.rows[i].sym] = true
  end
end
H.ok(vim.tbl_count(fsyms) >= 2, "file slice spans the symbols the file was inlined into")
H.ok(select(1, model.slice(c, { kind = "file", file = "/nope.c" })) == nil, "file with no code errors")

-- === rendering ===
-- Correlation in both directions rests on these two maps being exact
-- inverses over the rendered slice.
local render = require("neomax.configs.asm.render")
local out, line_to_row, row_to_line = render.render(c, rows, { relative_to = "/" })
H.eq(#out, #rows, "renders one line per row")
H.ok(out[1]:match("^%x+ <sum_squares>:$") ~= nil, "renders the symbol header", out[1])
local inverse_ok = true
for line, row in pairs(line_to_row) do
  if row_to_line[row] ~= line then
    inverse_ok = false
  end
end
H.ok(inverse_ok, "line_to_row and row_to_line are exact inverses")
H.eq(line_to_row[1], rows[1], "the first rendered line is the first row")

-- === symbol_at / symbol_near ===
local best, all = model.symbol_at(c, demo, 4)
H.eq(#all, 2, "symbol_at reports every candidate")
H.eq(best, "sum_squares", "symbol_at prefers the narrowest covering symbol over the inliner")
H.eq(model.symbol_at(c, demo, 15), "main", "a main-only line resolves to main")
H.eq(select(1, model.symbol_at(c, demo, 999)), nil, "unmapped line has no symbol")
H.eq(select(1, model.symbol_near(c, demo, 999, 3)), nil, "symbol_near respects its radius")
H.eq(select(1, model.symbol_near(c, demo, 5)), "sum_squares", "symbol_near finds the enclosing function")

-- === awkward symbol names (Zig generics) ===
local z = model.parse(H.read_fixture("objdump-zig-generics.txt"))
H.ok(#z.syms >= 2, "parses Zig generic instantiations", #z.syms)
local commas, parens = false, false
for _, s in ipairs(z.syms) do
  commas = commas or s.name:find(",", 1, true) ~= nil
  parens = parens or s.name:find("(", 1, true) ~= nil
end
H.ok(commas, "keeps commas in symbol names")
H.ok(parens, "keeps parens in symbol names")
local zi = 0
for _, r in ipairs(z.rows) do
  if r.kind == "insn" then
    zi = zi + 1
  end
end
H.ok(zi > 0, "parses instructions for generic symbols", zi)
