-- The timeline: parsing llvm-mca's table, and the pane built from it.
--
-- Parsing runs off a committed llvm-mca dump, so it needs no toolchain. The
-- pane tests need the built fixtures.

local H = require("helpers")
local mca = require("neomax.configs.asm.mca")
local model = require("neomax.configs.asm.model")

--- parsing (pure) -------------------------------------------------------------

local dump = table.concat(H.read_fixture("mca-timeline-c.txt"), "\n")

-- llvm-mca indexes instructions from zero; `kept` maps that onto model rows,
-- which is also where dropped instructions are accounted for.
local kept = {}
for i = 1, 40 do
  kept[i] = i * 10
end

local parsed, err = mca.parse_timeline(dump, kept)
H.ok(parsed ~= nil, "parses a timeline", err)
H.ok(parsed.width > 0, "reads the field width from the ruler", parsed.width)
H.eq(parsed.iterations, { 0, 1, 2 }, "sees every iteration")
H.eq(parsed.iteration, 2, "defaults to the last iteration (steady state)")
H.eq(mca.parse_timeline(dump, kept, 0).iteration, 0, "an iteration can be chosen")

-- indices map through `kept`, not directly
H.ok(parsed.by_row[10] ~= nil, "instruction 0 maps to the first kept row")
H.eq(parsed.by_row[11], nil, "and not to an unmapped row")
H.eq(#parsed.ordered, 17, "one entry per instruction", #parsed.ordered)

-- states decode
local first = parsed.by_row[parsed.ordered[1]]
H.ok(first.states:find("D"), "row carries its states", first.states)
H.eq(first.states:sub(first.dispatch, first.dispatch), "D", "dispatch column points at D")
H.eq(first.states:sub(first.retire, first.retire), "R", "retire column points at R")
H.ok(first.first <= first.dispatch, "first active column is at or before dispatch")
H.ok(first.last >= first.retire, "last active column is at or after retire")

-- a zero-latency instruction never executes: D, then straight to retire
local eliminated
for _, row in ipairs(parsed.ordered) do
  local entry = parsed.by_row[row]
  if not entry.execute then
    eliminated = entry
  end
end
H.ok(eliminated ~= nil, "finds a move-eliminated instruction with no execute phase")
H.ok(
  eliminated and eliminated.states:match("^[%.%s]*D%-*R"),
  "which shows as D then wait then R",
  eliminated and eliminated.states
)

-- iteration 0 runs on a cold pipeline, so it is not representative
local cold = mca.parse_timeline(dump, kept, 0)
local function span(t)
  local lo, hi = math.huge, 0
  for _, row in ipairs(t.ordered) do
    lo = math.min(lo, t.by_row[row].first)
    hi = math.max(hi, t.by_row[row].last)
  end
  return hi - lo + 1
end
H.ok(span(cold) > 0 and span(parsed) > 0, "both iterations span real cycles")

H.eq(select(2, mca.parse_timeline("no timeline here", kept)), "llvm-mca produced no timeline", "junk input is reported")

--- the pane -------------------------------------------------------------------

local C = H.binary("demo")
if not C or vim.fn.executable("llvm-mca") == 0 then
  return H.skip("timeline pane", "needs fixtures/build.sh and llvm-mca")
end

local view = require("neomax.configs.asm.view")
local TL = require("neomax.configs.asm.timeline")
local disasm = require("neomax.configs.asm.disasm")
local SRC = H.fixtures .. "/src/c/demo.c"

vim.cmd("edit " .. SRC)
local m = H.sync(function(cb)
  disasm.disassemble(C, { symbol = "sum_squares" }, cb)
end)[1]
view.open({ artifact = C, model = m, symbol = "sum_squares", root = H.fixtures .. "/src/c" })
local st = view.state

vim.api.nvim_set_current_win(st.asm_win)
vim.api.nvim_win_set_cursor(st.asm_win, { 5, 0 })
view.timeline()
vim.wait(60000, function()
  return TL.is_open()
end, 20)

H.ok(TL.is_open(), "the pane opens")
local ts = TL.state
H.eq(#vim.api.nvim_tabpage_list_wins(0), 3, "three windows: source, assembly, timeline")
H.eq(
  vim.wo[ts.win].statuscolumn,
  "%!v:lua.NeomaxAsmTimelineGutter()",
  "the instruction column is pinned via statuscolumn"
)
H.eq(vim.wo[ts.win].wrap, false, "no wrapping")
H.eq(vim.wo[ts.win].sidescrolloff, 0, "sidescrolloff would fight the lead-column rule")
H.ok(not vim.bo[ts.buf].modifiable, "the buffer is read-only")

local count = 0
for _, idx in ipairs(m.rows) do
  if idx.kind == "insn" then
    count = count + 1
  end
end
H.eq(#ts.lines, count, "one line per instruction")
H.eq(vim.api.nvim_buf_line_count(ts.buf), #ts.lines, "buffer matches the line table")

-- the gutter must survive percent signs: %rbp would render as "bp" otherwise
local with_percent
for line, entry in ipairs(ts.lines) do
  if entry.text:find("%%") then
    with_percent = line
  end
end
H.ok(with_percent ~= nil, "found an instruction with a percent sign")
vim.v.lnum = with_percent
local gutter = _G.NeomaxAsmTimelineGutter()
H.ok(gutter:find("%%%%"), "percent signs are escaped for the statusline", gutter)
H.ok(gutter:find("#Comment#"), "and the gutter carries highlight groups", gutter)

--- following ------------------------------------------------------------------

local function asm_line_of(row)
  return st.row_to_line[row]
end
local insn_rows = {}
for _, idx in ipairs(model.slice(m, { kind = "symbol", name = "sum_squares" })) do
  if m.rows[idx].kind == "insn" then
    insn_rows[#insn_rows + 1] = idx
  end
end

local target = insn_rows[#insn_rows]
vim.api.nvim_set_current_win(st.asm_win)
vim.api.nvim_win_set_cursor(st.asm_win, { asm_line_of(target), 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = st.asm_buf })

local tline = ts.row_to_line[target]
H.ok(tline ~= nil, "the last instruction has a timeline line")
local viewinfo = vim.api.nvim_win_call(ts.win, function()
  return vim.fn.winsaveview()
end)
H.eq(viewinfo.lnum, tline, "the pane follows the assembly cursor")

-- horizontal: dispatch is kept within lead_columns of the left edge
local dispatch = ts.lines[tline].dispatch
H.eq(viewinfo.leftcol, math.max(0, dispatch - 1 - TL.lead_columns), "and scrolls so dispatch sits just inside the edge")

-- following from the source pane aims at the first instruction of that line
vim.api.nvim_set_current_win(st.src_win)
vim.api.nvim_win_set_cursor(st.src_win, { 4, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = st.src_buf })
local projected = st.render_model.by_src[st.file][4]
H.eq(
  vim.api.nvim_win_call(ts.win, function()
    return vim.fn.winsaveview().lnum
  end),
  ts.row_to_line[projected[1]],
  "the pane follows the source cursor to the first instruction that line produced"
)

--- bounded rendering ----------------------------------------------------------

local full_lines = #ts.lines
local bounds = { insn_rows[3], insn_rows[4], insn_rows[5] }
H.sync(function(cb)
  TL.open({
    model = st.render_model,
    rows = model.slice(m, { kind = "symbol", name = "sum_squares" }),
    scope = "sum_squares",
    bounds = bounds,
  }, cb)
end)
H.eq(#TL.state.lines, 3, "a bounded render shows only the selected instructions")
H.ok(#TL.state.lines < full_lines, "which is fewer than the whole symbol")

-- and the cycle window narrows with it
local narrow_width = #vim.api.nvim_buf_get_lines(TL.state.buf, 0, 1, false)[1]
H.ok(narrow_width > 0, "bounded rows still have states", narrow_width)

TL.close()
H.ok(not TL.is_open(), "closes")
H.eq(#vim.api.nvim_tabpage_list_wins(0), 2, "back to two windows")

-- closing the view closes the timeline with it
view.timeline()
vim.wait(30000, function()
  return TL.is_open()
end, 20)
H.ok(TL.is_open(), "reopened")
view.close()
H.ok(not TL.is_open(), "closing the assembly view closes the timeline too")
