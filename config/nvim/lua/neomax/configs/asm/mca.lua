-- Scheduling analysis via llvm-mca.
--
-- There is no single "cycle cost" on an out-of-order core, so this reports the
-- numbers that actually mean something: latency and reciprocal throughput per
-- instruction, and a block summary saying whether the loop is front-end,
-- throughput or latency bound.
--
-- llvm-mca models a steady-state loop with perfect caches and perfect branch
-- prediction. It answers "how fast could this go", not "how fast does it go".

local M = {}

M.tool = "llvm-mca"

-- Architecture -> how to invoke the scheduler. `native` only makes sense for
-- the host; cross-compiled binaries need a named model.
M.targets = {
  x86_64 = { triple = "x86_64", cpu = "native" },
  x86 = { triple = "i386", cpu = "native" },
  aarch64 = { triple = "aarch64", cpu = "neoverse-n1" },
  riscv64 = { triple = "riscv64", cpu = "sifive-u74" },
}

M.cache = {}

--- Reconstruction -----------------------------------------------------------

local function sanitise_label(name)
  return (name:gsub("[^%w_]", "_"))
end

---Rebuilds assembler input from rendered rows.
---
---Branch targets have to be labels: x86 tolerates a bare address, AArch64
---rejects it outright. Any label referenced but not present in the slice gets
---a stub, so a branch out of the rendered range still parses.
---@param model table
---@param rows integer[] indices into model.rows
---@return string source, table line_to_row
function M.build_source(model, rows)
  local out, line_to_row = {}, {}
  local emitted, referenced = {}, {}

  for _, idx in ipairs(rows) do
    local row = model.rows[idx]

    if row.kind == "label" then
      local name = sanitise_label(row.text)
      out[#out + 1] = name .. ":"
      emitted[name] = true
    elseif row.kind == "insn" then
      local text = row.text
      if row.ref then
        local name = sanitise_label(row.ref)
        referenced[name] = true
        text = text:gsub("<[^>]+>", name)
      end
      out[#out + 1] = text
      line_to_row[#out] = idx
    end
  end

  for name in pairs(referenced) do
    if not emitted[name] then
      out[#out + 1] = name .. ":"
    end
  end

  return table.concat(out, "\n") .. "\n", line_to_row
end

--- Parsing -------------------------------------------------------------------

---Lines llvm-mca refused, from its diagnostics. Dropping them shifts every
---later row, so they have to be accounted for rather than ignored.
---@return table<integer, boolean>
local function dropped_lines(stderr)
  local dropped = {}
  for line in (stderr or ""):gmatch("[^\n]+") do
    local n = line:match(":(%d+):%d+: error:")
    if n then
      dropped[tonumber(n)] = true
    end
  end
  return dropped
end

local function parse_summary(stdout)
  local function number(label)
    local value = stdout:match(label .. ":%s*([%d%.]+)")
    return tonumber(value)
  end

  local iterations = number("Iterations") or 1
  local cycles = number("Total Cycles")

  return {
    iterations = iterations,
    instructions = number("Instructions"),
    total_cycles = cycles,
    -- The number worth quoting: what one pass through the block costs once
    -- the pipeline is full.
    cycles_per_iteration = cycles and (cycles / iterations) or nil,
    uops = number("Total uOps"),
    dispatch_width = number("Dispatch Width"),
    uops_per_cycle = number("uOps Per Cycle"),
    ipc = number("IPC"),
    block_rthroughput = number("Block RThroughput"),
  }
end

---Per-instruction rows from the "Instruction Info" table, in input order.
---
---The flag columns may be blank, so the instruction text is located by the
---column where the header says it starts rather than by splitting on spaces.
local function parse_instruction_info(stdout)
  local body = stdout:match("Instruction Info:.-\n\n(.-)\n\n")
  if not body then
    return {}
  end

  local entries, column = {}, nil
  for line in body:gmatch("[^\n]+") do
    if not column then
      column = line:find("Instructions:")
    elseif column then
      local head = line:sub(1, column - 1)
      local uops, latency, rthroughput = head:match("^%s*(%d+)%s+(%d+)%s+([%d%.]+)")
      if uops then
        entries[#entries + 1] = {
          uops = tonumber(uops),
          latency = tonumber(latency),
          rthroughput = tonumber(rthroughput),
          may_load = head:find("%*") ~= nil,
          side_effects = head:find("U") ~= nil,
          text = line:sub(column),
        }
      end
    end
  end

  return entries
end

local function mnemonic_of(text)
  return (text:match("^(%S+)") or ""):lower()
end

--- Analysis ------------------------------------------------------------------

---Runs llvm-mca and hands back its output alongside the mapping from output
---position to model row.
---
---Instructions llvm-mca refuses are dropped from its input, which shifts
---every later result; `kept` is the surviving rows in output order.
local function invoke(model, rows, extra, opts, cb)
  if vim.fn.executable(M.tool) == 0 then
    return cb(nil, M.tool .. " not found on PATH")
  end

  local target = M.targets[model.arch]
  if not target then
    return cb(nil, "no scheduling model for " .. tostring(model.arch))
  end
  local cpu = opts.cpu or target.cpu

  local source, line_to_row = M.build_source(model, rows)
  if next(line_to_row) == nil then
    return cb(nil, "nothing to analyse")
  end

  local cmd = {
    M.tool,
    "-mtriple=" .. target.triple,
    "-mcpu=" .. cpu,
    "-skip-unsupported-instructions=parse-failure",
  }
  vim.list_extend(cmd, extra or {})

  vim.system(cmd, { stdin = source, text = true }, function(res)
    vim.schedule(function()
      local dropped = dropped_lines(res.stderr)
      local kept, total = {}, select(2, source:gsub("\n", "\n"))
      for line = 1, total do
        if line_to_row[line] and not dropped[line] then
          kept[#kept + 1] = line_to_row[line]
        end
      end
      cb({
        stdout = res.stdout or "",
        stderr = res.stderr or "",
        kept = kept,
        cpu = cpu,
        skipped = vim.tbl_count(dropped),
      }, nil)
    end)
  end)
end

--- Timeline ------------------------------------------------------------------

---Where each state begins within a timeline row.
local function state_columns(states)
  local dispatch = states:find("D")
  local execute = states:find("[eE]")
  local retire = states:find("R")
  local first, last
  for i = 1, #states do
    if states:sub(i, i):match("[D=eE%-R]") then
      first = first or i
      last = i
    end
  end
  return { dispatch = dispatch, execute = execute, retire = retire, first = first, last = last }
end

---Parses the timeline table.
---
---Rows are `[iteration, instruction]`. The states field is fixed width,
---starting at column 11, and the width is whatever the ruler spans -- reading
---it from the ruler avoids guessing where the instruction text begins, which
---matters because the field is padded with dots and spaces.
---@return table|nil parsed, string|nil err
function M.parse_timeline(stdout, kept, want_iteration)
  local lines = vim.split(stdout, "\n", { trimempty = false })

  local start
  for i, line in ipairs(lines) do
    if line:find("^Timeline view:") then
      start = i
      break
    end
  end
  if not start then
    return nil, "llvm-mca produced no timeline"
  end

  local width = math.max(#(lines[start + 1] or ""), #(lines[start + 2] or "")) - 10
  if width <= 0 then
    return nil, "could not read the timeline ruler"
  end

  local by_iteration, seen = {}, {}
  for i = start, #lines do
    local iteration, index = lines[i]:match("^%[(%d+),(%d+)%]")
    if iteration then
      iteration, index = tonumber(iteration), tonumber(index)
      by_iteration[iteration] = by_iteration[iteration] or {}
      by_iteration[iteration][index] = lines[i]:sub(11, 10 + width)
      seen[iteration] = true
    end
  end

  local iterations = vim.tbl_keys(seen)
  table.sort(iterations)
  if #iterations == 0 then
    return nil, "llvm-mca produced an empty timeline"
  end

  -- The first iteration runs on a cold pipeline and exaggerates stalls, so
  -- steady state -- the last one simulated -- is the honest default.
  local iteration = want_iteration or iterations[#iterations]
  local states = by_iteration[iteration]
  if not states then
    return nil, "no timeline for iteration " .. tostring(iteration)
  end

  local by_row, ordered = {}, {}
  for index, text in pairs(states) do
    local row = kept[index + 1] -- llvm-mca indexes from zero
    if row then
      local entry = state_columns(text)
      entry.states = text
      entry.row = row
      by_row[row] = entry
      ordered[#ordered + 1] = row
    end
  end
  table.sort(ordered)

  return {
    by_row = by_row,
    ordered = ordered,
    width = width,
    iteration = iteration,
    iterations = iterations,
  }
end

---Timeline for the given rows, in full context.
---
---The analysis always covers every row passed in: narrowing what llvm-mca
---sees would erase the dependencies entering the region, so any narrowing is
---done when rendering, never here.
---@param model table
---@param rows integer[]
---@param opts? { cpu?: string, iterations?: integer, iteration?: integer, key?: string }
---@param cb fun(timeline: table|nil, err: string|nil)
function M.timeline(model, rows, opts, cb)
  opts = opts or {}
  local iterations = opts.iterations or 3

  local key = table.concat({
    "timeline",
    model.artifact or "?",
    opts.key or "?",
    model.arch,
    opts.cpu or "",
    iterations,
  }, "\0")
  if M.cache[key] then
    return cb(M.cache[key], nil)
  end

  invoke(
    model,
    rows,
    {
      "--timeline",
      "--timeline-max-cycles=0",
      "--iterations=" .. iterations,
    },
    opts,
    function(res, err)
      if err then
        return cb(nil, err)
      end

      local parsed, parse_err = M.parse_timeline(res.stdout, res.kept, opts.iteration)
      if not parsed then
        return cb(nil, parse_err)
      end

      parsed.cpu = res.cpu
      parsed.skipped = res.skipped
      M.cache[key] = parsed
      cb(parsed, nil)
    end
  )
end

---Runs llvm-mca over the rendered rows.
---@param model table
---@param rows integer[]
---@param opts? { cpu?: string, key?: string }
---@param cb fun(result: table|nil, err: string|nil)
function M.analyze(model, rows, opts, cb)
  opts = opts or {}

  local target = M.targets[model.arch]
  local key = table.concat({
    "analyze",
    model.artifact or "?",
    opts.key or "?",
    model.arch,
    opts.cpu or (target and target.cpu) or "",
  }, "\0")
  if M.cache[key] then
    return cb(M.cache[key], nil)
  end

  invoke(model, rows, {}, opts, function(res, err)
    if err then
      return cb(nil, err)
    end

    local entries = parse_instruction_info(res.stdout)
    if #entries == 0 then
      local first = res.stderr:match("[^\n]+") or "no output"
      return cb(nil, M.tool .. ": " .. first)
    end

    local per_row, mismatched = {}, 0
    for i, entry in ipairs(entries) do
      local idx = res.kept[i]
      if idx then
        -- Cheap guard against silent misalignment: llvm-mca reprints operands
        -- in its own style, but the mnemonic should still match.
        if mnemonic_of(entry.text) == (model.rows[idx].mnemonic or ""):lower() then
          per_row[idx] = entry
        else
          mismatched = mismatched + 1
        end
      end
    end

    if mismatched > #entries / 2 then
      return cb(nil, "could not line up llvm-mca output with the disassembly")
    end

    local result = {
      per_row = per_row,
      summary = parse_summary(res.stdout),
      cpu = res.cpu,
      arch = model.arch,
      mismatched = mismatched,
      skipped = res.skipped,
    }
    M.cache[key] = result
    cb(result, nil)
  end)
end

---Raw llvm-mca output, for the timeline view.
---@param model table
---@param rows integer[]
---@param opts? { cpu?: string, extra?: string[] }
---@param cb fun(text: string[]|nil, err: string|nil)
function M.report(model, rows, opts, cb)
  opts = opts or {}

  local target = M.targets[model.arch]
  if not target then
    return cb(nil, "no scheduling model for " .. tostring(model.arch))
  end

  local source = M.build_source(model, rows)
  local cmd = {
    M.tool,
    "-mtriple=" .. target.triple,
    "-mcpu=" .. (opts.cpu or target.cpu),
    "-skip-unsupported-instructions=parse-failure",
  }
  vim.list_extend(cmd, opts.extra or {})

  vim.system(cmd, { stdin = source, text = true }, function(res)
    vim.schedule(function()
      if not res.stdout or res.stdout == "" then
        return cb(nil, (res.stderr or "no output"):match("[^\n]+"))
      end
      cb(vim.split(res.stdout, "\n", { trimempty = false }), nil)
    end)
  end)
end

function M.invalidate()
  M.cache = {}
end

return M
