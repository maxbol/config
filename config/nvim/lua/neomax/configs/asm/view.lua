-- The side-by-side source/assembly view.
--
-- Two layers, deliberately independent:
--
--   1. Line correlation, always on. Moving the cursor in either window
--      highlights the matching lines in the other. No subprocess, no
--      re-disassembly -- it is table lookups against the parsed model.
--   2. Scope re-targeting, governed by pin/follow. Changes *which* symbol is
--      rendered. Follow tracks the enclosing symbol rather than the cursor
--      line, because per-line retargeting would thrash for no benefit.

local disasm = require("neomax.configs.asm.disasm")
local model_mod = require("neomax.configs.asm.model")
local lines_mod = require("neomax.configs.asm.lines")
local docs = require("neomax.configs.asm.docs")
local mca = require("neomax.configs.asm.mca")
local render = require("neomax.configs.asm.render")

local M = {}

local ns = vim.api.nvim_create_namespace("neomax_asm")
-- Separate namespace: decorations persist while the cursor-driven correlation
-- marks are cleared and rewritten on every move.
local ns_decor = vim.api.nvim_create_namespace("neomax_asm_decor")
-- Cycle costs arrive asynchronously, so they own a namespace that can be
-- cleared without disturbing the decorations already painted.
local ns_cycles = vim.api.nvim_create_namespace("neomax_asm_cycles")
local group = vim.api.nvim_create_augroup("NeomaxAsmView", { clear = true })

vim.api.nvim_set_hl(0, "NeomaxAsmCorrelated", { default = true, link = "Visual" })
vim.api.nvim_set_hl(0, "NeomaxAsmSibling", { default = true, link = "CursorLine" })
vim.api.nvim_set_hl(0, "NeomaxAsmDensity", { default = true, link = "Comment" })
vim.api.nvim_set_hl(0, "NeomaxAsmCycles", { default = true, link = "Comment" })
vim.api.nvim_set_hl(0, "NeomaxAsmCyclesHot", { default = true, link = "WarningMsg" })

---Whether a freshly opened view tracks the cursor across functions. Set to
---false in your config to open pinned instead.
M.follow_by_default = true

---Colour-bands each source line and its instructions so the correspondence is
---visible without moving the cursor. Off by default: it is deliberately loud.
M.banding_by_default = false

---Shows how many instructions each source line produced, as end-of-line text.
M.density_by_default = false

---Annotates each instruction with latency and reciprocal throughput, and puts
---a block summary in the winbar.
M.cycles_by_default = true

---Iterations of the block to simulate in the timeline view.
M.timeline_iterations = 3

---Cycles to render in the timeline, or 0 for no limit.
---
---llvm-mca's own default is 80, which truncates almost any real function --
---the view exists to show the whole thing, so it is unlimited here. One
---column per cycle, so a very long function produces a very wide buffer;
---set a number to cap it.
M.timeline_cycles = 0

---Latency at or above this is marked hot. Not a hard rule -- it just makes
---the multiplies and divides stand out from the moves.
M.hot_latency = 3

---Only one view at a time: a second would have no unambiguous source window.
---@type table|nil
M.state = nil

---Forward declared: goto_source re-attaches after switching the source file.
local attach

---`a and a.x or default` silently drops an explicit false, so options that may
---legitimately be false go through here.
local function opt(value, fallback)
  if value ~= nil then
    return value
  end
  return fallback
end

---The symbol currently rendered, if any. Used to hold your place across a
---rebuild at a different optimisation level.
---@return string|nil
function M.current_scope()
  local st = M.state
  if M.is_open() and st.scope and st.scope.kind == "symbol" then
    return st.scope.name
  end
end

function M.is_open()
  local st = M.state
  return st ~= nil and vim.api.nvim_win_is_valid(st.asm_win) and vim.api.nvim_buf_is_valid(st.asm_buf)
end

--- Path plumbing -----------------------------------------------------------

---Maps a buffer path onto the key the compiler recorded in the line table.
---They differ whenever the build ran from another directory, so fall back to
---matching on trailing path components.
---@return string|nil
---@diagnostic disable-next-line: duplicate-set-field
function M.resolve_file(model, bufpath)
  if bufpath == nil or bufpath == "" then
    return nil
  end

  model._filekey = model._filekey or {}
  local cached = model._filekey[bufpath]
  if cached ~= nil then
    return cached ~= false and cached or nil
  end

  local real = vim.uv.fs_realpath(bufpath) or bufpath
  local found = model.by_src[real] and real or nil

  if not found then
    for key in pairs(model.by_src) do
      local kreal = vim.uv.fs_realpath(key) or key
      if kreal == real then
        found = key
        break
      end
      if vim.endswith(real, "/" .. key) or vim.endswith(key, "/" .. real) then
        found = found or key
      end
    end
  end

  model._filekey[bufpath] = found or false
  return found
end

--- Window helpers ----------------------------------------------------------

local function ensure_visible(win, line)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local buf = vim.api.nvim_win_get_buf(win)
  line = math.max(1, math.min(line, vim.api.nvim_buf_line_count(buf)))

  local view = vim.api.nvim_win_call(win, function()
    return { top = vim.fn.line("w0"), bottom = vim.fn.line("w$") }
  end)

  vim.api.nvim_win_set_cursor(win, { line, 0 })

  -- Only recentre when the target actually scrolled off, so ordinary
  -- navigation inside the visible range doesn't jump the other pane around.
  if line < view.top or line > view.bottom then
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zz")
    end)
  end
end

local function clear_marks()
  local st = M.state
  if not st then
    return
  end
  for _, buf in ipairs({ st.asm_buf, st.src_buf }) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    end
  end
end

local function mark(buf, line, hl)
  if vim.api.nvim_buf_is_valid(buf) and line >= 1 and line <= vim.api.nvim_buf_line_count(buf) then
    vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, { line_hl_group = hl, priority = 200 })
  end
end

--- Decorations --------------------------------------------------------------

local BARS = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }

---Assigns every source line in view a band, and paints it on both panes.
---
---Bands run in source-line order so neighbouring lines never share a colour,
---which is what makes a block of assembly readable as "this came from those
---three lines" at a glance.
local function apply_bands(st)
  if not st.banding or not st.file then
    return
  end

  local seen = {}
  for _, idx in pairs(st.line_to_row) do
    local row = st.render_model.rows[idx]
    if row.kind == "insn" and row.file == st.file and row.line then
      seen[row.line] = true
    end
  end

  local ordered = vim.tbl_keys(seen)
  table.sort(ordered)

  local band_of = {}
  for i, src_line in ipairs(ordered) do
    band_of[src_line] = "NeomaxAsmBand" .. ((i - 1) % render.band_count + 1)
  end

  local function paint(buf, line, hl)
    if vim.api.nvim_buf_is_valid(buf) and line >= 1 and line <= vim.api.nvim_buf_line_count(buf) then
      vim.api.nvim_buf_set_extmark(buf, ns_decor, line - 1, 0, { line_hl_group = hl, priority = 100 })
    end
  end

  for asm_line, idx in pairs(st.line_to_row) do
    local row = st.render_model.rows[idx]
    if row.kind == "insn" and row.file == st.file and row.line and band_of[row.line] then
      paint(st.asm_buf, asm_line, band_of[row.line])
    end
  end
  for src_line, hl in pairs(band_of) do
    paint(st.src_buf, src_line, hl)
  end
end

---Marks each source line with how many instructions it produced, scaled
---against the heaviest line in view. The cheapest possible answer to "what did
---this line actually cost me", without opening the assembly pane at all.
local function apply_density(st)
  if not st.density or not st.file then
    return
  end

  local per_file = st.render_model.by_src[st.file]
  if not per_file then
    return
  end

  -- Count only what is actually rendered, so the numbers match the pane.
  local counts, heaviest = {}, 0
  for line, idxs in pairs(per_file) do
    local n = 0
    for _, idx in ipairs(idxs) do
      if st.row_to_line[idx] then
        n = n + 1
      end
    end
    if n > 0 then
      counts[line] = n
      heaviest = math.max(heaviest, n)
    end
  end

  local total = vim.api.nvim_buf_line_count(st.src_buf)
  for line, n in pairs(counts) do
    if line >= 1 and line <= total then
      local bar = BARS[math.min(#BARS, math.max(1, math.ceil(n / heaviest * #BARS)))]
      vim.api.nvim_buf_set_extmark(st.src_buf, ns_decor, line - 1, 0, {
        virt_text = { { ("  %s %d"):format(bar, n), "NeomaxAsmDensity" } },
        virt_text_pos = "eol",
        priority = 100,
      })
    end
  end
end

---The winbar carries the numbers that a per-instruction figure cannot give:
---what one pass through the block costs, and whether it is front-end or
---latency bound. The CPU model is named so the figures are never
---context-free.
local function set_winbar(st)
  if not vim.api.nvim_win_is_valid(st.asm_win) then
    return
  end

  local scope = st.scope.kind == "symbol" and st.scope.name or st.scope.kind
  local parts = { scope }

  local summary = st.cycle_summary
  if summary then
    if summary.cycles_per_iteration then
      parts[#parts + 1] = ("%.2f cyc/iter"):format(summary.cycles_per_iteration)
    end
    if summary.ipc then
      parts[#parts + 1] = ("IPC %.2f"):format(summary.ipc)
    end
    if summary.block_rthroughput then
      parts[#parts + 1] = ("rtp %.1f"):format(summary.block_rthroughput)
    end
    if st.cycle_cpu then
      parts[#parts + 1] = st.cycle_cpu
    end
  elseif st.cycles and st.cycle_error then
    parts[#parts + 1] = st.cycle_error
  end

  -- winbar is a statusline expression, so literal percent signs must escape.
  vim.wo[st.asm_win].winbar = (" " .. table.concat(parts, " · ")):gsub("%%", "%%%%")
end

---Annotates instructions with latency and reciprocal throughput.
---
---Asynchronous, so a token guards against a stale analysis painting over a
---view that has since retargeted.
local function apply_cycles(st)
  if vim.api.nvim_buf_is_valid(st.asm_buf) then
    vim.api.nvim_buf_clear_namespace(st.asm_buf, ns_cycles, 0, -1)
  end

  st.cycle_summary, st.cycle_error = nil, nil
  if not st.cycles then
    return set_winbar(st)
  end

  local token = (st.cycle_token or 0) + 1
  st.cycle_token = token

  local ordered = {}
  for line = 1, vim.api.nvim_buf_line_count(st.asm_buf) do
    local idx = st.line_to_row[line]
    if idx then
      ordered[#ordered + 1] = idx
    end
  end

  local key = st.scope.kind == "symbol" and st.scope.name or st.scope.kind
  mca.analyze(st.render_model, ordered, { key = key, cpu = st.cpu }, function(result, err)
    if M.state ~= st or st.cycle_token ~= token or not st.cycles then
      return
    end
    if not vim.api.nvim_buf_is_valid(st.asm_buf) then
      return
    end

    if err then
      st.cycle_error = err
      return set_winbar(st)
    end

    st.cycle_summary = result.summary
    st.cycle_cpu = result.cpu

    for line, idx in pairs(st.line_to_row) do
      local entry = result.per_row[idx]
      if entry and line <= vim.api.nvim_buf_line_count(st.asm_buf) then
        local hl = entry.latency >= M.hot_latency and "NeomaxAsmCyclesHot" or "NeomaxAsmCycles"
        local text = ("  %dc · %.2f"):format(entry.latency, entry.rthroughput)
        if entry.uops > 1 then
          text = text .. (" · %du"):format(entry.uops)
        end
        vim.api.nvim_buf_set_extmark(st.asm_buf, ns_cycles, line - 1, 0, {
          virt_text = { { text, hl } },
          virt_text_pos = "eol",
          priority = 90,
        })
      end
    end

    set_winbar(st)
  end)
end

local function apply_decorations(st)
  for _, buf in ipairs({ st.asm_buf, st.src_buf }) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, ns_decor, 0, -1)
    end
  end
  apply_bands(st)
  apply_density(st)
  apply_cycles(st)
end

--- Correlation -------------------------------------------------------------

---Source cursor moved: light up every instruction that line produced.
local function sync_from_source(line)
  local st = M.state
  clear_marks()

  local file = st.file
  if not file then
    return
  end

  local per_file = st.render_model.by_src[file]
  local idxs = per_file and per_file[line]
  if not idxs or #idxs == 0 then
    return
  end

  local first
  for _, idx in ipairs(idxs) do
    local asm_line = st.row_to_line[idx]
    if asm_line then
      mark(st.asm_buf, asm_line, "NeomaxAsmCorrelated")
      first = first or asm_line
    end
  end

  if first then
    ensure_visible(st.asm_win, first)
  end
end

---Assembly cursor moved: highlight the source line, and the sibling
---instructions that came from it, so the whole block is visible at once.
local function sync_from_asm(line)
  local st = M.state
  clear_marks()

  local idx = st.line_to_row[line]
  local row = idx and st.render_model.rows[idx]
  if not row or not row.file or not row.line then
    return
  end

  local per_file = st.render_model.by_src[row.file]
  for _, sibling in ipairs((per_file and per_file[row.line]) or {}) do
    local asm_line = st.row_to_line[sibling]
    if asm_line and asm_line ~= line then
      mark(st.asm_buf, asm_line, "NeomaxAsmSibling")
    end
  end

  -- Only drive the source pane when it is showing the file this row came
  -- from; inlined code legitimately points into a different file.
  if st.file and row.file == st.file and vim.api.nvim_win_is_valid(st.src_win) then
    mark(st.src_buf, row.line, "NeomaxAsmCorrelated")
    ensure_visible(st.src_win, row.line)
  end
end

--- Scope -------------------------------------------------------------------

---Renders `scope` from `model` into the assembly buffer.
---@return string|nil err
local function render_scope(model, scope)
  local st = M.state
  local rows, err = model_mod.slice(model, scope)
  if not rows then
    return err
  end

  local lines, line_to_row, row_to_line = render.render(model, rows, { relative_to = st.root })

  vim.bo[st.asm_buf].modifiable = true
  vim.api.nvim_buf_set_lines(st.asm_buf, 0, -1, false, lines)
  vim.bo[st.asm_buf].modifiable = false

  st.render_model = model
  st.line_to_row = line_to_row
  st.row_to_line = row_to_line
  st.scope = scope
  st.file = M.resolve_file(model, vim.api.nvim_buf_get_name(st.src_buf))

  local title = scope.kind == "symbol" and scope.name or "all"
  pcall(vim.api.nvim_buf_set_name, st.asm_buf, "asm://" .. vim.fs.basename(st.artifact) .. " " .. title)

  apply_decorations(st)
  return nil
end

---Fetches the whole-binary model, which is what makes "which symbol is this
---line in?" answerable from the line table instead of guessed from names.
---Cached by artifact mtime, so this is paid once per build.
local function ensure_index(cb)
  local st = M.state
  if st.index_model then
    return cb(st.index_model)
  end

  -- Cached models come back synchronously, so only announce indexing when it
  -- is actually going to take a moment.
  local settled = false
  vim.defer_fn(function()
    if not settled then
      vim.notify("asm: indexing " .. vim.fs.basename(st.artifact) .. "...", vim.log.levels.INFO)
    end
  end, 150)

  disasm.disassemble(st.artifact, {}, function(m, err)
    settled = true
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    if M.state == st then
      st.index_model = m
      cb(m)
    end
  end)
end

---Shows `symbol`, disassembling just it when no whole-binary model is loaded.
---@param symbol string
---@param on_done? fun()
local function retarget(symbol, on_done)
  local st = M.state

  if st.index_model then
    local err = render_scope(st.index_model, { kind = "symbol", name = symbol })
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    return on_done and on_done()
  end

  disasm.disassemble(st.artifact, { symbol = symbol }, function(m, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    if M.state ~= st then
      return
    end
    local rerr = render_scope(m, { kind = "symbol", name = symbol })
    if rerr then
      return vim.notify("asm: " .. rerr, vim.log.levels.ERROR)
    end
    if on_done then
      on_done()
    end
  end)
end

---Re-targets the view at the symbol containing the cursor.
---
---Resolves through the line table rather than a full disassembly: the answer
---is the same, and it does not require indexing the whole binary first.
---@param opts? { silent?: boolean }
function M.pin(opts)
  opts = opts or {}
  if not M.is_open() then
    return
  end

  local st = M.state
  local line = vim.api.nvim_win_get_cursor(st.src_win)[1]
  local src_name = vim.api.nvim_buf_get_name(st.src_buf)

  lines_mod.resolve(st.artifact, src_name, line, function(best, err)
    if M.state ~= st then
      return
    end
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    if not best then
      if not opts.silent then
        vim.notify("asm: no code near line " .. line .. " in " .. vim.fs.basename(st.artifact), vim.log.levels.WARN)
      end
      return
    end
    if st.scope.kind == "symbol" and st.scope.name == best then
      return
    end

    retarget(best, function()
      sync_from_source(line)
    end)
  end)
end

---The instruction row under the cursor in the assembly pane.
---@return table|nil
local function insn_under_cursor()
  local st = M.state
  local idx = st.line_to_row[vim.api.nvim_win_get_cursor(st.asm_win)[1]]
  local row = idx and st.render_model.rows[idx]
  if row and row.kind == "insn" then
    return row
  end
end

---Opens the manual page for the instruction under the cursor.
---
---The row already holds the mnemonic and operands as separate fields, so this
---never has to guess from the word under the cursor -- which would fail on
---`%eax`, `$0x1`, or any of the suffixed mnemonics objdump emits.
function M.goto_docs()
  if not M.is_open() then
    return
  end

  local insn = insn_under_cursor()
  if not insn then
    return vim.notify("asm: no instruction on this line", vim.log.levels.WARN)
  end

  local target, reason = docs.resolve(M.state.render_model.arch, insn)
  if not target then
    return vim.notify("asm: " .. (reason or "no documentation"), vim.log.levels.WARN)
  end

  local ok, err = pcall(docs.open, target)
  if not ok then
    vim.notify("asm: could not open " .. target.page .. ": " .. tostring(err), vim.log.levels.ERROR)
  end
end

---Jumps to the branch target of the instruction under the cursor.
function M.goto_target()
  if not M.is_open() then
    return
  end
  local st = M.state

  local idx = st.line_to_row[vim.api.nvim_win_get_cursor(st.asm_win)[1]]
  local row = idx and st.render_model.rows[idx]
  if not row or not row.ref then
    return vim.notify("asm: no branch target on this line", vim.log.levels.WARN)
  end

  -- Local labels are indexed by name; anything else is a symbol reference,
  -- possibly with an offset, which is out of scope for the current render.
  local target = st.render_model.labels[row.ref]
  local target_line = target and st.row_to_line[target]
  if not target_line then
    return vim.notify("asm: target not in view: " .. row.ref, vim.log.levels.WARN)
  end

  vim.api.nvim_win_set_cursor(st.asm_win, { target_line, 0 })
  vim.api.nvim_win_call(st.asm_win, function()
    vim.cmd("normal! zz")
  end)
end

---Switches the view between symbol, file and whole-binary scope.
function M.select_scope()
  if not M.is_open() then
    return
  end
  local st = M.state

  vim.ui.select({ "symbol under cursor", "this file", "whole binary" }, { prompt = "Assembly scope:" }, function(choice)
    if not choice or not M.is_open() then
      return
    end

    if choice == "symbol under cursor" then
      return M.pin()
    end

    -- File and binary scopes need every instruction, so these are the only
    -- paths that pay for a full disassembly.
    ensure_index(function(index)
      st.follow = false -- only meaningful when one symbol is shown
      local scope
      if choice == "this file" then
        local file = M.resolve_file(index, vim.api.nvim_buf_get_name(st.src_buf))
        if not file then
          return vim.notify(
            "asm: this file contributed no code to " .. vim.fs.basename(st.artifact),
            vim.log.levels.WARN
          )
        end
        scope = { kind = "file", file = file }
      else
        scope = { kind = "all" }
      end

      local err = render_scope(index, scope)
      if err then
        return vim.notify("asm: " .. err, vim.log.levels.ERROR)
      end
      sync_from_source(vim.api.nvim_win_get_cursor(st.src_win)[1])
    end)
  end)
end

---Opens the source location an assembly line came from, following it into
---another file when the code was inlined from one.
function M.goto_source()
  if not M.is_open() then
    return
  end
  local st = M.state

  local idx = st.line_to_row[vim.api.nvim_win_get_cursor(st.asm_win)[1]]
  local row = idx and st.render_model.rows[idx]
  if not row or not row.file or not row.line then
    return vim.notify("asm: this line has no source position", vim.log.levels.WARN)
  end

  if vim.fn.filereadable(row.file) == 0 then
    return vim.notify("asm: source not available: " .. row.file, vim.log.levels.WARN)
  end

  vim.api.nvim_set_current_win(st.src_win)
  if vim.api.nvim_buf_get_name(st.src_buf) ~= row.file then
    vim.cmd("edit " .. vim.fn.fnameescape(row.file))
    -- The view now belongs to a different source file.
    st.src_buf = vim.api.nvim_get_current_buf()
    st.file = M.resolve_file(st.render_model, row.file)
    attach(st)
  end
  vim.api.nvim_win_set_cursor(st.src_win, { row.line, 0 })
  vim.cmd("normal! zz")
end

---Toggles per-source-line colour banding across both panes.
function M.toggle_banding()
  if not M.is_open() then
    return
  end
  M.state.banding = not M.state.banding
  apply_decorations(M.state)
  vim.notify("asm: banding " .. (M.state.banding and "on" or "off"))
end

---Toggles latency / throughput annotations and the block summary.
function M.toggle_cycles()
  if not M.is_open() then
    return
  end
  M.state.cycles = not M.state.cycles
  apply_cycles(M.state)
  vim.notify("asm: cycle costs " .. (M.state.cycles and "on" or "off"))
end

---Opens llvm-mca's full timeline and bottleneck analysis in a scratch buffer.
---
---This is where the out-of-order behaviour actually becomes visible: which
---instructions issue together, what stalls, and which resource is the limit.
function M.timeline()
  if not M.is_open() then
    return
  end
  local st = M.state

  local ordered = {}
  for line = 1, vim.api.nvim_buf_line_count(st.asm_buf) do
    local idx = st.line_to_row[line]
    if idx then
      ordered[#ordered + 1] = idx
    end
  end

  mca.report(st.render_model, ordered, {
    cpu = st.cpu,
    extra = {
      "--timeline",
      "--bottleneck-analysis",
      "--iterations=" .. M.timeline_iterations,
      "--timeline-max-cycles=" .. M.timeline_cycles,
    },
  }, function(text, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    pcall(vim.api.nvim_buf_set_name, buf, "asm-timeline://" .. (st.scope.name or st.scope.kind))

    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
    vim.wo.wrap = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close timeline" })

    -- Say which knob to reach for, in whichever direction the output went.
    local truncated, widest = false, 0
    for _, line in ipairs(text) do
      truncated = truncated or line:find("Truncated display", 1, true) ~= nil
      widest = math.max(widest, #line)
    end
    if truncated then
      vim.notify(
        ("asm: timeline truncated at %d cycles -- raise view.timeline_cycles (0 = unlimited)"):format(M.timeline_cycles),
        vim.log.levels.WARN
      )
    elseif widest > 1000 then
      vim.notify(
        ("asm: timeline is %d columns wide -- set view.timeline_cycles to cap it"):format(widest),
        vim.log.levels.INFO
      )
    end
  end)
end

---Toggles the per-line instruction-count hints in the source pane.
function M.toggle_density()
  if not M.is_open() then
    return
  end
  M.state.density = not M.state.density
  apply_decorations(M.state)
  vim.notify("asm: density hints " .. (M.state.density and "on" or "off"))
end

function M.toggle_follow()
  if not M.is_open() then
    return
  end
  local st = M.state
  st.follow = not st.follow
  vim.notify("asm: follow " .. (st.follow and "on" or "off"))
  if st.follow then
    M.pin({ silent = true })
  end
end

--- Lifecycle ---------------------------------------------------------------

function M.close()
  local st = M.state
  if not st then
    return
  end

  M.state = nil
  pcall(vim.api.nvim_del_augroup_by_id, st.augroup)
  if st.follow_timer then
    st.follow_timer:stop()
  end
  if vim.api.nvim_buf_is_valid(st.src_buf) then
    vim.api.nvim_buf_clear_namespace(st.src_buf, ns, 0, -1)
    vim.api.nvim_buf_clear_namespace(st.src_buf, ns_decor, 0, -1)
  end
  st.cycle_token = (st.cycle_token or 0) + 1 -- orphan any analysis in flight
  if vim.api.nvim_win_is_valid(st.asm_win) then
    vim.api.nvim_win_close(st.asm_win, true)
  end
end

function attach(st)
  local au = vim.api.nvim_create_augroup("NeomaxAsmView:" .. st.asm_buf, { clear = true })
  st.augroup = au

  -- The window check is the loop guard: moving the cursor in the other pane
  -- fires its CursorMoved too, but that pane is not the focused one.
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = au,
    buffer = st.src_buf,
    callback = function()
      if not M.is_open() or vim.api.nvim_get_current_win() ~= st.src_win then
        return
      end
      local line = vim.api.nvim_win_get_cursor(st.src_win)[1]
      sync_from_source(line)

      if st.follow then
        st.follow_timer:stop()
        st.follow_timer:start(
          120,
          0,
          vim.schedule_wrap(function()
            if M.is_open() and st.follow then
              M.pin({ silent = true })
            end
          end)
        )
      end
    end,
  })

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = au,
    buffer = st.asm_buf,
    callback = function()
      if not M.is_open() or vim.api.nvim_get_current_win() ~= st.asm_win then
        return
      end
      sync_from_asm(vim.api.nvim_win_get_cursor(st.asm_win)[1])
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    group = au,
    buffer = st.asm_buf,
    callback = function()
      vim.schedule(M.close)
    end,
  })

  local map = function(lhs, rhs, desc)
    for _, buf in ipairs({ st.src_buf, st.asm_buf }) do
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end
  end
  map("<leader>yp", M.pin, "Asm: pin to symbol under cursor")
  map("<leader>yf", M.toggle_follow, "Asm: toggle follow mode")
  map("<leader>ys", M.select_scope, "Asm: select scope (symbol/file/binary)")
  map("<leader>yc", M.toggle_banding, "Asm: toggle colour banding")
  map("<leader>yd", M.toggle_density, "Asm: toggle density hints")
  map("<leader>ym", M.toggle_cycles, "Asm: toggle cycle costs")
  map("<leader>yt", M.timeline, "Asm: llvm-mca timeline")

  vim.keymap.set("n", "q", M.close, { buffer = st.asm_buf, desc = "Asm: close view" })
  vim.keymap.set("n", "<CR>", M.goto_source, { buffer = st.asm_buf, desc = "Asm: jump to source" })
  vim.keymap.set("n", "gd", M.goto_target, { buffer = st.asm_buf, desc = "Asm: follow branch target" })
  -- Shadows the global `gm` only inside the assembly pane.
  vim.keymap.set("n", "gm", M.goto_docs, { buffer = st.asm_buf, desc = "Asm: manual page for this instruction" })
end

---Opens the split view.
---@param opts { artifact: string, model: table, symbol?: string, root?: string, follow?: boolean, banding?: boolean, density?: boolean, cycles?: boolean, cpu?: string }
---@return boolean ok
function M.open(opts)
  M.close()

  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_win_get_buf(src_win)

  local asm_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[asm_buf].buftype = "nofile"
  vim.bo[asm_buf].swapfile = false
  render.attach_highlight(asm_buf)

  vim.cmd("vsplit")
  local asm_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(asm_win, asm_buf)
  vim.wo[asm_win].wrap = false
  vim.wo[asm_win].number = false
  vim.wo[asm_win].relativenumber = false
  vim.api.nvim_set_current_win(src_win)

  local scope = opts.symbol and { kind = "symbol", name = opts.symbol } or { kind = "all" }

  -- Follow defaults on, because tracking the cursor across functions is the
  -- normal way to read this. Not when the whole binary was asked for though:
  -- collapsing that to a single function on the first cursor move would
  -- undo what was explicitly requested.
  local follow = opt(opts.follow, M.follow_by_default and scope.kind == "symbol")

  M.state = {
    artifact = opts.artifact,
    root = opts.root or vim.fn.getcwd(),
    src_buf = src_buf,
    src_win = src_win,
    asm_buf = asm_buf,
    asm_win = asm_win,
    follow = follow,
    banding = opt(opts.banding, M.banding_by_default),
    density = opt(opts.density, M.density_by_default),
    cycles = opt(opts.cycles, M.cycles_by_default),
    cpu = opts.cpu,
    follow_timer = vim.uv.new_timer(),
    -- Whether the model spans the whole binary is a property of the MODEL,
    -- not of the scope being rendered: opening aimed at one function is
    -- routinely done with a full model, and that model is the index.
    index_model = opts.model.symbol == nil and opts.model or nil,
  }

  local err = render_scope(opts.model, scope)
  if err then
    M.close()
    vim.notify("asm: " .. err, vim.log.levels.ERROR)
    return false
  end

  if not opts.model.has_debug_info then
    vim.notify(
      "asm: no line table in " .. vim.fs.basename(opts.artifact) .. " -- build with -g for source correlation",
      vim.log.levels.WARN
    )
  end

  attach(M.state)
  sync_from_source(vim.api.nvim_win_get_cursor(src_win)[1])
  return true
end

return M
