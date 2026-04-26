-- local utils = require("neomax.configs.debugging.languages.utils")

require("dap-go").setup({
  delve = {
    build_flags = "",
    -- cwd = function()
    --   return utils.getCwd({ "go.mod", "go.sum", ".git" })
    -- end,
  },
})
