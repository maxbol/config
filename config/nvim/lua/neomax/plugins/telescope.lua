return {
  {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    config = function()
      require("telescope").setup({
        pickers = {
          -- Hard set all cwd for telescope pickers to getcwd(-1) to
          -- avoid lcd taint from oil buffers
          oldfiles = {
            cwd_only = true,
            cwd = vim.fn.getcwd(-1),
          },
          find_files = {
            cwd = vim.fn.getcwd(-1),
          },
          live_grep = {
            cwd = vim.fn.getcwd(-1),
          },
          colorscheme = {
            enable_preview = true,
          },
        },
        extensions = {
          opener = {
            hidden = false, -- do not show hidden directories
            root_dir = "~/Source", -- search from home directory by default
            respect_gitignore = true, -- respect .gitignore files
          },
          dap = {
            theme = require("telescope.themes").get_ivy(),
          },
          recent_files = {
            only_cwd = true,
          },
        },
      })
    end,
  },
  {
    "jvgrootveld/telescope-zoxide",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/popup.nvim",
      "nvim-lua/plenary.nvim",
    },
    lazy = false,
  },
  {
    "nvim-telescope/telescope-dap.nvim",
    config = function()
      require("telescope").load_extension("dap")
    end,
    -- lazy = false,
  },
}
