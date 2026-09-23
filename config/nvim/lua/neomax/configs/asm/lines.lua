-- The DWARF line table on its own, without disassembling anything.
--
-- Answering "which function is this source line in?" needs addresses, not
-- instructions. Reading the line table directly costs ~70ms where a full
-- disassembly of the same binary costs ~1100ms, so this is what the
-- interactive paths -- opening after a build, pin, follow -- resolve against.
-- The full model is then only needed for the file and binary scopes.

local disasm = require("neomax.configs.asm.disasm")

local M = {}

M.tool = "llvm-dwarfdump"
M.cache = {}

--- Parsing ------------------------------------------------------------------

local CU = "^debug_line%[0x%x+%]$"
local DIR = '^include_directories%[%s*(%d+)%] = "(.*)"$'
local FILE = "^file_names%[%s*(%d+)%]:$"
local NAME = '^%s*name: "(.*)"$'
local DIR_INDEX = "^%s*dir_index: (%d+)$"
local ROW = "^0x(%x+)%s+(%d+)%s+(%d+)%s+(%d+)"

local function full_path(name, dir)
  if name:sub(1, 1) == "/" then
    return name
  end
  return dir and (dir .. "/" .. name) or name
end

---Parses `llvm-dwarfdump --debug-line` output.
---
---Pure Lua, so it can be tested against dumps from any toolchain.
---@param lines string[]
---@return table index { by_src = { [file] = { [line] = addresses } } }
function M.parse(lines)
  local by_src = {}

  -- Per compilation unit: file name indices are only meaningful within one.
  local dirs, files, pending = {}, {}, nil

  local function flush_pending()
    if pending and pending.index then
      files[pending.index] = full_path(pending.name or "", dirs[pending.dir_index or 0])
    end
    pending = nil
  end

  -- Row lines are the overwhelming majority, so they are recognised by a
  -- cheap prefix test before any of the header patterns are tried. On a large
  -- binary this is the difference between a snappy resolve and a stall.
  for _, raw in ipairs(lines) do
    if raw:byte(1) == 48 and raw:byte(2) == 120 then -- "0x"
      local addr, line, _, fidx = raw:match(ROW)
      if addr then
        if pending then
          flush_pending()
        end
        line = tonumber(line)
        -- line 0 marks end_sequence and similar bookkeeping rows
        local file = files[tonumber(fidx)]
        if file and line > 0 then
          local per_file = by_src[file]
          if not per_file then
            per_file = {}
            by_src[file] = per_file
          end
          local at = per_file[line]
          if not at then
            at = {}
            per_file[line] = at
          end
          at[#at + 1] = tonumber(addr, 16)
        end
      end
    else
      local text = raw:gsub("%s+$", "")

      if text:match(CU) then
        flush_pending()
        dirs, files = {}, {}
      else
        local dir_idx, dir_path = text:match(DIR)
        if dir_idx then
          flush_pending()
          dirs[tonumber(dir_idx)] = dir_path
        else
          local file_idx = text:match(FILE)
          if file_idx then
            flush_pending()
            pending = { index = tonumber(file_idx) }
          elseif pending then
            local name = text:match(NAME)
            local dir_index = text:match(DIR_INDEX)
            if name then
              pending.name = name
            elseif dir_index then
              pending.dir_index = tonumber(dir_index)
            end
          end
        end
      end
    end
  end

  flush_pending()
  return { by_src = by_src }
end

--- Symbol resolution --------------------------------------------------------

---The symbol covering `addr`, from an address-sorted nm listing.
---@return table|nil
function M.symbol_for_addr(syms, addr)
  local lo, hi, found = 1, #syms, nil
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if syms[mid].addr <= addr then
      found = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  if not found then
    return nil
  end

  local sym = syms[found]
  local stop = (sym.size and sym.size > 0) and (sym.addr + sym.size) or (syms[found + 1] and syms[found + 1].addr)
  if stop and addr >= stop then
    return nil
  end
  return sym
end

---Which symbols a source file's lines land in, and over what line span.
---Memoised per file on the index.
local function coverage(index, syms, file)
  index._coverage = index._coverage or {}
  if index._coverage[file] then
    return index._coverage[file]
  end

  local cov = {}
  for line, addrs in pairs(index.by_src[file] or {}) do
    for _, addr in ipairs(addrs) do
      local sym = M.symbol_for_addr(syms, addr)
      if sym then
        local span = cov[sym.name]
        if not span then
          cov[sym.name] = { min = line, max = line }
        else
          span.min = math.min(span.min, line)
          span.max = math.max(span.max, line)
        end
      end
    end
  end

  index._coverage[file] = cov
  return cov
end

---The symbol owning the nearest mapped line to `line`.
---
---Mirrors model.symbol_near, including the narrowest-covering-symbol rule, so
---that resolving through the line table and resolving through a full
---disassembly agree.
---@return string|nil
function M.symbol_near(index, syms, file, line, radius)
  local per_file = index.by_src[file]
  if not per_file then
    return nil
  end

  local cov = coverage(index, syms, file)

  for delta = 0, radius or 25 do
    local candidates = delta == 0 and { line } or { line - delta, line + delta }
    for _, candidate in ipairs(candidates) do
      if candidate >= 1 and per_file[candidate] then
        local best, best_width
        for _, addr in ipairs(per_file[candidate]) do
          local sym = M.symbol_for_addr(syms, addr)
          local span = sym and cov[sym.name]
          local width = span and (span.max - span.min) or math.huge
          if sym and (not best or width < best_width) then
            best, best_width = sym.name, width
          end
        end
        if best then
          return best
        end
      end
    end
  end
end

--- Loading ------------------------------------------------------------------

---Maps a buffer path onto the key the compiler recorded.
---@return string|nil
function M.resolve_file(index, bufpath)
  if bufpath == nil or bufpath == "" then
    return nil
  end

  index._filekey = index._filekey or {}
  local cached = index._filekey[bufpath]
  if cached ~= nil then
    return cached ~= false and cached or nil
  end

  local real = vim.uv.fs_realpath(bufpath) or bufpath
  local found = index.by_src[real] and real or nil

  if not found then
    for key in pairs(index.by_src) do
      local kreal = vim.uv.fs_realpath(key) or key
      if kreal == real then
        found = key
        break
      end
      if vim.endswith(real, "/" .. key) or vim.endswith(key, "/" .. real) then
        found = found or key
      end
    end
  end

  index._filekey[bufpath] = found or false
  return found
end

---Reads (and caches) the line table for an artifact.
---@param artifact string
---@param cb fun(index: table|nil, err: string|nil)
function M.load(artifact, cb)
  if vim.fn.executable(M.tool) == 0 then
    return cb(nil, M.tool .. " not found on PATH")
  end

  local key = disasm.artifact_key(artifact)
  if not key then
    return cb(nil, "no such artifact: " .. artifact)
  end
  if M.cache[key] then
    return cb(M.cache[key], nil)
  end

  vim.system({ M.tool, "--debug-line", artifact }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return cb(nil, M.tool .. " failed: " .. (res.stderr or ""):gsub("%s+$", ""))
      end

      local index = M.parse(vim.split(res.stdout or "", "\n", { trimempty = false }))
      if next(index.by_src) == nil then
        return cb(nil, "no line table -- build with debug info (-g) for source correlation")
      end

      M.cache[key] = index
      cb(index, nil)
    end)
  end)
end

---Resolves a source position to the symbol containing it, reading only the
---line table and the symbol table.
---@param artifact string
---@param bufpath string
---@param line integer
---@param cb fun(symbol: string|nil, err: string|nil)
function M.resolve(artifact, bufpath, line, cb)
  M.load(artifact, function(index, err)
    if err then
      return cb(nil, err)
    end

    local file = M.resolve_file(index, bufpath)
    if not file then
      return cb(nil, nil) -- this file contributed nothing; not an error
    end

    disasm.symbols(artifact, function(syms, sym_err)
      if sym_err then
        return cb(nil, sym_err)
      end
      cb(M.symbol_near(index, syms, file, line), nil)
    end)
  end)
end

function M.invalidate(artifact)
  if not artifact then
    M.cache = {}
    return
  end
  for key in pairs(M.cache) do
    if key:find(artifact, 1, true) then
      M.cache[key] = nil
    end
  end
end

return M
