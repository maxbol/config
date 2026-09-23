-- some cool quickfix list experiments
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set
local g = vim.g

local is_tmux = vim.env.TMUX ~= nil

if g.makefile_root == nil then
  g.makefile_root = vim.fn.stdpath("data") .. "/make"
end

local M = {}

M.max_history = 15

local function looks_like_path(str)
  return str:match("[/\\]") ~= nil
end

function M.insertCmdInList(cmds, cmd)
  local new_cmds = { cmd }
  for i, c in ipairs(cmds) do
    if i >= M.max_history then
      break
    end
    if c ~= cmd then
      table.insert(new_cmds, c)
    end
  end
  return new_cmds
end

-- Every persisted command mode. `file` is the on-disk name under
-- g.makefile_root/<cwd>/, `opt` the key accepted by M.makeLanguage().
M.modes = {
  { name = "make", file = "make", opt = "makecmd" },
  { name = "run", file = "run", opt = "runcmd" },
  { name = "lint", file = "lint", opt = "lintcmd" },
  { name = "asm", file = "asm", opt = "asmcmd" },
  -- Not a command: the binary to disassemble. Same storage shape though --
  -- remembered picks over a set of defaults -- so it rides along here.
  { name = "artifact", file = "artifact", opt = "artifacts", exists = true },
}

-- A mode's default may be a single command or a list of them.
local function tolist(v)
  if v == nil then
    return {}
  end
  return type(v) == "string" and { v } or v
end

-- Picked commands first (most recent first), then configured defaults not yet
-- picked. Defaults therefore stay reachable in the selector forever, and
-- editing a language config takes effect immediately -- only picks are stored.
local function merge(picks, defaults)
  local out, seen = {}, {}
  for _, src in ipairs({ picks, defaults }) do
    for _, cmd in ipairs(src) do
      if cmd ~= "" and not seen[cmd] then
        seen[cmd] = true
        table.insert(out, cmd)
      end
    end
  end
  return out
end

function M.getProjectFiles(cwd)
  local dir = g.makefile_root .. "/" .. cwd

  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end

  local files = {}
  for _, mode in ipairs(M.modes) do
    files[mode.name] = dir .. "/" .. mode.file
  end
  return files
end

-- Returns { [mode] = { picks = {...}, display = {...} } }, keyed by mode name.
-- `picks` is what gets persisted, `display` what the selector offers.
function M.getLastCmds(defaults, cwd)
  local files = M.getProjectFiles(cwd)
  local out = {}

  for _, mode in ipairs(M.modes) do
    local picks = {}
    if vim.fn.filereadable(files[mode.name]) == 1 then
      picks = vim.fn.readfile(files[mode.name])
    end
    if mode.exists then
      picks = vim.tbl_filter(function(path)
        return vim.fn.filereadable(path) == 1
      end, picks)
    end

    out[mode.name] = {
      picks = picks,
      display = merge(picks, tolist(defaults[mode.name])),
    }
  end

  return out
end

---Expands a language's `artifacts` spec into concrete executables under
---`cwd`, most recently built first -- so the thing you just compiled leads
---the list.
---@param spec string|string[]|fun(cwd: string): string[]|nil
---@param cwd string
---@return string[]
function M.expandArtifacts(spec, cwd)
  if spec == nil then
    return {}
  end
  if type(spec) == "function" then
    spec = spec(cwd)
  end

  local globs = type(spec) == "string" and { spec } or (spec or {})
  local found = {}

  for _, glob in ipairs(globs) do
    local pattern = glob:sub(1, 1) == "/" and glob or (cwd .. "/" .. glob)
    for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
      if vim.fn.isdirectory(path) == 0 and vim.fn.executable(path) == 1 then
        found[#found + 1] = path
      end
    end
  end

  table.sort(found, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  return found
end

function M.storeCmds(mode, cmds, cwd)
  vim.fn.writefile(cmds, M.getProjectFiles(cwd)[mode])
end

function M.getCustomCmd(cmds, cb)
  local default = #cmds == 1 and cmds[1] or nil
  vim.ui.select(cmds, {
    prompt = "Enter command:",
    default = default,
    include_prompt_in_entries = true,
  }, function(cmd_with_args)
    if not cmd_with_args then
      return
    end

    cb(cmd_with_args)
  end)
  -- vim.ui.input({
  -- 	prompt = "Arguments:",
  -- 	completion = "shellcmd",
  -- 	default = cmd,
  -- }, function(cmd_with_args) end)
end

function M.make(cwd, statusmsg, makecmd, grepcmd, on_success, on_failure)
  local lines = {}
  local grep_lines = {}
  local editor_cwd = vim.fn.getcwd()
  print(statusmsg .. ": " .. makecmd .. " (cwd: " .. cwd .. ")")

  local function on_output(_, data, _)
    if data then
      for _, value in ipairs(data) do
        if value ~= "" then
          table.insert(lines, value)
        end
      end
    end
  end

  local function on_exit(_, exit_code)
    if #lines > 0 then
      local grep_pipe_cmd = "cat <<EOF " .. grepcmd .. "\n" .. table.concat(lines, "\n") .. "\nEOF"
      local grep_io = assert(io.popen(grep_pipe_cmd, "r"))
      local grep_output = grep_io:read("*a")
      grep_io:close()
      if grep_output ~= nil then
        grep_output = grep_output:gsub("\n$", "")
        if grep_output ~= "" then
          grep_lines = vim.split(grep_output, "\n")
        end
      end

      if cwd ~= editor_cwd then
        for i, v in ipairs(grep_lines) do
          local parts = vim.split(v, ":")
          local p1 = parts[1]
          if
            p1 ~= nil and string.sub(p1, 1, 1) ~= "/" --[[ and looks_like_path(p1) ]]
          then
            local path = vim.fs.joinpath(cwd, p1)
            parts[1] = vim.fs.relpath(editor_cwd, path)
          end
          grep_lines[i] = table.concat(parts, ":")
        end
      end
    end

    vim.fn.setqflist({}, "r", {
      title = makecmd,
      lines = grep_lines,
    })

    if #grep_lines > 0 then
      vim.cmd("copen")
      print("Encountered " .. #grep_lines .. " errors, opening quickfix list")
      if on_failure then
        on_failure()
      end
    elseif exit_code ~= 0 then
      -- No greppable error lines, so we can't create a quickfix list. Instead, let's
      -- open a split with a temporary buffer showing the entire cmd output.
      --
      local out_lines = {
        "Make error: " .. makecmd .. " failed with exit code " .. exit_code,
        "Command output:",
        "",
      }

      if #lines == 0 then
        lines = { "The command exited with a non-zero exit code but provided no output" }
      end

      for _, line in ipairs(lines) do
        table.insert(out_lines, line)
      end

      table.insert(out_lines, "")
      table.insert(out_lines, "(Press <CR> to close this buffer...)")

      vim.cmd("10sp")
      vim.cmd("enew")
      vim.cmd("setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap")
      vim.keymap.set("n", "<CR>", ":q<CR>", { buffer = vim.api.nvim_win_get_buf(0) })
      vim.api.nvim_buf_set_lines(0, 0, -1, false, out_lines)
      vim.cmd("cclose")

      print("Encountered non-line enumerated error, opening error buffer")

      if on_failure then
        on_failure()
      end
    else
      vim.cmd("cclose")
      print("OK!")
      if on_success then
        on_success()
      end
    end
    -- vim.cmd("doautocmd QuickFixCmdPost")
  end

  vim.fn.jobstart(makecmd, {
    cwd = cwd,
    on_stderr = on_output,
    on_stdout = on_output,
    on_exit = on_exit,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

function M.run(cwd, runcmd, on_success, on_failure)
  local ui = vim.api.nvim_list_uis()[1]

  local original_cwd = vim.loop.cwd()

  print("Running project: " .. runcmd .. " (cwd: " .. cwd .. ")")

  local cmd = runcmd

  if is_tmux and ui ~= nil then
    local width = ui.width

    if width > 200 then
      cmd = string.format("tmux split-window -h %s \\; set-option remain-on-exit on", cmd)
    else
      cmd = string.format("tmux new-window %s \\; set-option remain-on-exit on", cmd)
    end
  end

  vim.loop.chdir(cwd)

  local success = os.execute(cmd)

  if success and on_success then
    on_success()
  elseif not success and on_failure then
    on_failure()
  end

  vim.loop.chdir(original_cwd)
end

function M.mapMake(o)
  map("n", o.mappingDefault, function()
    M.make(o.getCwd(), o.label, o.getCmds()[1], o.grepcmd)
  end, { desc = o.descDefault, buffer = o.buffer })
  map("n", o.mappingCustom, function()
    M.getCustomCmd(o.getCmds(), function(cmd)
      M.make(o.getCwd(), o.label, cmd, o.grepcmd, o.recordCmd(cmd))
    end)
  end, { desc = o.descCustom, buffer = o.buffer })
end

function M.mapMakeRun(o)
  map("n", o.mappingDefault, function()
    M.make(o.getCwd(), o.label, o.getMakeCmds()[1], o.grepcmd, function()
      local cmd = o.getCmds()[1]
      print("Running project: " .. cmd)
      M.run(o.getCwd(), cmd)
    end)
  end, { desc = o.descDefault, buffer = o.buffer })
  map("n", o.mappingCustom, function()
    M.getCustomCmd(o.getCmds(), function(cmd)
      M.make(o.getCwd(), o.label, o.getMakeCmds()[1], o.grepcmd, function()
        print("Running project: " .. cmd)
        M.run(o.getCwd(), cmd, o.recordCmd(cmd))
      end)
    end)
  end, { desc = o.descCustom, buffer = o.buffer })
end

---Builds, then opens the assembly view aimed at the symbol under the cursor.
---
---Unlike lint/build/run this does not end at the quickfix list: on success it
---hands the built artifact to the asm module. The previous scope is carried
---across so rebuilding at another optimisation level keeps your place.
function M.openAsm(o, opts)
  opts = opts or {}
  local artifacts = o.getArtifacts()

  if #artifacts == 0 then
    return print("No artifact to disassemble -- set `artifacts` for this filetype in make.lua")
  end

  local function open(path)
    local asm = require("neomax.configs.asm")
    asm.open_for_cursor(path, { root = o.getCwd(), prefer_scope = asm.current_scope() })
  end

  if opts.pick and #artifacts > 1 then
    vim.ui.select(artifacts, { prompt = "Artifact to disassemble:" }, function(choice)
      if choice then
        o.recordArtifact(choice)()
        open(choice)
      end
    end)
  else
    open(artifacts[1])
  end
end

function M.mapMakeAsm(o)
  map("n", o.mappingDefault, function()
    local cmd = o.getCmds()[1]
    if cmd == nil then
      return print("No asm build command configured for this filetype")
    end
    M.make(o.getCwd(), o.label, cmd, o.grepcmd, function()
      M.openAsm(o)
    end)
  end, { desc = o.descDefault, buffer = o.buffer })

  map("n", o.mappingCustom, function()
    M.getCustomCmd(o.getCmds(), function(cmd)
      local persist = o.recordCmd(cmd)
      M.make(o.getCwd(), o.label, cmd, o.grepcmd, function()
        persist()
        M.openAsm(o, { pick = true })
      end)
    end)
  end, { desc = o.descCustom, buffer = o.buffer })
end

function M.makeLanguage(opts)
  local makecmd = opts.makecmd
  local runcmd = opts.runcmd
  local lintcmd = opts.lintcmd

  local grepcmds = opts.grepcmds or {
    make = opts.grepcmd,
    lint = opts.grepcmd,
  }

  local cmds_per_cwd = {}

  local cwd_roots = { ".git", ".jj" }

  for _, v in ipairs(opts.cwd_roots or {}) do
    table.insert(cwd_roots, v)
  end

  local function getCwd()
    local function traverse(dir)
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

  -- Artifacts are globbed per project root, so defaults depend on the cwd.
  local function defaultsFor(cwd)
    local d = {}
    for _, mode in ipairs(M.modes) do
      if mode.name == "artifact" then
        d[mode.name] = M.expandArtifacts(opts.artifacts, cwd)
      else
        d[mode.name] = opts[mode.opt]
      end
    end
    return d
  end

  local function getCmdsByCwd(cwd)
    if cmds_per_cwd[cwd] == nil then
      cmds_per_cwd[cwd] = M.getLastCmds(defaultsFor(cwd), cwd)
    end
    return cmds_per_cwd[cwd]
  end

  -- Commands offered in the selector for `mode`, best default first.
  local function getCmds(mode)
    return function()
      local cwd = getCwd()
      local entry = getCmdsByCwd(cwd)[mode]
      -- Every build produces new binaries, so the artifact list is rebuilt on
      -- each read instead of being cached alongside the commands.
      if mode == "artifact" then
        entry.picks = vim.tbl_filter(function(path)
          return vim.fn.filereadable(path) == 1
        end, entry.picks)
        entry.display = merge(entry.picks, M.expandArtifacts(opts.artifacts, cwd))
      end
      return entry.display
    end
  end

  -- Records a pick, returning a closure that persists it -- so a command is
  -- only remembered once it has actually succeeded.
  local function recordCmd(mode)
    return function(cmd)
      local cwd = getCwd()
      local entry = getCmdsByCwd(cwd)[mode]
      entry.picks = M.insertCmdInList(entry.picks, cmd)
      entry.display = merge(entry.picks, tolist(defaultsFor(cwd)[mode]))
      return function()
        M.storeCmds(mode, entry.picks, cwd)
      end
    end
  end

  local getMakeCmds = getCmds("make")

  local pattern = opts.pattern or { opts.filetype }

  autocmd("Filetype", {
    group = "WorkspaceQuickfix",
    pattern = pattern,
    callback = function(o)
      if lintcmd ~= nil then
        M.mapMake({
          getCwd = getCwd,
          getCmds = getCmds("lint"),
          recordCmd = recordCmd("lint"),
          grepcmd = grepcmds.lint,
          buffer = o.buf,
          descDefault = "Lint project",
          descCustom = "Lint project (custom cmd)",
          mappingDefault = "<leader>yl",
          mappingCustom = "<leader>yL",
          label = "Running linter...",
        })
      end

      if opts.asmcmd ~= nil then
        M.mapMakeAsm({
          getCwd = getCwd,
          getCmds = getCmds("asm"),
          recordCmd = recordCmd("asm"),
          getArtifacts = getCmds("artifact"),
          recordArtifact = recordCmd("artifact"),
          grepcmd = grepcmds.asm or grepcmds.make,
          buffer = o.buf,
          descDefault = "Build + view asm",
          descCustom = "Build + view asm (pick optimisation)",
          mappingDefault = "<leader>ya",
          mappingCustom = "<leader>yA",
          label = "Building for asm view...",
        })
      end

      if makecmd ~= nil then
        M.mapMake({
          getCwd = getCwd,
          getCmds = getCmds("make"),
          recordCmd = recordCmd("make"),
          grepcmd = grepcmds.make,
          buffer = o.buf,
          descDefault = "Build project",
          descCustom = "Build project (custom cmd)",
          mappingDefault = "<leader>yb",
          mappingCustom = "<leader>yB",
          label = "Building project...",
        })

        if runcmd ~= nil then
          M.mapMakeRun({
            getCwd = getCwd,
            getCmds = getCmds("run"),
            getMakeCmds = getMakeCmds,
            recordCmd = recordCmd("run"),
            grepcmd = grepcmds.make,
            buffer = o.buf,
            descDefault = "Run project",
            descCustom = "Run project (custom cmd)",
            mappingDefault = "<leader>yr",
            mappingCustom = "<leader>yR",
            label = "Building and running project...",
          })
        end
      end
    end,
  })
end

augroup("WorkspaceQuickfix", { clear = true })

-- `asmcmd` lists exist to be stepped through: the first entry is the default,
-- <leader>yA offers the rest. Comparing what each optimisation level emits for
-- the same function is the point of the asm view.
M.makeLanguage({
  pattern = { "zig" },
  grepcmd = "2>&1 | grep -E '^.+:[0-9]+:[0-9]+'",
  makecmd = "zig build",
  runcmd = "zig build run",
  asmcmd = {
    "zig build -Doptimize=ReleaseFast",
    "zig build -Doptimize=ReleaseSmall",
    "zig build -Doptimize=ReleaseSafe",
    "zig build -Doptimize=Debug",
  },
  artifacts = "zig-out/bin/*",
  cwd_roots = { "build.zig", "build.zig.zon" },
})

M.makeLanguage({
  pattern = { "odin" },
  grepcmd = "2>&1 | grep -E '^.+\\([0-9]+:[0-9]+\\)' | sed -E 's/\\(([0-9]+:[0-9]+)\\)/:\\1/g'",
  makecmd = "odin build .",
  runcmd = "odin run .",
  -- -debug is what emits DWARF at all; without it there is nothing to
  -- correlate against. Odin's line table thins out considerably at -o:speed.
  asmcmd = {
    "odin build . -o:speed -debug",
    "odin build . -o:size -debug",
    "odin build . -o:minimal -debug",
    "odin build . -o:none -debug",
  },
  -- odin names the binary after its directory
  artifacts = function(cwd)
    return { vim.fs.basename(cwd) }
  end,
})

M.makeLanguage({
  pattern = { "go" },
  grepcmds = {
    lint = "2>/dev/null | grep -E '^.+:[0-9]+:[0-9]+'",
    make = "2>&1 | grep -E '^.+:[0-9]+:[0-9]+'",
  },
  lintcmd = "golangci-lint run --timeout 300s --config .golangci.yml ./...",
  makecmd = "go build ./...",
  runcmd = "go run .",
  -- An explicit -o keeps the artifact path predictable; `go build .` names the
  -- binary after the module, not the directory. Worth gitignoring.
  -- `all=-N -l` disables optimisation and inlining, which is the only way to
  -- see a small function at all -- Go inlines them out of existence otherwise.
  asmcmd = {
    "go build -o ./asm-out .",
    "go build -gcflags='all=-N -l' -o ./asm-out .",
    "go build -gcflags='-m' -o ./asm-out .",
  },
  artifacts = "asm-out",
  cwd_roots = { "go.mod", "go.sum" },
})

M.makeLanguage({
  pattern = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
  grepcmds = {
    lint = '2>/dev/null | awk \'/^(\\/.+)$/ { file=$1; } /^\\s*[0-9]+:[0-9]+/ {  errorMsg=""; for (i=3;i<=NF;++i) errorMsg=errorMsg " " $i; print file ":" $1 " " $2 " " errorMsg }\'',
    make = "2>/dev/null | grep -E '^.+\\([0-9]+,[0-9]+\\)' | sed -E 's/^(.+)\\(([0-9]+),([0-9]+)\\):(.*)/\\1:\\2:\\3 \\4/g'",
  },
  lintcmd = "yarn lint",
  makecmd = "yarn build",
  runcmd = "yarn start",
  cwd_roots = { "package.json", "yarn.lock" },
})

M.makeLanguage({
  pattern = { "c", "cpp" },
  grepcmd = "2>&1 | grep -E '^.+:[0-9]+:[0-9]+'",
  makecmd = "make",
  runcmd = "./out",
  -- -g alongside an optimisation level is the combination worth looking at: a
  -- plain debug build produces asm that mirrors the source and teaches little.
  asmcmd = {
    'make CFLAGS="-O2 -g" CXXFLAGS="-O2 -g"',
    'make CFLAGS="-O3 -g -march=native" CXXFLAGS="-O3 -g -march=native"',
    'make CFLAGS="-Os -g" CXXFLAGS="-Os -g"',
    'make CFLAGS="-O0 -g" CXXFLAGS="-O0 -g"',
  },
  artifacts = { "out", "build/*", "zig-out/bin/*" },
  cwd_roots = { "Makefile", "compile_commands.json", "build.zig" },
})

M.makeLanguage({
  pattern = { "ocaml", "dune" },
  grepcmd = "2>&1 | grep -E '^.+:[0-9]+:[0-9]+'",
  makecmd = "dune build",
  runcmd = "dune exec myapp",
  asmcmd = { "dune build --profile release", "dune build" },
  artifacts = { "_build/default/*.exe", "_build/default/bin/*.exe" },
  cwd_roots = { "dune-project" },
})

return M
