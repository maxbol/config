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

M.find_project_cwd = function(projectMarkers, rootCwd, bufPath)
  local function traverse(dir)
    -- Can't search outside of editor CWD
    if string.sub(dir, 1, #rootCwd) ~= rootCwd then
      return nil
    end

    local handle = vim.loop.fs_scandir(dir)
    if not handle then
      return nil
    end

    while true do
      local name = vim.loop.fs_scandir_next(handle)
      if name == nil then
        break
      end

      for _, root in ipairs(projectMarkers) do
        if root == name then
          return dir
        end
      end
    end

    local parent_dir = vim.loop.fs_realpath(dir .. "/../")
    if parent_dir then
      return traverse(parent_dir)
    end

    return nil
  end

  return traverse(vim.fs.dirname(bufPath))
end

return M
