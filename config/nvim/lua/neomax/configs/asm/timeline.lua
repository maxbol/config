-- A readable timeline pane, built from llvm-mca's table.
--
-- Three things the raw table does not do:
--
--   * the instruction stays pinned to the left, in a 'statuscolumn' gutter, so
--     scrolling sideways through hundreds of cycles never loses track of which
--     instruction a row belongs to;
--   * the states are coloured, because `-` (waiting to retire, harmless)
--     dominates the picture while `=` (stalled, the actual cost) is what you
--     are looking for;
--   * it follows the cursor in the source and assembly panes, both vertically
--     and horizontally.

local mca = require("neomax.configs.asm.mca")

local M = {}

local ns_focus = vim.api.nvim_create_namespace("neomax_asm_tl_focus")
local ns_band = vim.api.nvim_create_namespace("neomax_asm_tl_band")

-- `=` is the signal and `-` is the noise, so they are coloured accordingly.
vim.api.nvim_set_hl(0, "NeomaxAsmTlDispatch", { default = true, link = "Special" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlStall", { default = true, link = "DiagnosticWarn" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlExec", { default = true, link = "String" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlRetire", { default = true, link = "Special" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlWait", { default = true, link = "NonText" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlTick", { default = true, link = "NonText" })
vim.api.nvim_set_hl(0, "NeomaxAsmTlFocus", { default = true, link = "Visual" })

---Columns reserved for the pinned instruction text.
M.gutter_width = 32

---Keep the focused instruction's dispatch this far from the left edge.
M.lead_columns = 5

---@type table|nil
M.state = nil

function M.is_open()
  local st = M.state
  return st ~= nil and vim.api.nvim_win_is_valid(st.win) and vim.api.nvim_buf_is_valid(st.buf)
end

--- Gutter --------------------------------------------------------------------

---Called per line by 'statuscolumn'. Percent signs must be escaped: the
---gutter is a statusline expression, and `%xmm5` would otherwise render as
---`mm5`.
function _G.NeomaxAsmTimelineGutter()
  local st = M.state
  if not st then
    return ""
  end

  local entry = st.lines[vim.v.lnum]
  if not entry then
    return ""
  end

  local text = entry.text:gsub("\t", " "):gsub("%s+", " ")
  local room = M.gutter_width - 10
  if #text > room then
    -- Character-wise, and with an ASCII marker: a byte-wise cut can split a
    -- multi-byte character and render as replacement garbage.
    text = vim.fn.strcharpart(text, 0, room - 1) .. "~"
  end

  -- Operands are full of percent signs and this is a statusline expression,
  -- so each one has to survive as a literal: %rbp would otherwise render as
  -- "bp". The replacement needs four percents to emit two.
  text = text:gsub("%%", "%%%%")

  return ("%%#Comment#%8x %%#Normal#%-" .. room .. "s"):format(entry.addr or 0, text)
end

--- Rendering -----------------------------------------------------------------

local function apply_syntax(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[
      syntax clear
      syntax match NeomaxAsmTlWait /-/
      syntax match NeomaxAsmTlTick /\./
      syntax match NeomaxAsmTlStall /=/
      syntax match NeomaxAsmTlExec /[eE]/
      syntax match NeomaxAsmTlDispatch /D/
      syntax match NeomaxAsmTlRetire /R/
    ]])
  end)
end

---A cycle ruler aligned with the visible portion of the pane. Lives in the
---winbar and is recomputed on scroll, since the content moves under it.
local function update_ruler(st)
  if not M.is_open() then
    return
  end

  local info = vim.fn.getwininfo(st.win)[1]
  if not info then
    return
  end

  local textoff = info.textoff or 0
  local width = math.max(0, info.width - textoff)
  local leftcol = vim.api.nvim_win_call(st.win, function()
    return vim.fn.winsaveview().leftcol
  end)

  -- One column of slack: a winbar as wide as the window gets truncated, and
  -- vim marks that with a leading "<" which eats the first cycle label.
  local ruler_width = math.max(0, width - 1)

  local cells = {}
  for i = 1, ruler_width do
    cells[i] = " "
  end
  for i = 1, ruler_width do
    local cycle = st.first_cycle + leftcol + i - 1
    if cycle % 10 == 0 then
      local label = tostring(cycle)
      for j = 1, #label do
        if i + j - 1 <= ruler_width then
          cells[i + j - 1] = label:sub(j, j)
        end
      end
    end
  end

  -- The scope is already named in the assembly pane; this only has to say
  -- which iteration and which CPU model the numbers came from.
  local label = (("iter %d · %s"):format(st.iteration, st.cpu) .. string.rep(" ", textoff)):sub(1, textoff)
  vim.wo[st.win].winbar = (label .. table.concat(cells)):gsub("%%", "%%%%")
end

---The gutter width is only known once the window has been drawn, so the
---ruler is refreshed after the redraw rather than during it -- otherwise the
---first render aligns the cycle numbers against a gutter of width zero.
local function queue_ruler(st)
  vim.schedule(function()
    if M.is_open() and M.state == st then
      update_ruler(st)
    end
  end)
end

---Renders `rows` (a subset of the model's rows) into the pane.
---@param st table
---@param timeline table parsed llvm-mca timeline
---@param rows integer[]|nil restrict to these rows, or nil for everything
local function render(st, timeline, rows)
  local wanted
  if rows then
    wanted = {}
    for _, row in ipairs(rows) do
      wanted[row] = true
    end
  end

  -- Crop the cycle range to what the rendered rows actually occupy, which is
  -- what keeps a narrow selection narrow instead of spanning the function.
  local first, last = math.huge, 0
  local selected = {}
  for _, row in ipairs(timeline.ordered) do
    if not wanted or wanted[row] then
      local entry = timeline.by_row[row]
      if entry.first then
        selected[#selected + 1] = entry
        first = math.min(first, entry.first)
        last = math.max(last, entry.last)
      end
    end
  end

  if #selected == 0 then
    return false, "no timeline rows in that range"
  end

  local text, lines = {}, {}
  for i, entry in ipairs(selected) do
    text[i] = entry.states:sub(first, last)
    local row = st.model.rows[entry.row]
    lines[i] = {
      row = entry.row,
      addr = row.addr,
      text = row.text or "",
      dispatch = entry.dispatch and (entry.dispatch - first + 1) or 1,
    }
  end

  vim.bo[st.buf].modifiable = true
  vim.api.nvim_buf_set_lines(st.buf, 0, -1, false, text)
  vim.bo[st.buf].modifiable = false

  st.lines = lines
  st.row_to_line = {}
  for line, entry in ipairs(lines) do
    st.row_to_line[entry.row] = line
  end
  -- llvm-mca's columns are 1-based within the states field; cycle 0 is the
  -- first column of the untrimmed row.
  st.first_cycle = first - 1
  st.iteration = timeline.iteration
  st.cpu = timeline.cpu

  queue_ruler(st)
  return true
end

--- Focus ---------------------------------------------------------------------

---Centres and highlights the row, and scrolls sideways so its dispatch sits
---just inside the left edge.
---@param row integer index into model.rows
function M.focus_row(row)
  if not M.is_open() then
    return
  end
  local st = M.state

  local line = st.row_to_line[row]
  if not line then
    return
  end

  vim.api.nvim_buf_clear_namespace(st.buf, ns_focus, 0, -1)
  vim.api.nvim_buf_set_extmark(st.buf, ns_focus, line - 1, 0, {
    line_hl_group = "NeomaxAsmTlFocus",
    priority = 200,
  })

  local dispatch = st.lines[line].dispatch
  vim.api.nvim_win_call(st.win, function()
    vim.api.nvim_win_set_cursor(st.win, { line, math.max(0, dispatch - 1) })
    vim.cmd("normal! zz")
    local view = vim.fn.winsaveview()
    view.leftcol = math.max(0, dispatch - 1 - M.lead_columns)
    vim.fn.winrestview(view)
  end)

  queue_ruler(st)
end

---Paints the same colour bands the source and assembly panes use.
---@param band_of table<integer, string> source line -> highlight group
---@param line_of table<integer, integer> model row -> source line
function M.apply_bands(band_of, line_of)
  if not M.is_open() then
    return
  end
  local st = M.state

  vim.api.nvim_buf_clear_namespace(st.buf, ns_band, 0, -1)
  if not band_of then
    return
  end

  for line, entry in ipairs(st.lines) do
    local src = line_of and line_of[entry.row]
    local group = src and band_of[src]
    if group then
      vim.api.nvim_buf_set_extmark(st.buf, ns_band, line - 1, 0, {
        line_hl_group = group,
        priority = 100,
      })
    end
  end
end

--- Lifecycle -----------------------------------------------------------------

function M.close()
  local st = M.state
  M.state = nil
  if not st then
    return
  end
  pcall(vim.api.nvim_del_augroup_by_id, st.augroup)
  if vim.api.nvim_win_is_valid(st.win) then
    vim.api.nvim_win_close(st.win, true)
  end
end

---Opens (or re-renders) the timeline pane.
---@param opts { model: table, rows: integer[], scope: string, bounds?: integer[], cpu?: string, iterations?: integer }
---@param cb? fun(ok: boolean, err: string|nil)
function M.open(opts, cb)
  cb = cb or function() end

  mca.timeline(opts.model, opts.rows, {
    key = opts.scope,
    cpu = opts.cpu,
    iterations = opts.iterations,
  }, function(timeline, err)
    if err then
      return cb(false, err)
    end

    local reuse = M.is_open()
    local st = reuse and M.state or {
      buf = vim.api.nvim_create_buf(false, true),
    }

    st.model = opts.model
    st.scope = opts.scope

    if not reuse then
      vim.bo[st.buf].buftype = "nofile"
      vim.bo[st.buf].bufhidden = "wipe"
      vim.bo[st.buf].swapfile = false
      apply_syntax(st.buf)

      local origin = vim.api.nvim_get_current_win()
      -- Full width across the bottom: the timeline needs every column it can
      -- get, and splitting one pane would waste half of them.
      vim.cmd("botright split")
      st.win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(st.win, st.buf)
      vim.wo[st.win].wrap = false
      vim.wo[st.win].number = false
      vim.wo[st.win].relativenumber = false
      vim.wo[st.win].sidescrolloff = 0 -- would fight the lead-column rule
      vim.wo[st.win].statuscolumn = "%!v:lua.NeomaxAsmTimelineGutter()"
      vim.api.nvim_set_current_win(origin)

      vim.keymap.set("n", "q", M.close, { buffer = st.buf, desc = "Close timeline" })

      st.augroup = vim.api.nvim_create_augroup("NeomaxAsmTimeline:" .. st.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "WinScrolled", "WinResized" }, {
        group = st.augroup,
        callback = function()
          if M.is_open() then
            update_ruler(M.state)
          end
        end,
      })
      vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
        group = st.augroup,
        buffer = st.buf,
        callback = function()
          vim.schedule(M.close)
        end,
      })
    end

    M.state = st

    local ok, render_err = render(st, timeline, opts.bounds)
    if not ok then
      M.close()
      return cb(false, render_err)
    end

    cb(true, nil)
  end)
end

return M
