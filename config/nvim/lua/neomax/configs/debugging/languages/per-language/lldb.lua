local dap = require("dap")

-- local env = {}
--
-- if vim.fn.has("macunix") then
--   env.LLDB_DEBUGSERVER_PATH =
--     "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/Resources/debugserver"
-- end

-- dap.adapters.lldb = {
--   type = "executable",
--   command = vim.fn.exepath("codelldb"),
--   name = "lldb",
-- }

dap.adapters.lldb = {
  type = "executable",
  command = vim.fn.exepath("lldb-dap"),
  name = "lldb",
}

-- dap.adapters.lldb = {
--   type = "server",
--   name = "lldb",
--   port = "${port}",
--   executable = {
--     command = "codelldb",
--     args = {
--       "--port",
--       "${port}",
--     },
--     options = {
--       env = env,
--     },
--   },
-- }
