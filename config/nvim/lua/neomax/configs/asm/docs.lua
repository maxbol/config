-- Instruction documentation, one provider per architecture.
--
-- The rest of the module never names an instruction set; this is the single
-- place that does. An architecture with no provider fails cleanly rather than
-- opening something from the wrong ISA.

local M = {}

---@class AsmDocTarget
---@field kind "man"
---@field page string
---@field label string

--- x86 ----------------------------------------------------------------------

-- Intel documents conditional instructions once, under a `cc` umbrella: there
-- is an x86-jcc page but no x86-je.
local CONDITIONS = {}
for _, cc in ipairs({
  "o",
  "no",
  "b",
  "c",
  "nae",
  "ae",
  "nb",
  "nc",
  "e",
  "z",
  "ne",
  "nz",
  "be",
  "na",
  "a",
  "nbe",
  "s",
  "ns",
  "p",
  "pe",
  "po",
  "np",
  "l",
  "nge",
  "ge",
  "nl",
  "le",
  "ng",
  "g",
  "nle",
}) do
  CONDITIONS[cc] = true
end

local CC_FAMILIES = {
  { prefix = "fcmov", page = "fcmovcc" }, -- before "cmov" would mis-split it
  { prefix = "cmov", page = "cmovcc" },
  { prefix = "loop", page = "loopcc" },
  { prefix = "set", page = "setcc" },
  { prefix = "j", page = "jcc" },
}

local SIZE_SUFFIXES = { b = true, w = true, l = true, q = true }

---Drops an AT&T operand-size suffix, if there is one to drop.
---@return string|nil
local function strip_suffix(mnemonic)
  local last = mnemonic:sub(-1)
  local base = mnemonic:sub(1, -2)
  if #base >= 2 and SIZE_SUFFIXES[last] then
    return base
  end
end

local function uses_vector_registers(operands)
  return operands:find("%%[xyz]mm") ~= nil
end

---Page names to try, best first.
---
---Neither "exact first" nor "strip first" is right on its own. `movq %rsp,
---%rbp` is MOV with a q suffix, but x86-movq also exists as the MMX/SSE MOVQ;
---`movsd` is a page in its own right and must never be stripped to `movs`.
---The operands settle it: vector registers mean the exact page is wanted.
---@param mnemonic string
---@param operands string
---@return string[]
function M.x86_candidates(mnemonic, operands)
  local m = mnemonic:lower()
  operands = operands or ""

  for _, family in ipairs(CC_FAMILIES) do
    if #m > #family.prefix and m:sub(1, #family.prefix) == family.prefix then
      if CONDITIONS[m:sub(#family.prefix + 1)] then
        return { family.page }
      end
    end
  end

  local stripped = strip_suffix(m)
  if not stripped then
    return { m }
  end
  if uses_vector_registers(operands) then
    return { m, stripped }
  end
  return { stripped, m }
end

--- Page lookup ---------------------------------------------------------------

M.page_cache = {}

---Whether a manual page exists. Replaceable, so the resolution rules can be
---tested without the pages installed.
---@param page string
---@return boolean
function M.has_page(page)
  local cached = M.page_cache[page]
  if cached ~= nil then
    return cached
  end

  local found = false
  if vim.fn.executable("man") == 1 then
    local res = vim.system({ "man", "-w", page }, { text = true }):wait(2000)
    found = res.code == 0
  end

  M.page_cache[page] = found
  return found
end

function M.clear_cache()
  M.page_cache = {}
end

--- Providers -----------------------------------------------------------------

local function x86_provider()
  return {
    name = "x86-manpages",
    install_hint = "x86 instruction pages are missing -- add the x86-manpages package",
    resolve = function(insn)
      local candidates = M.x86_candidates(insn.mnemonic, insn.operands)
      local tried = {}

      for _, candidate in ipairs(candidates) do
        local page = "x86-" .. candidate
        tried[#tried + 1] = page
        if M.has_page(page) then
          return { kind = "man", page = page, label = candidate:upper() }
        end
      end

      return nil, ("no page for `%s` (tried %s)"):format(insn.mnemonic, table.concat(tried, ", "))
    end,
  }
end

M.providers = {
  x86_64 = x86_provider(),
  x86 = x86_provider(),
}

---Resolves an instruction to its documentation.
---@param arch string from model.arch
---@param insn table a row of kind "insn"
---@return AsmDocTarget|nil target, string|nil reason
function M.resolve(arch, insn)
  local provider = M.providers[arch]
  if not provider then
    return nil, "no documentation provider for " .. tostring(arch)
  end
  if not insn or not insn.mnemonic then
    return nil, "no instruction here"
  end
  return provider.resolve(insn)
end

---Command modifier for the documentation window.
---
---`botright` puts it across the full width of the screen rather than carving
---up the current window: with source and assembly already side by side, a
---third vertical split leaves a manual page too narrow to read, and a plain
---`horizontal` split would only divide the pane it was invoked from.
---`topleft` behaves the same way at the top; `vertical` restores the old
---behaviour.
M.split = "botright"

---Height of the documentation window, or nil for vim's default (half).
M.height = nil

---Opens a resolved target.
---
---Neovim's own :Man reuses an existing manual window when there is one, so
---repeated lookups replace the page rather than stacking splits.
---@param target AsmDocTarget
function M.open(target)
  vim.cmd(("%s Man %s"):format(M.split, target.page))
  if M.height then
    vim.cmd("resize " .. M.height)
  end
end

return M
