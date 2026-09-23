-- Step 1: disassemble an artifact and show it. No split view, no sync yet --
-- this exists to exercise the backend and the parser against real builds.

local disasm = require("neomax.configs.asm.disasm")
local render = require("neomax.configs.asm.render")
local view = require("neomax.configs.asm.view")
local model_mod = require("neomax.configs.asm.model")
local lines = require("neomax.configs.asm.lines")

local M = {}

M.disasm = disasm
M.view = view
M.current_scope = view.current_scope

---Renders a whole model, one line per row.
---@param m table
---@param opts? { relative_to?: string }
---@return string[]
function M.render(m, opts)
  local all = {}
  for i = 1, #m.rows do
    all[i] = i
  end
  return (render.render(m, all, opts))
end

---Opens a parsed model in a scratch buffer.
---@param m table
function M.show(m)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, M.render(m))

  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  render.attach_highlight(buf)

  local name = m.symbol and (vim.fs.basename(m.artifact) .. " " .. m.symbol) or vim.fs.basename(m.artifact)
  pcall(vim.api.nvim_buf_set_name, buf, "asm://" .. name)

  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, buf)
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close asm view" })

  if not m.has_debug_info then
    vim.notify(
      "No line table in " .. vim.fs.basename(m.artifact) .. " -- build with debug info (-g) to get source correlation",
      vim.log.levels.WARN
    )
  end

  return buf
end

---Disassembles and shows, narrowing to `symbol` when given.
---@param artifact string
---@param symbol? string
function M.dump(artifact, symbol)
  artifact = vim.fn.fnamemodify(artifact, ":p")
  disasm.disassemble(artifact, { symbol = symbol }, function(m, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    M.show(m)
  end)
end

---Picks a symbol from the artifact, then dumps it.
---@param artifact string
function M.pick(artifact)
  artifact = vim.fn.fnamemodify(artifact, ":p")
  disasm.symbols(artifact, function(syms, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end

    local names = vim.tbl_map(function(s)
      return s.name
    end, syms)

    vim.ui.select(names, { prompt = "Disassemble symbol:" }, function(choice)
      if choice then
        M.dump(artifact, choice)
      end
    end)
  end)
end

---Opens the side-by-side view for `artifact`, narrowed to `symbol` when
---given. Without a symbol the whole binary is loaded, which also serves as
---the index for pin and follow.
---@param artifact string
---@param symbol? string
function M.split(artifact, symbol)
  artifact = vim.fn.fnamemodify(artifact, ":p")
  disasm.disassemble(artifact, { symbol = symbol }, function(m, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end
    view.open({ artifact = artifact, model = m, symbol = symbol })
  end)
end

---Opens the view on a freshly built artifact, aimed at whatever the cursor
---is in.
---
---Aims at the symbol under the cursor. `prefer_scope` is the fallback when the
---cursor maps to nothing, so a rebuild at another optimisation level keeps your
---place instead of dumping you at the top of the binary.
---@param artifact string
---@param opts? { root?: string, prefer_scope?: string }
function M.open_for_cursor(artifact, opts)
  opts = opts or {}
  artifact = vim.fn.fnamemodify(artifact, ":p")

  -- The build just replaced it; mtime keying would catch this anyway, but
  -- dropping the old data explicitly avoids depending on clock resolution.
  disasm.invalidate(artifact)
  lines.invalidate(artifact)

  local src_name = vim.api.nvim_buf_get_name(0)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local root = opts.root or vim.fn.getcwd()

  local function show(symbol)
    disasm.disassemble(artifact, { symbol = symbol }, function(m, err)
      if err then
        -- The symbol may not have survived the rebuild; fall back to showing
        -- the binary rather than failing outright.
        if symbol then
          return show(nil)
        end
        return vim.notify("asm: " .. err, vim.log.levels.ERROR)
      end
      view.open({ artifact = artifact, model = m, symbol = symbol, root = root })
    end)
  end

  -- Resolve through the line table, not a full disassembly: it answers the
  -- same question several times faster, which is what keeps this usable
  -- straight after a build.
  lines.resolve(artifact, src_name, line, function(symbol, err)
    if err then
      return vim.notify("asm: " .. err, vim.log.levels.ERROR)
    end

    -- The cursor wins. `prefer_scope` is the fallback for when it says
    -- nothing useful -- you were reading the asm pane, or sitting in a file
    -- that contributed nothing -- and it is what holds your place across a
    -- rebuild at a different optimisation level.
    if not symbol and opts.prefer_scope then
      symbol = opts.prefer_scope
    end

    if not symbol then
      vim.notify(
        "asm: no code from this file in " .. vim.fs.basename(artifact) .. " -- showing the whole binary",
        vim.log.levels.WARN
      )
    end

    show(symbol)
  end)
end

vim.api.nvim_create_user_command("AsmView", function(o)
  local artifact = o.fargs[1]
  if not artifact then
    return vim.notify("AsmView <artifact> [symbol]", vim.log.levels.ERROR)
  end
  M.split(artifact, o.fargs[2] and table.concat(vim.list_slice(o.fargs, 2), " ") or nil)
end, { nargs = "+", complete = "file", desc = "Open the source/asm split view" })

vim.api.nvim_create_user_command("AsmClose", view.close, { desc = "Close the asm view" })

vim.api.nvim_create_user_command("AsmDump", function(o)
  local artifact = o.fargs[1]
  if not artifact then
    return vim.notify("AsmDump <artifact> [symbol]", vim.log.levels.ERROR)
  end
  if o.fargs[2] then
    M.dump(artifact, table.concat(vim.list_slice(o.fargs, 2), " "))
  else
    M.pick(artifact)
  end
end, { nargs = "+", complete = "file", desc = "Disassemble an artifact (step 1 harness)" })

return M
