-- Turns model rows into buffer lines. Shared by the dump harness and the
-- split view so both render identically.

local M = {}

---@param row table
---@param root string paths are shown relative to this
---@return string
function M.format_row(row, root)
  if row.kind == "section" then
    return ("; ==== section %s ===="):format(row.text)
  elseif row.kind == "sym" then
    return ("%016x <%s>:"):format(row.addr, row.text)
  elseif row.kind == "func" then
    return ("; %s():"):format(row.text)
  elseif row.kind == "src" then
    local path = vim.fs.relpath(root, row.file) or vim.fn.fnamemodify(row.file, ":~")
    return ("; %s:%d"):format(path, row.line)
  elseif row.kind == "label" then
    return ("<%s>:"):format(row.text)
  elseif row.kind == "insn" then
    return ("    %x:  %s"):format(row.addr, row.text)
  end
  return row.text
end

---Renders the given rows, in order.
---@param model table
---@param rows integer[] indices into model.rows
---@param opts? { relative_to?: string }
---@return string[] lines, table line_to_row, table row_to_line
function M.render(model, rows, opts)
  opts = opts or {}
  local root = opts.relative_to or vim.fn.getcwd()

  local lines, line_to_row, row_to_line = {}, {}, {}
  for i, idx in ipairs(rows) do
    lines[i] = M.format_row(model.rows[idx], root)
    line_to_row[i] = idx
    row_to_line[idx] = i
  end

  return lines, line_to_row, row_to_line
end

---Turns on syntax highlighting for an assembly buffer.
---
---Started explicitly rather than left to nvim-treesitter's FileType hook,
---which only covers parsers present at startup. Degrades quietly if the
---`objdump` grammar is absent.
local hinted = false
function M.attach_highlight(buf)
  vim.bo[buf].filetype = "objdump"

  if pcall(vim.treesitter.start, buf, "objdump") then
    return true
  end

  if not hinted then
    hinted = true
    vim.notify("asm: no tree-sitter `objdump` grammar; assembly will be unhighlighted", vim.log.levels.INFO)
  end
  return false
end

--- Band colours ---------------------------------------------------------------

-- Distinct hues, blended into the colourscheme's own background rather than
-- used raw, so the bands read as tints of the current theme instead of
-- fighting it. Works out for both light and dark backgrounds.
local BAND_HUES = { 0xe06c75, 0x98c379, 0x61afef, 0xc678dd, 0xe5c07b, 0x56b6c2 }

M.band_count = #BAND_HUES

local function channels(colour)
  return math.floor(colour / 65536) % 256, math.floor(colour / 256) % 256, colour % 256
end

local function blend(fg, bg, alpha)
  local fr, fgn, fb = channels(fg)
  local br, bgn, bb = channels(bg)
  local function mix(a, b)
    return math.floor(a * alpha + b * (1 - alpha) + 0.5)
  end
  return mix(fr, br) * 65536 + mix(fgn, bgn) * 256 + mix(fb, bb)
end

---(Re)defines the band highlight groups against the current colourscheme.
function M.define_bands()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = normal and normal.bg
  if not bg then
    bg = vim.o.background == "dark" and 0x1e1e1e or 0xfafafa
  end

  for i, hue in ipairs(BAND_HUES) do
    -- Subtle on purpose: this sits under the correlation highlight and has to
    -- stay readable behind ordinary syntax colouring.
    vim.api.nvim_set_hl(0, "NeomaxAsmBand" .. i, { bg = blend(hue, bg, 0.16) })
  end
end

M.define_bands()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NeomaxAsmBands", { clear = true }),
  callback = M.define_bands,
})

return M
