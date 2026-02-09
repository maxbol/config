local M = {}

M.getCwd = function(cwd_roots)
  local function traverse(dir)
    print("Traversing " .. dir)
    local handle = vim.loop.fs_scandir(dir)
    if not handle then
      return nil
    end

    while true do
      local name = vim.loop.fs_scandir_next(handle)
      if name == nil then
        break
      end

      for _, root in ipairs(cwd_roots) do
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

  return traverse(vim.fs.dirname(vim.fn.expand("%:p"))) or vim.fn.getcwd()
end

return M
