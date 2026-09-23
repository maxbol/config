-- Test runner. See tests/README.md.
--
--   nvim --headless -l config/nvim/tests/run.lua           -- everything
--   nvim --headless -l config/nvim/tests/run.lua model     -- matching specs

local here = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
vim.opt.runtimepath:prepend(vim.fn.fnamemodify(here, ":h"))
package.path = here .. "/?.lua;" .. package.path

local H = require("helpers")
local filter = vim.v.argv[#vim.v.argv]
if filter == "run.lua" or filter:match("/run%.lua$") then
  filter = nil
end

local specs = vim.fn.glob(here .. "/spec/*_spec.lua", false, true)
table.sort(specs)

local ran = 0
for _, spec in ipairs(specs) do
  local name = vim.fn.fnamemodify(spec, ":t:r")
  if not filter or name:find(filter, 1, true) then
    ran = ran + 1
    print("\n" .. name)
    local ok, err = pcall(dofile, spec)
    if not ok then
      H.failed = H.failed + 1
      H.failures[#H.failures + 1] = name .. " (crashed)"
      print("  FAIL " .. name .. " crashed\n       " .. tostring(err))
    end
  end
end

print(("\n%d specs, %d passed, %d failed"):format(ran, H.passed, H.failed))
if H.failed > 0 then
  for _, f in ipairs(H.failures) do
    print("  - " .. f)
  end
  vim.cmd("cq")
end
vim.cmd("qa!")
