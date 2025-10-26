local M = {}

M.get_text_in_selection = function()
  local vstart = vim.fn.getpos(".")
  local vend = vim.fn.getpos("v")
  local region = vim.fn.getregion(vstart, vend)
  local out = ""
  for n, l in ipairs(region) do
    if n ~= 1 then
      out = out .. "\\_."
    end
    l = string.gsub(l, "\\", "\\\\")
    l = string.gsub(l, "~", "\\~")
    out = out .. l
  end
  return out
end

M.get_cword = function()
  return vim.fn.expand("<cword>")
end

M.get_selected_text_or_cword = function()
  local mode = vim.api.nvim_get_mode()
  if mode.mode == "x" or mode.mode == "v" then
    return M.get_text_in_selection()
  end
  return M.get_cword()
end

return M
