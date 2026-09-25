-- Colour banding and density hints. Needs fixtures/build.sh.

local H = require("helpers")
local view = require("neomax.configs.asm.view")
local render = require("neomax.configs.asm.render")
local disasm = require("neomax.configs.asm.disasm")

local C = H.binary("demo")
if not C then
  return H.skip("decorate", "fixtures/build.sh has not been run")
end

local SRC = H.fixtures .. "/src/c/demo.c"
local decor = vim.api.nvim_create_namespace("neomax_asm_decor")
local corr = vim.api.nvim_create_namespace("neomax_asm")

local function marks(buf, ns)
  return vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
end

-- === palette ===
render.define_bands()
H.ok(render.band_count >= 4, "enough bands to distinguish neighbours", render.band_count)
local seen_bg = {}
for i = 1, render.band_count do
  local hl = vim.api.nvim_get_hl(0, { name = "NeomaxAsmBand" .. i })
  H.ok(hl and hl.bg ~= nil, "band " .. i .. " has a background")
  seen_bg[hl.bg] = true
end
H.eq(vim.tbl_count(seen_bg), render.band_count, "every band is a distinct colour")

vim.cmd("edit " .. SRC)
local m = H.sync(function(cb)
  disasm.disassemble(C, { symbol = "sum_squares" }, cb)
end)[1]

-- === defaults ===
view.open({ artifact = C, model = m, symbol = "sum_squares", root = H.fixtures .. "/src/c" })
local st = view.state
-- Both defaults are user preferences, so assert the view honours whatever is
-- configured rather than pinning a particular choice.
H.eq(st.banding, view.banding_by_default, "banding follows the configured default")
H.eq(st.density, view.density_by_default, "density follows the configured default")

-- The rest exercises both decorations regardless of how they are configured.
if not st.density then
  view.toggle_density()
end

-- density: end-of-line counts on the source, none on the assembly
local dm = marks(st.src_buf, decor)
H.ok(#dm > 0, "density marks the source lines", #dm)
local with_virt, sample = 0, nil
for _, mark in ipairs(dm) do
  if mark[4].virt_text then
    with_virt = with_virt + 1
    sample = sample or mark[4].virt_text[1][1]
  end
end
H.eq(with_virt, #dm, "every density mark is end-of-line text")
H.ok(sample and sample:match("%d+$"), "density text ends in a count", sample)
H.ok(sample and sample:match("[▁▂▃▄▅▆▇█]"), "density text carries a bar", sample)

-- the counts match what the pane actually shows
local shown = 0
for _, idx in pairs(st.line_to_row) do
  if st.render_model.rows[idx].kind == "insn" then
    shown = shown + 1
  end
end
local counted = 0
for _, mark in ipairs(dm) do
  counted = counted + tonumber(mark[4].virt_text[1][1]:match("(%d+)$"))
end
H.eq(counted, shown, "density counts add up to the instructions on screen")

-- === banding ===
view.toggle_banding()
H.ok(st.banding, "banding toggles on")
local abands, sbands = 0, 0
for _, mark in ipairs(marks(st.asm_buf, decor)) do
  if (mark[4].line_hl_group or ""):match("^NeomaxAsmBand") then
    abands = abands + 1
  end
end
local src_band_lines = {}
for _, mark in ipairs(marks(st.src_buf, decor)) do
  if (mark[4].line_hl_group or ""):match("^NeomaxAsmBand") then
    sbands = sbands + 1
    src_band_lines[mark[2] + 1] = mark[4].line_hl_group
  end
end
H.ok(abands > 0, "assembly lines are banded", abands)
H.ok(sbands > 0, "source lines are banded", sbands)
H.eq(abands, shown, "every rendered instruction gets a band")

-- neighbouring source lines must differ, which is the whole point
local ordered = vim.tbl_keys(src_band_lines)
table.sort(ordered)
local clash = nil
for i = 2, #ordered do
  if src_band_lines[ordered[i]] == src_band_lines[ordered[i - 1]] and #ordered <= render.band_count then
    clash = ordered[i]
  end
end
H.eq(clash, nil, "consecutive source lines get different bands")

-- a source line and its instructions share a band
local pairs_ok = true
for asm_line, idx in pairs(st.line_to_row) do
  local row = st.render_model.rows[idx]
  if row.kind == "insn" and row.file == st.file and row.line and src_band_lines[row.line] then
    for _, mark in ipairs(marks(st.asm_buf, decor)) do
      if mark[2] + 1 == asm_line and mark[4].line_hl_group ~= src_band_lines[row.line] then
        pairs_ok = false
      end
    end
  end
end
H.ok(pairs_ok, "an instruction carries the band of the line that produced it")

-- === decorations survive correlation, and vice versa ===
vim.api.nvim_set_current_win(st.src_win)
vim.api.nvim_win_set_cursor(st.src_win, { 4, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = st.src_buf })
H.ok(#marks(st.asm_buf, corr) > 0, "correlation still highlights")
H.ok(#marks(st.asm_buf, decor) == abands, "cursor movement does not wipe the bands")

-- === toggling back off ===
view.toggle_banding()
local left = 0
for _, mark in ipairs(marks(st.asm_buf, decor)) do
  if (mark[4].line_hl_group or ""):match("^NeomaxAsmBand") then
    left = left + 1
  end
end
H.eq(left, 0, "banding toggles off cleanly")
view.toggle_density()
H.eq(#marks(st.src_buf, decor), 0, "density toggles off cleanly")

-- === decorations follow a scope change ===
view.toggle_density()
local before = #marks(st.src_buf, decor)
H.pick("this file")
view.select_scope()
vim.wait(30000, function()
  return view.state.scope.kind == "file"
end, 20)
H.ok(#marks(st.src_buf, decor) >= before, "density re-applied for the new scope", #marks(st.src_buf, decor))

-- === cycle costs ===
local cycles_ns = vim.api.nvim_create_namespace("neomax_asm_cycles")
if vim.fn.executable("llvm-mca") == 1 then
  vim.wait(30000, function()
    return view.state.cycle_summary ~= nil
  end, 50)

  H.ok(st.cycles, "cycle costs on by default")
  H.ok(st.cycle_summary ~= nil, "block summary arrived", st.cycle_error)

  local annotations = marks(st.asm_buf, cycles_ns)
  H.ok(#annotations > 0, "instructions annotated with cycle costs", #annotations)
  local sample, hot = nil, false
  for _, mark in ipairs(annotations) do
    local text, hl = mark[4].virt_text[1][1], mark[4].virt_text[1][2]
    sample = sample or text
    if hl == "NeomaxAsmCyclesHot" then
      hot = true
    end
  end
  H.ok(sample and sample:match("%d+c · [%d%.]+"), "annotation shows latency and throughput", sample)
  H.ok(hot, "expensive instructions are marked hot")

  local winbar = vim.wo[st.asm_win].winbar
  H.ok(winbar:find("cyc/iter"), "winbar carries cycles per iteration", winbar)
  H.ok(winbar:find("IPC"), "winbar carries IPC", winbar)

  -- annotations live in their own namespace, so decoration toggles leave them
  view.toggle_banding()
  H.eq(#marks(st.asm_buf, cycles_ns), #annotations, "banding does not disturb cycle annotations")
  view.toggle_banding()

  view.toggle_cycles()
  H.eq(#marks(st.asm_buf, cycles_ns), 0, "cycle costs toggle off cleanly")
  view.toggle_cycles()
  vim.wait(30000, function()
    return #marks(st.asm_buf, cycles_ns) > 0
  end, 50)
  H.ok(#marks(st.asm_buf, cycles_ns) > 0, "and back on")
else
  H.skip("cycle costs", "llvm-mca not on PATH")
end

view.close()
H.eq(#marks(vim.api.nvim_get_current_buf(), decor), 0, "closing clears decorations from the source buffer")

-- === explicit false is respected (not swallowed by `x and y or z`) ===
view.open({ artifact = C, model = m, symbol = "sum_squares", root = H.fixtures .. "/src/c", density = false })
H.ok(not view.state.density, "density = false is respected")
view.close()
view.banding_by_default = true
view.open({ artifact = C, model = m, symbol = "sum_squares", root = H.fixtures .. "/src/c", banding = false })
H.ok(not view.state.banding, "banding = false overrides banding_by_default")
view.close()
view.banding_by_default = false
