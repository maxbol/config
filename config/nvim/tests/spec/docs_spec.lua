-- Instruction documentation lookup.
--
-- The resolution rules are tested against the committed list of page names, so
-- they run whether or not the manual pages are installed.

local H = require("helpers")
local docs = require("neomax.configs.asm.docs")

--- candidate generation (pure) ----------------------------------------------

local function cands(mnemonic, operands)
  return docs.x86_candidates(mnemonic, operands)
end

H.eq(cands("movl", "%eax, %ecx"), { "mov", "movl" }, "strips an AT&T size suffix")
H.eq(cands("imull", "%eax, %ecx"), { "imul", "imull" }, "strips from imull")
H.eq(cands("retq", ""), { "ret", "retq" }, "strips from retq")

-- x86-movq exists as the MMX/SSE MOVQ, so the operands decide which is meant
H.eq(cands("movq", "%rsp, %rbp"), { "mov", "movq" }, "integer movq prefers MOV")
H.eq(cands("movq", "%xmm0, %rax"), { "movq", "mov" }, "vector movq prefers MOVQ")
H.eq(cands("movd", "%xmm0, %eax"), { "movd" }, "movd is not suffix-stripped")

-- instructions that merely end in a suffix letter must not be stripped
H.eq(cands("movsd", "%xmm0, %xmm1"), { "movsd" }, "movsd is its own instruction")
H.eq(cands("movss", "%xmm0, %xmm1"), { "movss" }, "movss is its own instruction")
H.eq(cands("addsd", "%xmm1, %xmm0"), { "addsd" }, "addsd is its own instruction")

-- condition-code families are documented once, under a cc umbrella
for _, m in ipairs({ "je", "jne", "jle", "jg", "jbe", "jnae" }) do
  H.eq(cands(m, ""), { "jcc" }, m .. " resolves to jcc")
end
H.eq(cands("jmp", ""), { "jmp" }, "jmp is not a conditional jump")
H.eq(cands("setle", "%al"), { "setcc" }, "setle resolves to setcc")
H.eq(cands("cmovne", "%eax, %ecx"), { "cmovcc" }, "cmovne resolves to cmovcc")
H.eq(cands("fcmovb", "%st(1)"), { "fcmovcc" }, "fcmovb resolves to fcmovcc, not cmovcc")
H.eq(cands("loope", ""), { "loopcc" }, "loope resolves to loopcc")
H.eq(cands("loop", ""), { "loop" }, "plain loop has its own page")
H.eq(cands("endbr64", ""), { "endbr64" }, "unknown instructions are left alone")

--- resolution against the real page list ------------------------------------

local pages = {}
for _, name in ipairs(H.read_fixture("x86-manpages-list.txt")) do
  pages[name] = true
end
H.ok(vim.tbl_count(pages) > 1000, "page list fixture loaded", vim.tbl_count(pages))

local real_has_page = docs.has_page
docs.has_page = function(page)
  return pages[page] == true
end
docs.clear_cache()

local function page_for(mnemonic, operands)
  local target = docs.resolve("x86_64", { kind = "insn", mnemonic = mnemonic, operands = operands })
  return target and target.page
end

H.eq(page_for("movl", "%eax, %ecx"), "x86-mov", "movl resolves to x86-mov")
H.eq(page_for("movq", "%rsp, %rbp"), "x86-mov", "integer movq resolves to x86-mov")
H.eq(page_for("movq", "%xmm0, %rax"), "x86-movq", "vector movq resolves to x86-movq")
H.eq(page_for("movsd", "%xmm0, %xmm1"), "x86-movsd", "movsd resolves to its own page")
H.eq(page_for("jle", ""), "x86-jcc", "jle resolves to x86-jcc")
H.eq(page_for("retq", ""), "x86-ret", "retq resolves to x86-ret")
H.eq(page_for("imull", "%eax"), "x86-imul", "imull resolves to x86-imul")
H.eq(page_for("nopl", "(%rax)"), "x86-nop", "nopl resolves to x86-nop")

-- instructions newer than the manual dump fail cleanly rather than guessing
local target, reason = docs.resolve("x86_64", { kind = "insn", mnemonic = "endbr64", operands = "" })
H.eq(target, nil, "endbr64 has no page")
H.ok(reason and reason:match("no page for `endbr64`"), "and says which pages it tried", reason)

-- every mnemonic in the committed disassembly resolves or fails cleanly
local model = require("neomax.configs.asm.model")
local m = model.parse(H.read_fixture("objdump-c.txt"))
local resolved, unresolved = 0, {}
for _, row in ipairs(m.rows) do
  if row.kind == "insn" then
    if page_for(row.mnemonic, row.operands) then
      resolved = resolved + 1
    else
      unresolved[row.mnemonic] = true
    end
  end
end
H.ok(resolved > 0, "resolves instructions from a real disassembly", resolved)
H.eq(vim.tbl_keys(unresolved), { "endbr64" }, "only endbr64 is unresolved in the C fixture")

--- provider dispatch ---------------------------------------------------------

H.eq(docs.resolve("aarch64", { mnemonic = "stp" }), nil, "no provider for aarch64 yet")
local _, arm_reason = docs.resolve("aarch64", { mnemonic = "stp" })
H.ok(arm_reason and arm_reason:match("no documentation provider"), "and says so plainly", arm_reason)
local _, unknown_reason = docs.resolve("unknown", { mnemonic = "mov" })
H.ok(unknown_reason ~= nil, "an unknown architecture fails cleanly")

docs.has_page = real_has_page
docs.clear_cache()

--- against the installed pages, if there are any -----------------------------

if docs.has_page("x86-mov") then
  H.eq(page_for("movl", "%eax"), "x86-mov", "resolves against the installed pages")
  H.ok(not docs.has_page("x86-definitely-not-real"), "a missing page is reported missing")

  -- The window has to span the screen: with source and assembly already side
  -- by side, a third vertical split leaves the page unreadably narrow.
  vim.cmd("runtime! plugin/man.lua")
  local function describe(node)
    if node[1] == "leaf" then
      return vim.fs.basename(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(node[2])))
    end
    local kids = {}
    for _, child in ipairs(node[2]) do
      kids[#kids + 1] = describe(child)
    end
    return node[1] .. "(" .. table.concat(kids, ", ") .. ")"
  end

  vim.cmd("only")
  vim.cmd("edit /tmp/neomax-src.txt")
  vim.cmd("vsplit /tmp/neomax-asm.txt")
  H.eq(describe(vim.fn.winlayout()), "row(neomax-asm.txt, neomax-src.txt)", "starts side by side")

  docs.open({ kind = "man", page = "x86-mov" })
  local layout = describe(vim.fn.winlayout())
  H.eq(
    layout,
    "col(row(neomax-asm.txt, neomax-src.txt), x86-mov(7))",
    "the page spans the whole screen rather than splitting one pane"
  )
  H.eq(#vim.api.nvim_tabpage_list_wins(0), 3, "three windows")

  -- repeated lookups replace the page instead of stacking splits
  docs.open({ kind = "man", page = "x86-imul" })
  H.eq(#vim.api.nvim_tabpage_list_wins(0), 3, "a second lookup reuses the window")
  H.ok(describe(vim.fn.winlayout()):find("x86%-imul"), "and shows the new page", describe(vim.fn.winlayout()))
  vim.cmd("only")
else
  H.skip("installed pages", "x86-manpages not on MANPATH (add modules/home-manager/asm-reference.nix)")
end
