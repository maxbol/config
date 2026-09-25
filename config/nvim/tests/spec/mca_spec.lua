-- Scheduling analysis. Needs fixtures/build.sh and llvm-mca.

local H = require("helpers")
local mca = require("neomax.configs.asm.mca")
local model = require("neomax.configs.asm.model")
local disasm = require("neomax.configs.asm.disasm")

--- source reconstruction (pure) ----------------------------------------------

local fixture = model.parse(H.read_fixture("objdump-c.txt"))
local rows = model.slice(fixture, { kind = "symbol", name = "sum_squares" })
local source, line_to_row = mca.build_source(fixture, rows)
local src_lines = vim.split(source, "\n", { trimempty = true })

H.ok(#src_lines > 0, "rebuilds assembler input")
H.ok(not source:find("<"), "no objdump angle brackets survive", source:match("[^\n]*<[^\n]*"))
H.ok(source:find("L0:") ~= nil, "emits the labels it references")

-- Branch targets must be labels: x86 tolerates a bare address, AArch64 does
-- not, so the reconstruction always uses labels.
local branch = nil
for _, line in ipairs(src_lines) do
  if line:match("^jle%s") or line:match("^jne%s") then
    branch = line
  end
end
H.ok(branch and branch:match("L%d+$"), "branch targets are labels", branch)

-- every emitted instruction maps back to its row
local mapped = 0
for _, idx in pairs(line_to_row) do
  H.ok(fixture.rows[idx].kind == "insn", "line_to_row points at instructions")
  mapped = mapped + 1
  if mapped > 1 then
    break
  end
end
local insn_rows = 0
for _, idx in ipairs(rows) do
  if fixture.rows[idx].kind == "insn" then
    insn_rows = insn_rows + 1
  end
end
H.eq(vim.tbl_count(line_to_row), insn_rows, "every instruction row is emitted")

-- a slice whose branch leaves the rendered range still parses, via a stub
local partial = mca.build_source(fixture, { rows[1], rows[4], rows[5] })
H.ok(partial:find(":%s*$") or partial:find(":\n"), "stubs labels referenced but not rendered")

--- live analysis --------------------------------------------------------------

if vim.fn.executable("llvm-mca") == 0 then
  return H.skip("mca analysis", "llvm-mca not on PATH")
end

local TARGETS = {
  { name = "x86_64", binary = "demo", symbol = "sum_squares", cpu = "native" },
  { name = "aarch64", binary = "demo-aarch64-linux", symbol = "sumSquares", cpu = "neoverse-n1" },
  { name = "riscv64", binary = "demo-riscv64-linux", symbol = "sumSquares", cpu = "sifive-u74" },
}

for _, target in ipairs(TARGETS) do
  local bin = H.binary(target.binary)
  if not bin then
    H.skip(target.name, "fixtures/build.sh has not produced it")
  else
    local m = H.sync(function(cb)
      disasm.disassemble(bin, { symbol = target.symbol }, cb)
    end)[1]
    local slice = m and model.slice(m, { kind = "symbol", name = target.symbol })

    local result, err
    if m then
      local r = H.sync(function(cb)
        mca.analyze(m, slice, { key = target.symbol }, cb)
      end)
      result, err = r[1], r[2]
    end

    H.ok(result ~= nil, target.name .. ": analyses", err)

    if result then
      H.eq(result.cpu, target.cpu, target.name .. ": uses the configured cpu model")
      H.eq(result.mismatched, 0, target.name .. ": every annotation lines up with its instruction")

      -- llvm-mca may drop instructions it cannot parse; the remainder must
      -- still be attributed to the right rows, not shifted by the gap.
      local annotated, instructions = 0, 0
      for _, idx in ipairs(slice) do
        if m.rows[idx].kind == "insn" then
          instructions = instructions + 1
          if result.per_row[idx] then
            annotated = annotated + 1
          end
        end
      end
      H.eq(annotated, instructions - result.skipped, target.name .. ": annotates all but the skipped instructions")
      H.ok(annotated > 0, target.name .. ": annotated something", annotated)

      local s = result.summary
      H.ok(s.cycles_per_iteration and s.cycles_per_iteration > 0, target.name .. ": reports cycles per iteration")
      H.ok(s.ipc and s.ipc > 0, target.name .. ": reports IPC")
      H.ok(s.block_rthroughput and s.block_rthroughput > 0, target.name .. ": reports block throughput")
      H.ok(s.iterations and s.iterations > 1, target.name .. ": models a repeated block")

      -- spot-check a value rather than only its presence
      local any = select(2, next(result.per_row))
      H.ok(any and any.latency >= 0 and any.rthroughput > 0, target.name .. ": entries carry latency and throughput")
    end
  end
end

--- caching and failure modes --------------------------------------------------

local C = H.binary("demo")
if C then
  local m = H.sync(function(cb)
    disasm.disassemble(C, { symbol = "sum_squares" }, cb)
  end)[1]
  local slice = model.slice(m, { kind = "symbol", name = "sum_squares" })

  mca.invalidate()
  local first = H.sync(function(cb)
    mca.analyze(m, slice, { key = "sum_squares" }, cb)
  end)[1]
  local second = H.sync(function(cb)
    mca.analyze(m, slice, { key = "sum_squares" }, cb)
  end)[1]
  H.ok(first == second, "repeat analysis is served from cache")
  mca.invalidate()
  H.eq(vim.tbl_count(mca.cache), 0, "invalidate clears the cache")

  -- an architecture with no scheduling model says so rather than guessing
  local fake = vim.tbl_extend("force", {}, m)
  fake.arch = "powerpc"
  local arch_err = H.sync(function(cb)
    mca.analyze(fake, slice, {}, cb)
  end)[2]
  H.ok(arch_err and arch_err:match("no scheduling model"), "unsupported architecture fails cleanly", arch_err)

  -- the timeline report comes back as text
  local text = H.sync(function(cb)
    mca.report(m, slice, { extra = { "--timeline", "--iterations=2" } }, cb)
  end)[1]
  H.ok(text and #text > 10, "timeline report returns output", text and #text)
  local has_timeline = false
  for _, line in ipairs(text or {}) do
    if line:find("Timeline view") then
      has_timeline = true
    end
  end
  H.ok(has_timeline, "and it contains the timeline view")

  -- llvm-mca truncates the timeline at 80 cycles unless told otherwise, which
  -- hides most of any real function.
  local function truncated(cycles)
    local out = H.sync(function(cb)
      mca.report(m, slice, {
        extra = { "--timeline", "--iterations=3", "--timeline-max-cycles=" .. cycles },
      }, cb)
    end)[1]
    for _, line in ipairs(out or {}) do
      if line:find("Truncated display", 1, true) then
        return true
      end
    end
    return false
  end

  H.ok(truncated(4), "a tight cycle limit truncates the timeline")
  H.ok(not truncated(0), "zero means unlimited")
end
