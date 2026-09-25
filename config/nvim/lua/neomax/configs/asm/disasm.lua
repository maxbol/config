-- Runs a disassembler over a built artifact and hands back a parsed model.
--
-- One backend covers every language that emits DWARF, which is the whole
-- point: correlation comes from the line table, not from knowing the
-- language. Backends exist only for toolchains that can't be read that way.

local model = require("neomax.configs.asm.model")

local M = {}

-- Parsed models, keyed by artifact identity plus scope, so a rebuild
-- invalidates itself. Symbol tables are cached separately in M.symcache.
M.cache = {}
M.symcache = {}

M.backends = {
  objdump = {
    tool = "llvm-objdump",
    ---@param opts { range?: { start: integer, stop: integer }, symbol?: string }
    args = function(opts)
      local args = {
        "-d",
        "--line-numbers",
        "--symbolize-operands",
        "--no-show-raw-insn",
      }
      if opts.range then
        -- Preferred: addresses can't be misparsed. `--disassemble-symbols`
        -- takes a COMMA-SEPARATED list, so any symbol whose name contains a
        -- comma -- every Zig generic instantiation, most C++ templates --
        -- is silently split into nonexistent names and matches nothing.
        table.insert(args, ("--start-address=0x%x"):format(opts.range.start))
        table.insert(args, ("--stop-address=0x%x"):format(opts.range.stop))
      elseif opts.symbol then
        table.insert(args, "--disassemble-symbols=" .. opts.symbol)
      end
      return args
    end,
    parse = model.parse,
  },
}

M.default_backend = "objdump"

---Identity of an artifact as built: any rebuild changes this.
---@return string|nil
function M.artifact_key(artifact)
  local st = vim.uv.fs_stat(artifact)
  if not st then
    return nil
  end
  return table.concat({ artifact, st.mtime.sec, st.size }, "\0")
end

---Assembler bookkeeping that is never a useful disassembly target.
---
---`.L*` are GAS local labels and `$a`/`$d`/`$t`/`$x` are ELF mapping symbols
---marking code-vs-data boundaries on ARM, AArch64 and RISC-V. A RISC-V build
---of the test fixture carries 61k of them, and because they sit at arbitrary
---addresses they shadow the real function in an address lookup.
---@param name string
---@return boolean
local function internal_symbol(name)
  return name:match("^%.L") ~= nil or name:match("^%$[adtx]$") ~= nil or name:match("^%$[adtx]%.") ~= nil
end

---Higher is a better answer for "which symbol owns this address": a sized
---symbol beats a marker, and a global beats a local alias of it.
local function rank(sym)
  return (sym.size > 0 and 2 or 0) + (sym.local_ and 0 or 1)
end

---Lists the function symbols in an artifact, address-ordered, with sizes.
---Names are as the linker spells them, not demangled.
---@param artifact string
---@param cb fun(syms: {name:string, addr:integer, size:integer, local_:boolean}[]|nil, err: string|nil)
function M.symbols(artifact, cb)
  local key = M.artifact_key(artifact)
  if not key then
    return cb(nil, "no such artifact: " .. artifact)
  end
  if M.symcache[key] then
    return cb(M.symcache[key], nil)
  end

  vim.system({ "nm", "-S", "--defined-only", artifact }, { text = true }, function(res)
    local done = vim.schedule_wrap(function()
      if res.code ~= 0 then
        return cb(nil, "nm failed: " .. (res.stderr or ""):gsub("%s+$", ""))
      end

      local syms = {}
      for _, line in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
        -- "11b0 2d T sum_squares", or without the size column. The name may
        -- contain spaces, commas and parens, so it is everything after the
        -- type letter rather than a whitespace-delimited field.
        local addr, size, kind, name = line:match("^(%x+) (%x+) (%a) (.+)$")
        if not addr then
          addr, kind, name = line:match("^(%x+) (%a) (.+)$")
          size = "0"
        end
        if addr and kind:match("[TtWw]") and not internal_symbol(name) then
          syms[#syms + 1] = {
            name = name,
            addr = tonumber(addr, 16),
            size = tonumber(size, 16) or 0,
            local_ = kind:match("%l") ~= nil,
          }
        end
      end

      -- Several symbols can share an address (a global and its local alias,
      -- say). Address lookup takes the last match, so order the best one last.
      table.sort(syms, function(a, b)
        if a.addr ~= b.addr then
          return a.addr < b.addr
        end
        local ra, rb = rank(a), rank(b)
        if ra ~= rb then
          return ra < rb
        end
        return a.name > b.name
      end)

      M.symcache[key] = syms
      cb(syms, nil)
    end)
    done()
  end)
end

---The address range a symbol occupies. Prefers the ELF size; falls back to
---the next symbol's address for toolchains that emit sizeless symbols.
---@return { start: integer, stop: integer }|nil
local function range_of(syms, i)
  local sym = syms[i]
  if sym.size and sym.size > 0 then
    return { start = sym.addr, stop = sym.addr + sym.size }
  end
  for j = i + 1, #syms do
    if syms[j].addr > sym.addr then
      return { start = sym.addr, stop = syms[j].addr }
    end
  end
  return nil
end

---Resolves a symbol name to its address range.
---@param artifact string
---@param name string
---@param cb fun(range: table|nil, err: string|nil)
function M.resolve(artifact, name, cb)
  M.symbols(artifact, function(syms, err)
    if err then
      return cb(nil, err)
    end
    for i, sym in ipairs(syms) do
      if sym.name == name then
        local range = range_of(syms, i)
        if not range then
          return cb(nil, "cannot size symbol: " .. name)
        end
        return cb(range, nil)
      end
    end
    cb(nil, "symbol not found: " .. name)
  end)
end

local function run(artifact, opts, backend, backend_name, cb)
  local key = table.concat({
    backend_name,
    M.artifact_key(artifact) or artifact,
    opts.range and ("%x-%x"):format(opts.range.start, opts.range.stop) or (opts.symbol or "*"),
  }, "\0")

  local hit = M.cache[key]
  if hit then
    return cb(hit, nil)
  end

  local cmd = { backend.tool }
  vim.list_extend(cmd, backend.args(opts))
  vim.list_extend(cmd, opts.extra_args or {})
  table.insert(cmd, artifact)

  vim.system(cmd, { text = true }, function(res)
    local done = vim.schedule_wrap(function()
      if res.code ~= 0 then
        return cb(nil, backend.tool .. " failed: " .. (res.stderr or ""):gsub("%s+$", ""))
      end

      local m = backend.parse(vim.split(res.stdout or "", "\n", { trimempty = false }))
      m.artifact = artifact
      m.symbol = opts.symbol

      if #m.rows == 0 then
        local why = opts.symbol and ("nothing disassembled for symbol: " .. opts.symbol)
          or "nothing disassembled (stripped, or not a native binary?)"
        return cb(nil, why)
      end

      -- The most common setup error, and invisible otherwise: the artifact
      -- disassembles fine but carries no line table.
      m.has_debug_info = next(m.by_src) ~= nil

      M.cache[key] = m
      cb(m, nil)
    end)
    done()
  end)
end

---Disassembles `artifact`, optionally narrowed to a single symbol.
---
---Narrowing is what keeps this interactive: one symbol costs ~30ms even on a
---multi-megabyte binary, where a full pass costs closer to a second.
---@param artifact string
---@param opts { symbol?: string, range?: table, backend?: string, extra_args?: string[] }
---@param cb fun(m: table|nil, err: string|nil)
function M.disassemble(artifact, opts, cb)
  opts = opts or {}
  local backend_name = opts.backend or M.default_backend
  local backend = M.backends[backend_name]
  if not backend then
    return cb(nil, "unknown disassembler backend: " .. tostring(backend_name))
  end

  if vim.fn.executable(backend.tool) == 0 then
    return cb(nil, backend.tool .. " not found on PATH")
  end

  if not vim.uv.fs_stat(artifact) then
    return cb(nil, "no such artifact: " .. artifact)
  end

  if opts.symbol and not opts.range then
    return M.resolve(artifact, opts.symbol, function(range, err)
      if err then
        return cb(nil, err)
      end
      local scoped = vim.tbl_extend("force", opts, { range = range })
      run(artifact, scoped, backend, backend_name, cb)
    end)
  end

  run(artifact, opts, backend, backend_name, cb)
end

---Drops cached models and symbol tables. Keying on mtime makes this belt and
---braces, but an explicit clear after a rebuild is cheap.
function M.invalidate(artifact)
  if not artifact then
    M.cache, M.symcache = {}, {}
    return
  end
  for _, tbl in ipairs({ M.cache, M.symcache }) do
    for key in pairs(tbl) do
      if key:find(artifact, 1, true) then
        tbl[key] = nil
      end
    end
  end
end

return M
