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

return M
