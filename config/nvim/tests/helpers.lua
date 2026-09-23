-- Shared assertions and fixture plumbing for the asm/make specs.

local M = {}

M.passed, M.failed = 0, 0
M.failures = {}

-- Absolute: run.sh cd's into this directory, so the source path is relative.
M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
M.fixtures = M.root .. "/fixtures"
M.build = M.fixtures .. "/build"

function M.ok(cond, label, extra)
  if cond then
    M.passed = M.passed + 1
    print("  ok  " .. label)
  else
    M.failed = M.failed + 1
    local msg = "  FAIL " .. label .. (extra and ("\n       " .. tostring(extra)) or "")
    M.failures[#M.failures + 1] = label
    print(msg)
  end
end

function M.eq(got, want, label)
  M.ok(
    vim.inspect(got) == vim.inspect(want),
    label,
    "got  " .. vim.inspect(got) .. "\n       want " .. vim.inspect(want)
  )
end

function M.skip(label, why)
  print("  --  " .. label .. " (skipped: " .. why .. ")")
end

---Runs an async function to completion and returns everything it passed back.
function M.sync(fn, timeout)
  local done, res = false, nil
  fn(function(...)
    res = { ... }
    done = true
  end)
  vim.wait(timeout or 60000, function()
    return done
  end, 10)
  return res or {}
end

function M.ms(fn)
  local t = vim.uv.hrtime()
  fn()
  return (vim.uv.hrtime() - t) / 1e6
end

function M.read_fixture(name)
  return vim.fn.readfile(M.fixtures .. "/" .. name)
end

---Path to a binary produced by fixtures/build.sh, or nil when it is absent.
---Specs that need a real toolchain skip themselves rather than fail.
function M.binary(name)
  local path = M.build .. "/" .. name
  return vim.fn.filereadable(path) == 1 and path or nil
end

---Redirects vim.ui.select to choose `choice` for the next prompt.
function M.pick(choice)
  vim.ui.select = function(items, _, cb)
    for _, item in ipairs(items) do
      if item == choice then
        return cb(item)
      end
    end
    cb(nil)
  end
end

return M
