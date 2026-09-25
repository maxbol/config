-- The split view: correlation, scope, follow. Needs fixtures/build.sh.

local H = require("helpers")
local asm = require("neomax.configs.asm")
local view = require("neomax.configs.asm.view")
local disasm = require("neomax.configs.asm.disasm")
local lines = require("neomax.configs.asm.lines")

local C = H.binary("demo")
if not C then
  return H.skip("view", "fixtures/build.sh has not been run")
end

local SRC = H.fixtures .. "/src/c/demo.c"
local ns = vim.api.nvim_create_namespace("neomax_asm")

local function marks(buf)
  local out = {}
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
    out[#out + 1] = { line = m[2] + 1, hl = m[4].line_hl_group }
  end
  table.sort(out, function(a, b)
    return a.line < b.line
  end)
  return out
end
local function move(win, line)
  vim.api.nvim_set_current_win(win)
  vim.api.nvim_win_set_cursor(win, { line, 0 })
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = vim.api.nvim_win_get_buf(win) })
end

vim.cmd("edit " .. SRC)
local src_win = vim.api.nvim_get_current_win()
local m = H.sync(function(cb)
  disasm.disassemble(C, {}, cb)
end)[1]

H.ok(view.open({ artifact = C, model = m, root = H.fixtures .. "/src/c" }), "opens")
local st = view.state
H.eq(#vim.api.nvim_tabpage_list_wins(0), 2, "splits into two windows")
H.ok(vim.api.nvim_get_current_win() == src_win, "leaves focus in the source window")
H.ok(st.file and st.file:match("demo%.c$"), "resolves the buffer against the line table", st.file)
H.ok(not st.follow, "an explicit whole-binary open does not follow")

-- === source -> asm ===
move(src_win, 4)
local am = marks(st.asm_buf)
H.eq(#am, 4, "line 4 highlights all four inlined instructions")
for _, x in ipairs(am) do
  H.eq(x.hl, "NeomaxAsmCorrelated", "uses the correlated highlight")
end
move(src_win, 2)
H.eq(#marks(st.asm_buf), 0, "a line with no instructions clears the highlight")

-- === asm -> source ===
move(src_win, 4)
local target = marks(st.asm_buf)[1].line
move(st.asm_win, target)
local sm = marks(st.src_buf)
H.eq(#sm, 1, "an asm line highlights one source line")
H.eq(sm[1].line, 4, "and maps back to the right line")
H.eq(vim.api.nvim_win_get_cursor(src_win)[1], 4, "the source window follows")
move(st.asm_win, 1)
H.eq(#marks(st.src_buf), 0, "an unmapped asm line clears rather than misleads")

-- === the unfocused pane must not drive ===
vim.api.nvim_set_current_win(src_win)
vim.api.nvim_win_set_cursor(src_win, { 9, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = st.asm_buf })
H.eq(vim.api.nvim_win_get_cursor(src_win)[1], 9, "the unfocused asm pane does not move the source cursor")

-- === scopes ===
H.eq(st.scope.kind, "all", "opens at whole-binary scope")
local all_lines = vim.api.nvim_buf_line_count(st.asm_buf)
H.pick("this file")
view.select_scope()
vim.wait(30000, function()
  return view.state.scope.kind == "file"
end, 20)
H.eq(view.state.scope.kind, "file", "switches to file scope")
local file_lines = vim.api.nvim_buf_line_count(st.asm_buf)
H.ok(file_lines < all_lines, "file scope is smaller than the whole binary")
local fsyms = {}
for _, idx in pairs(st.line_to_row) do
  local r = st.render_model.rows[idx]
  if r.kind == "insn" and r.sym then
    fsyms[r.sym] = true
  end
end
H.ok(vim.tbl_count(fsyms) >= 2, "file scope spans the symbols the file was inlined into")

move(src_win, 8)
H.pick("symbol under cursor")
view.select_scope()
vim.wait(30000, function()
  return view.state.scope.kind == "symbol"
end, 20)
H.eq(view.state.scope.name, "sum_squares", "switches back to the symbol at the cursor")

-- === branch targets ===
local br, ref
for line, idx in pairs(st.line_to_row) do
  local row = st.render_model.rows[idx]
  if row.kind == "insn" and row.ref and st.render_model.labels[row.ref] then
    br, ref = line, row.ref
    break
  end
end
if br then
  vim.api.nvim_set_current_win(st.asm_win)
  vim.api.nvim_win_set_cursor(st.asm_win, { br, 0 })
  view.goto_target()
  local landed = st.render_model.rows[st.line_to_row[vim.api.nvim_win_get_cursor(st.asm_win)[1]]]
  H.eq(landed.kind, "label", "gd lands on a label")
  H.eq(landed.text, ref, "gd lands on the right label")
else
  H.skip("branch targets", "no in-view branch in this build")
end

view.close()
H.ok(not view.is_open(), "closes")
H.eq(#vim.api.nvim_tabpage_list_wins(0), 1, "removes the asm window")
H.eq(#vim.api.nvim_buf_get_extmarks(vim.api.nvim_get_current_buf(), ns, 0, -1, {}), 0, "cleans up source highlights")

-- === opening for the cursor, the way <leader>ya does ===
disasm.invalidate()
lines.invalidate()
vim.cmd("edit " .. SRC)
local win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_cursor(win, { 8, 0 })
local ms = H.ms(function()
  asm.open_for_cursor(C, { root = H.fixtures .. "/src/c" })
  vim.wait(60000, function()
    return view.is_open()
  end, 10)
end)
H.eq(view.state.scope.name, "sum_squares", "aims at the symbol under the cursor")
H.ok(view.state.index_model == nil, "resolves without building a whole-binary index")
H.eq(#view.state.render_model.syms, 1, "opens from a single-symbol disassembly")
H.ok(view.state.follow, "follows by default for a symbol-scoped open")
print(("       (cold open: %.0f ms)"):format(ms))

-- follow walks across functions with no further keypresses
move(win, 15)
vim.wait(10000, function()
  return view.state.scope.name == "main"
end, 10)
H.eq(view.state.scope.name, "main", "follow crosses into another function on its own")
move(win, 8)
vim.wait(10000, function()
  return view.state.scope.name == "sum_squares"
end, 10)
H.eq(view.state.scope.name, "sum_squares", "and back again")
view.toggle_follow()
move(win, 15)
vim.wait(500)
H.eq(view.state.scope.name, "sum_squares", "follow off freezes the scope")

-- === instruction documentation ===
do
  local docs = require("neomax.configs.asm.docs")
  H.eq(view.state.render_model.arch, "x86_64", "model carries the architecture")
  local bound = {}
  for _, km in ipairs(vim.api.nvim_buf_get_keymap(view.state.asm_buf, "n")) do
    bound[km.lhs] = true
  end
  H.ok(bound["gm"], "gm is bound inside the assembly pane")
  H.ok(bound["gd"] and bound["q"], "so are gd and q")
  -- and only there: the global gm keeps working everywhere else
  local src_bound = {}
  for _, km in ipairs(vim.api.nvim_buf_get_keymap(view.state.src_buf, "n")) do
    src_bound[km.lhs] = true
  end
  H.ok(not src_bound["gm"], "the source pane keeps the global gm")

  -- resolve against the committed page list rather than the installed pages
  local pages = {}
  for _, name in ipairs(H.read_fixture("x86-manpages-list.txt")) do
    pages[name] = true
  end
  local real = docs.has_page
  docs.has_page = function(page)
    return pages[page] == true
  end
  docs.clear_cache()

  local resolved, unresolved = 0, 0
  for _, idx in pairs(view.state.line_to_row) do
    local row = view.state.render_model.rows[idx]
    if row.kind == "insn" then
      if docs.resolve(view.state.render_model.arch, row) then
        resolved = resolved + 1
      else
        unresolved = unresolved + 1
      end
    end
  end
  H.ok(resolved > 0, "instructions in the pane resolve to manual pages", resolved)
  H.ok(resolved > unresolved, "most of them resolve", ("%d resolved, %d not"):format(resolved, unresolved))

  docs.has_page = real
  docs.clear_cache()
end

-- === jumping into a file the code was inlined from ===
view.close()
vim.cmd("edit " .. SRC)
vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { 15, 0 })
asm.open_for_cursor(C, { root = H.fixtures .. "/src/c" })
vim.wait(60000, function()
  return view.is_open()
end, 10)

local foreign, foreign_file
for line, idx in pairs(view.state.line_to_row) do
  local row = view.state.render_model.rows[idx]
  if row.kind == "insn" and row.file and row.file:match("%.h$") and vim.fn.filereadable(row.file) == 1 then
    foreign, foreign_file = line, row.file
    break
  end
end
if foreign then
  vim.api.nvim_set_current_win(view.state.asm_win)
  vim.api.nvim_win_set_cursor(view.state.asm_win, { foreign, 0 })
  view.goto_source()
  H.eq(vim.api.nvim_buf_get_name(view.state.src_buf), foreign_file, "jumps into the file the code was inlined from")
  H.ok(view.is_open(), "the view survives the file switch")
  H.eq(view.state.file, foreign_file, "and re-resolves its source file")
else
  H.skip("cross-file jump", "no readable inlined header in this build")
end
view.close()
