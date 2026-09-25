-- Parses `llvm-objdump -d --line-numbers` output into a row list plus the
-- lookup tables the split view needs.
--
-- Deliberately free of any vim API, so it can be unit tested against fixture
-- dumps from every compiler we care about -- which is where the interesting
-- bugs live.

local M = {}

-- "    11b0:      \ttestl\t%edi, %edi" -- spaces, then a literal tab.
local INSN = "^%s*(%x+):%s*\t(.*)$"
local SYM = "^(%x+) <(.+)>:$"
local LABEL = "^<(.+)>:$"
local SECTION = "^Disassembly of section (.+):$"
local FUNC = "^; (.+)%(%):$"
local SRC = "^; (.+):(%d+)$"
local SRC_DISC = "^; (.+):(%d+) %(discriminator %d+%)$"
local FORMAT = "^.+:\tfile format (.+)$"

-- objdump names the target in its header; normalising it here is what lets
-- per-architecture features (documentation lookup, scheduling models) exist
-- without the rest of the module knowing about any instruction set.
local ARCH_FORMATS = {
  { pattern = "x86%-64", arch = "x86_64" },
  { pattern = "i386", arch = "x86" },
  { pattern = "aarch64", arch = "aarch64" },
  { pattern = "arm", arch = "arm" },
  { pattern = "riscv", arch = "riscv" },
  { pattern = "powerpc64", arch = "powerpc64" },
  { pattern = "powerpc", arch = "powerpc" },
}

---@param format string e.g. "elf64-x86-64", "elf64-littleaarch64"
---@return string arch normalised name, or "unknown"
function M.normalise_arch(format)
  for _, entry in ipairs(ARCH_FORMATS) do
    if format:find(entry.pattern) then
      -- riscv and arm come in 32- and 64-bit flavours; keep the width.
      if entry.arch == "riscv" then
        return format:find("elf64") and "riscv64" or "riscv32"
      end
      return entry.arch
    end
  end
  return "unknown"
end

---Splits an instruction body into mnemonic, operands and a branch target.
---@param body string
local function split_insn(body)
  local mnemonic, operands = body:match("^(%S+)\t(.*)$")
  if not mnemonic then
    mnemonic, operands = body:match("^(%S+)%s*(.*)$")
  end
  -- Symbolised branch targets render as `<L0>` or `<sym+0x1c>`.
  local ref = (operands or ""):match("<([^>]+)>")
  return mnemonic or body, operands or "", ref
end

---@param lines string[] raw objdump stdout, one entry per line
---@return table model
function M.parse(lines)
  local rows = {}
  local by_src = {} -- file -> line -> { row index, ... }
  local by_addr = {} -- address -> row index
  local syms = {} -- ordered symbol table
  local labels = {} -- label name -> row index, for jump-to-target

  -- Source position carried forward from the last `; file:line` comment.
  -- Reset at every symbol boundary: a symbol built without debug info must
  -- not inherit the previous symbol's position.
  local file, line, sym
  local arch, arch_raw

  local function push(row)
    rows[#rows + 1] = row
    return #rows
  end

  for _, raw in ipairs(lines) do
    local text = raw:gsub("%s+$", "")

    if text == "" then
      goto continue
    end

    do
      local format = text:match(FORMAT)
      if format then
        arch, arch_raw = M.normalise_arch(format), format
        goto continue
      end
    end

    do
      local section = text:match(SECTION)
      if section then
        file, line, sym = nil, nil, nil
        push({ kind = "section", text = section })
        goto continue
      end

      local sym_addr, sym_name = text:match(SYM)
      if sym_addr then
        file, line = nil, nil
        sym = sym_name
        local idx = push({ kind = "sym", text = sym_name, addr = tonumber(sym_addr, 16) })
        syms[#syms + 1] = {
          name = sym_name,
          addr = tonumber(sym_addr, 16),
          row = idx,
          first_insn = nil,
          last_insn = nil,
        }
        goto continue
      end

      -- `; sum_squares():` -- a demangled name for the symbol above, not a
      -- source position. Kept for display only.
      local func = text:match(FUNC)
      if func then
        push({ kind = "func", text = func, sym = sym })
        goto continue
      end

      local src_file, src_line = text:match(SRC_DISC)
      if not src_file then
        src_file, src_line = text:match(SRC)
      end
      if src_file then
        file, line = src_file, tonumber(src_line)
        push({ kind = "src", text = text:sub(3), file = file, line = line, sym = sym })
        goto continue
      end

      local label = text:match(LABEL)
      if label then
        local idx = push({ kind = "label", text = label, sym = sym })
        labels[label] = idx
        goto continue
      end

      local addr, body = text:match(INSN)
      if addr then
        local mnemonic, operands, ref = split_insn(body)
        local naddr = tonumber(addr, 16)
        local idx = push({
          kind = "insn",
          addr = naddr,
          text = body,
          mnemonic = mnemonic,
          operands = operands,
          ref = ref,
          file = file,
          line = line,
          sym = sym,
        })

        by_addr[naddr] = idx
        if file and line then
          local per_file = by_src[file]
          if not per_file then
            per_file = {}
            by_src[file] = per_file
          end
          local at_line = per_file[line]
          if not at_line then
            at_line = {}
            per_file[line] = at_line
          end
          at_line[#at_line + 1] = idx
        end

        local current = syms[#syms]
        if current then
          current.first_insn = current.first_insn or idx
          current.last_insn = idx
        end
        goto continue
      end

      -- Anything left (`...` gap markers, stray notes) is shown verbatim and
      -- carries no mapping.
      push({ kind = "other", text = text })
    end

    ::continue::
  end

  -- A symbol owns every row up to the next symbol header.
  for i, sym in ipairs(syms) do
    sym.last_row = syms[i + 1] and (syms[i + 1].row - 1) or #rows
  end

  return {
    rows = rows,
    by_src = by_src,
    by_addr = by_addr,
    syms = syms,
    labels = labels,
    arch = arch or "unknown",
    arch_raw = arch_raw,
  }
end

---@param model table
---@param name string
---@return table|nil
function M.symbol(model, name)
  for _, sym in ipairs(model.syms) do
    if sym.name == name then
      return sym
    end
  end
end

---The rows to render for a scope, as indices into `model.rows`.
---
---Scopes are views onto one parsed model rather than separate disassembly
---runs, so re-targeting the view costs nothing once the model exists.
---@param model table
---@param scope { kind: "symbol"|"file"|"all", name?: string, file?: string }
---@return integer[]|nil rows, string|nil err
function M.slice(model, scope)
  if scope.kind == "all" then
    local out = {}
    for i = 1, #model.rows do
      out[i] = i
    end
    return out
  end

  if scope.kind == "symbol" then
    local sym = M.symbol(model, scope.name)
    if not sym then
      return nil, "symbol not in model: " .. tostring(scope.name)
    end
    local out = {}
    for i = sym.row, sym.last_row do
      out[#out + 1] = i
    end
    return out
  end

  if scope.kind == "file" then
    -- Everything the file generated, wherever it ended up. Code inlined into
    -- other functions shows up under those functions, which is the point:
    -- it is the only view that reveals where your code actually went.
    local out = {}
    local current_sym, emitted_sym, pending_src = nil, nil, nil

    for i, row in ipairs(model.rows) do
      if row.kind == "sym" then
        current_sym = i
      elseif row.kind == "src" then
        pending_src = row.file == scope.file and i or nil
      elseif row.kind == "insn" and row.file == scope.file then
        if current_sym and emitted_sym ~= current_sym then
          out[#out + 1] = current_sym
          emitted_sym = current_sym
        end
        if pending_src then
          out[#out + 1] = pending_src
          pending_src = nil
        end
        out[#out + 1] = i
      end
    end

    if #out == 0 then
      return nil, "no instructions from " .. tostring(scope.file)
    end
    return out
  end

  return nil, "unknown scope: " .. tostring(scope.kind)
end

---Per-symbol source line coverage, built once and memoised on the model.
local function coverage(model)
  if model._coverage then
    return model._coverage
  end

  local cov = {}
  for _, row in ipairs(model.rows) do
    if row.kind == "insn" and row.sym and row.file and row.line then
      local per_sym = cov[row.sym]
      if not per_sym then
        per_sym = {}
        cov[row.sym] = per_sym
      end
      local span = per_sym[row.file]
      if not span then
        per_sym[row.file] = { min = row.line, max = row.line }
      else
        span.min = math.min(span.min, row.line)
        span.max = math.max(span.max, row.line)
      end
    end
  end

  model._coverage = cov
  return cov
end

---The symbol a source line belongs to.
---
---Inlining means a line can appear in several symbols at once -- in the C
---fixture, `square()` shows up in both `sum_squares` and the `main` that
---inlined it. The narrowest covering symbol is the specific one, so that is
---the one we pick; the caller can still offer the rest.
---@param model table
---@param file string
---@param line integer
---@return string|nil best, string[] all
function M.symbol_at(model, file, line)
  local per_file = model.by_src[file]
  local idxs = per_file and per_file[line]
  if not idxs then
    return nil, {}
  end

  local seen, names = {}, {}
  for _, idx in ipairs(idxs) do
    local sym = model.rows[idx].sym
    if sym and not seen[sym] then
      seen[sym] = true
      names[#names + 1] = sym
    end
  end

  local cov = coverage(model)
  local best, best_span
  for _, name in ipairs(names) do
    local span = cov[name] and cov[name][file]
    local width = span and (span.max - span.min) or math.huge
    if not best or width < best_span then
      best, best_span = name, width
    end
  end

  return best, names
end

---The symbol owning the nearest mapped line to `line`.
---
---A cursor often sits somewhere that generated no code at all -- a blank
---line, a comment, a declaration -- and failing there would make pin feel
---broken. Searching outwards finds the enclosing function instead.
---@param model table
---@param file string
---@param line integer
---Kept deliberately local: searching far enough to cross a function boundary
---would return an arbitrary neighbour rather than the enclosing function, so
---beyond this the caller should fall back to something it knows.
---@param radius? integer how far to search, in lines (default 25)
---@return string|nil symbol, integer|nil at_line
function M.symbol_near(model, file, line, radius)
  local per_file = model.by_src[file]
  if not per_file then
    return nil, nil
  end

  for delta = 0, radius or 25 do
    local candidates = delta == 0 and { line } or { line - delta, line + delta }
    for _, candidate in ipairs(candidates) do
      if candidate >= 1 and per_file[candidate] then
        local sym = M.symbol_at(model, file, candidate)
        if sym then
          return sym, candidate
        end
      end
    end
  end

  return nil, nil
end

---Every source file the dump attributes instructions to.
---@param model table
---@return string[]
function M.files(model)
  local out = {}
  for file in pairs(model.by_src) do
    out[#out + 1] = file
  end
  table.sort(out)
  return out
end

---Rows generated by `file`, for the per-file scope. Ordered by address, so
---code inlined into other symbols still appears in a sensible place.
---@param model table
---@param file string
---@return integer[] row indices
function M.rows_for_file(model, file)
  local per_file = model.by_src[file]
  if not per_file then
    return {}
  end
  local out = {}
  for _, idxs in pairs(per_file) do
    for _, idx in ipairs(idxs) do
      out[#out + 1] = idx
    end
  end
  table.sort(out, function(a, b)
    return model.rows[a].addr < model.rows[b].addr
  end)
  return out
end

---How many instructions a given source line produced. Drives the gutter
---density hint.
---@return integer
function M.insn_count(model, file, line)
  local per_file = model.by_src[file]
  local at_line = per_file and per_file[line]
  return at_line and #at_line or 0
end

return M
