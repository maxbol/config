local map = vim.keymap.set

local function get_selection()
  -- does not handle rectangular selection
  local s_start = vim.fn.getpos(".")
  local s_end = vim.fn.getpos("v")
  local lines = vim.fn.getregion(s_start, s_end)
  local text = vim.fn.escape(lines[1], [[\/]])
  for i = 2, #lines do
    text = text .. "\\n" .. vim.fn.escape(lines[i], [[\/]])
  end
  return text
end

local function mergeTables(a, b)
  local merged = {}
  for k, v in pairs(a) do
    merged[k] = v
  end
  for k, v in pairs(b) do
    merged[k] = v
  end
  return merged
end

local function make_fff_binding(binding, picker, args, desc)
  args = args or function()
    return {}
  end

  map("n", binding, function()
    picker(args(), { desc = desc })
  end)
  map("x", binding, function()
    picker(mergeTables(args(), { query = get_selection() }), { desc = desc })
  end)
end

make_fff_binding("<leader><leader>", require("fff").find_files, function()
  return {
    base_path = vim.fn.getcwd(-1),
  }
end, "fff.nvim find files")

make_fff_binding("<leader>ff", require("fff").find_files, function()
  return {
    base_path = vim.fn.getcwd(-1),
  }
end, "fff.nvim find files")

make_fff_binding("<leader>fw", require("fff").live_grep, function()
  return {
    cwd = vim.fn.getcwd(-1),
  }
end, "fff.nvim Live grep")
