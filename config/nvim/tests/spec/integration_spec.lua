-- <leader>ya end to end: build via make.lua, then open the view.
-- Builds into fixtures/src, so it needs a C compiler.

local H = require("helpers")

if vim.fn.executable("cc") == 0 and vim.fn.executable("gcc") == 0 then
  return H.skip("integration", "no C compiler")
end

local PROJ = H.fixtures .. "/src/c"
vim.g.makefile_root = vim.fn.tempname() .. "/make"
os.execute("rm -f " .. PROJ .. "/out")

require("neomax.configs.make")
local view = require("neomax.configs.asm.view")

vim.cmd("edit " .. PROJ .. "/demo.c")
vim.cmd("filetype detect") -- `nvim -l` skips detection
local win = vim.api.nvim_get_current_win()
H.eq(vim.bo.filetype, "c", "filetype detected")

local ya = vim.fn.maparg("<leader>ya", "n", false, true)
local yA = vim.fn.maparg("<leader>yA", "n", false, true)
H.ok(ya and ya.callback, "<leader>ya is mapped")
H.ok(yA and yA.callback, "<leader>yA is mapped")
H.eq(ya.desc, "Build + view asm", "with a description")
H.ok(vim.fn.maparg("<leader>yb", "n") ~= "", "the existing build mapping still works")

if not (ya and ya.callback) then
  return
end

vim.api.nvim_win_set_cursor(win, { 8, 0 })
ya.callback()
vim.wait(120000, function()
  return view.is_open() and view.state.scope.kind == "symbol"
end, 50)

H.ok(view.is_open(), "the view opens after the build")
H.ok(vim.fn.filereadable(PROJ .. "/out") == 1, "the build produced the artifact")
H.eq(view.state.scope.name, "sum_squares", "aimed at the symbol under the cursor")
H.ok(view.state.artifact:match("/out$") ~= nil, "the artifact came from the configured glob", view.state.artifact)
H.eq(view.state.root, PROJ, "rooted at the project, not the editor cwd")

local rendered = vim.api.nvim_buf_get_lines(view.state.asm_buf, 0, -1, false)
H.ok(rendered[1]:match("<sum_squares>:") ~= nil, "renders that symbol", rendered[1])
local relative = false
for _, l in ipairs(rendered) do
  if l == "; demo.c:8" then
    relative = true
  end
end
H.ok(relative, "source comments are relative to the project root")

-- the cursor wins on a rebuild
vim.api.nvim_set_current_win(win)
vim.api.nvim_win_set_cursor(win, { 15, 0 })
ya.callback()
vim.wait(120000, function()
  return view.is_open() and view.state.scope.name == "main"
end, 50)
H.eq(view.state.scope.name, "main", "moving the cursor retargets on the next build")

view.close()
os.execute("rm -f " .. PROJ .. "/out")
