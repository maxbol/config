-- Mapping the paths a compiler records onto files that can be opened.
--
-- dune rewrites the build directory to a fake `/workspace_root` prefix for
-- reproducible builds, ocamlopt sometimes records paths relative to the build
-- root, and a build run from elsewhere records a prefix that no longer exists.
-- None of those open, and a plain string suffix match sees through none of
-- them.

local H = require("helpers")
local model = require("neomax.configs.asm.model")

--- matching (pure) -----------------------------------------------------------

H.eq(model.common_suffix("/a/b/c.ml", "/x/y/b/c.ml"), 2, "counts shared trailing components")
H.eq(model.common_suffix("/a/b/c.ml", "/a/b/c.ml"), 3, "identical paths share everything")
H.eq(model.common_suffix("/a/b/c.ml", "/a/b/d.ml"), 0, "different basenames share nothing")
H.eq(model.common_suffix("c.ml", "/deep/tree/c.ml"), 1, "a bare basename still matches")

local dune_keys = {
  "/workspace_root/lib/tco/arithmetic.ml",
  "/workspace_root/bin/main.ml",
  "/workspace_root/printf.ml",
}

local key, score = model.match_file(dune_keys, "/home/max/src/proj/lib/tco/arithmetic.ml")
H.eq(key, "/workspace_root/lib/tco/arithmetic.ml", "matches through a bogus /workspace_root prefix")
H.eq(score, 3, "scoring by shared components")

-- the specific case a string suffix cannot do: neither path contains the other
H.ok(
  not vim.endswith("/home/max/src/proj/lib/tco/arithmetic.ml", "/" .. dune_keys[1]),
  "and a plain suffix match would have failed here"
)

H.eq(select(2, model.match_file(dune_keys, "/elsewhere/unrelated.ml")), 0, "no shared components scores zero")
H.eq(model.match_file({}, "/a/b.ml"), nil, "an empty key set matches nothing")

-- a more specific key beats a less specific one
H.eq(
  model.match_file({ "/x/util.ml", "/x/lib/tco/util.ml" }, "/proj/lib/tco/util.ml"),
  "/x/lib/tco/util.ml",
  "prefers the key sharing more components"
)
-- ties resolve deterministically rather than by table order
H.eq(
  model.match_file({ "/b/util.ml", "/a/util.ml" }, "/proj/util.ml"),
  model.match_file({ "/a/util.ml", "/b/util.ml" }, "/proj/util.ml"),
  "a tie resolves the same way regardless of key order"
)

--- prefix maps (pure) --------------------------------------------------------

local dune = {}
model.learn_path_map(dune, "/workspace_root/lib/tco/arithmetic.ml", "/home/max/src/proj/lib/tco/arithmetic.ml")
H.eq(dune._path_map, { from = "/workspace_root", to = "/home/max/src/proj" }, "learns the prefix swap")
H.eq(
  model.translate_path(dune, "/workspace_root/bin/main.ml"),
  "/home/max/src/proj/bin/main.ml",
  "and applies it to every other file in the build"
)
H.eq(model.translate_path(dune, "/elsewhere/x.ml"), "/elsewhere/x.ml", "paths outside the prefix are untouched")

local relative = {}
model.learn_path_map(relative, "bin/main.ml", "/tmp/proj/bin/main.ml")
H.eq(relative._path_map, { from = "", to = "/tmp/proj" }, "handles recorded paths that are relative")
H.eq(model.translate_path(relative, "bin/other.ml"), "/tmp/proj/bin/other.ml", "rooting them at the project")

local identical = {}
model.learn_path_map(identical, "/a/b/demo.c", "/a/b/demo.c")
H.eq(model.translate_path(identical, "/a/b/other.c"), "/a/b/other.c", "an exact match changes nothing")

H.eq(model.translate_path({}, "/a/b.c"), "/a/b.c", "no map means no translation")
local unrelated = {}
model.learn_path_map(unrelated, "/x/y.ml", "/p/q.ml")
H.eq(unrelated._path_map, nil, "paths with nothing in common teach nothing")

--- end to end, against a real dune build ------------------------------------

local BIN = H.binary("demo-ocaml.exe")
if not BIN then
  return H.skip("dune paths", "fixtures/build.sh has not built the OCaml fixture")
end

local disasm = require("neomax.configs.asm.disasm")
local lines = require("neomax.configs.asm.lines")
local view = require("neomax.configs.asm.view")
local asm = require("neomax.configs.asm")

local PROJ = H.fixtures .. "/src/ocaml"
local SRC = PROJ .. "/lib/tco/arithmetic.ml"

-- the recorded paths really are unopenable
local m = H.sync(function(cb)
  disasm.disassemble(BIN, {}, cb)
end)[1]
H.ok(m ~= nil, "disassembles the OCaml binary")
local bogus
for file in pairs(m.by_src) do
  if file:find("workspace_root", 1, true) then
    bogus = file
  end
end
H.ok(bogus ~= nil, "dune recorded a /workspace_root path", bogus)
H.eq(vim.fn.filereadable(bogus), 0, "which does not exist on disk")

-- resolution still finds the file
H.ok(view.resolve_file(m, SRC) ~= nil, "the buffer resolves against it anyway")

local idx = H.sync(function(cb)
  lines.load(BIN, cb)
end)[1]
local file = lines.resolve_file(idx, SRC)
H.ok(file ~= nil, "and so does the line table", file)
local syms = H.sync(function(cb)
  disasm.symbols(BIN, cb)
end)[1]
H.eq(
  lines.symbol_near(idx, syms, file, 3),
  "camlTco__Arithmetic.fold_vals_275",
  "symbols resolve through OCaml mangling"
)

-- the view: correlation, readable paths, and a working jump
vim.cmd("edit " .. SRC)
local win = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_cursor(win, { 3, 0 })
asm.open_for_cursor(BIN, { root = PROJ })
vim.wait(120000, function()
  return view.is_open()
end, 20)
H.ok(view.is_open(), "the view opens on an OCaml binary")

local st = view.state
local shown = table.concat(vim.api.nvim_buf_get_lines(st.asm_buf, 0, -1, false), "\n")
H.ok(not shown:find("workspace_root", 1, true), "rendered source comments carry no /workspace_root")
H.ok(shown:find("lib/tco/arithmetic%.ml"), "they show the path relative to the project", shown:match("; %S+%.ml:%d+"))

local ns = vim.api.nvim_create_namespace("neomax_asm")
vim.api.nvim_set_current_win(win)
vim.api.nvim_win_set_cursor(win, { 3, 0 })
vim.api.nvim_exec_autocmds("CursorMoved", { buffer = st.src_buf })
H.ok(#vim.api.nvim_buf_get_extmarks(st.asm_buf, ns, 0, -1, {}) > 0, "the source line highlights its instructions")

local target
for line, idx2 in pairs(st.line_to_row) do
  local row = st.render_model.rows[idx2]
  if row.kind == "insn" and row.file then
    target = line
    break
  end
end
vim.api.nvim_set_current_win(st.asm_win)
vim.api.nvim_win_set_cursor(st.asm_win, { target, 0 })
view.goto_source()
H.eq(
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(view.state.src_buf), ":t"),
  "arithmetic.ml",
  "pressing enter opens the real file, not the recorded path"
)
H.eq(vim.fn.filereadable(vim.api.nvim_buf_get_name(view.state.src_buf)), 1, "and it is readable")

view.close()
