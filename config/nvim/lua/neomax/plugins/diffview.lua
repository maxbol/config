return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewFileHistory", "DiffviewOpen" },
  config = function()
    local diffview = require("diffview")
    local config = require("diffview.config")
    diffview.setup({
      enhanced_diff_hl = true,
      keymaps = {
        view = {
          -- ["-"] = require("diffview.config").actions.toggle_stage_entry,
          ["-"] = function()
            config.actions.toggle_stage_entry()
          end,
          -- { "n", "-", require("diffview").actions.toggle_stage_entry, { desc = "toggle stage buffer" } },
        },
      },
      view = {
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
          winbar_info = true,
        },
        default = {
          layout = "diff2_horizontal",
          disable_diagnostics = true,
          winbar_info = true,
        },
        file_history = {
          layout = "diff2_horizontal",
          disable_diagnostics = false,
          winbar_info = false,
        },
      },
    })
  end,
}
