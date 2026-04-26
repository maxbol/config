local map = vim.keymap.set

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

local function make_telescope_binding(binding, picker, args, desc)
  args = args or function()
    return {}
  end

  map("n", binding, function()
    picker(args(), { desc = desc })
  end)
  map("x", binding, function()
    picker(mergeTables(args(), { default_text = vim.fn.expand("<cword>") }), { desc = desc })
  end)
end

make_telescope_binding("<leader><leader>", require("telescope.builtin").find_files, function()
  return {
    find_command = { "rg", "--ignore", "--files", "--sortr", "accessed" },
    cwd = vim.fn.getcwd(-1),
  }
end, "Telescope find (based on access time)")

make_telescope_binding("<leader>ff", require("telescope.builtin").find_files, function()
  return {
    cwd = vim.fn.getcwd(-1),
  }
end, "Telescope find files")

make_telescope_binding("<leader>fa", require("telescope.builtin").find_files, function()
  return {
    follow = true,
    no_ignore = true,
    hidden = true,
  }
end, "Telescope Find all files")

make_telescope_binding("<leader>fw", require("telescope.builtin").live_grep, function()
  return {
    cwd = vim.fn.getcwd(-1),
  }
end, "Telescope Live grep")

make_telescope_binding("<leader>fW", require("telescope.builtin").live_grep, function()
  return {
    cwd = vim.fn.getcwd(-1),
    no_ignore = true,
    hidden = true,
  }
end, "Telescope Live grep (all files)")

make_telescope_binding("<leader>fo", require("telescope.builtin").oldfiles, function()
  return {
    cwd = vim.fn.getcwd(-1),
    cwd_only = true,
  }
end, "Telescope Find oldfiles")

make_telescope_binding("<leader>fb", require("telescope.builtin").buffers, nil, "Telescope Find oldfiles")

make_telescope_binding("<leader>fh", require("telescope.builtin").help_tags, nil, "Telescope Help page")

make_telescope_binding(
  "<leader>f/",
  require("telescope.builtin").current_buffer_fuzzy_find,
  nil,
  "Telescope Find in current buffer"
)

make_telescope_binding(
  "<leader>fs",
  require("telescope.builtin").lsp_document_symbols,
  nil,
  "Telescope Find symbol in document"
)

make_telescope_binding("<leader>fS", require("telescope.builtin").lsp_dynamic_workspace_symbols, function()
  return {
    symbols = { "function", "class", "interface", "method", "enum" },
  }
end, "Telescope Find symbol in workspace-")
