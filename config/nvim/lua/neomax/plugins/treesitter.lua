--[[ local parser_install_dir = vim.fn.stdpath("cache") .. "/treesitters"
vim.fn.mkdir(parser_install_dir, "p")
vim.opt.runtimepath:append(parser_install_dir) ]]

return {
  "nvim-treesitter/nvim-treesitter",
  commit = "4916d6592ede8c07973490d9322f187e07dfefac",
  lazy = false,
  -- event = { "BufReadPost", "BufNewFile" },
  cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
  build = ":TSUpdate",
  -- opts = {
  --   -- parser_install_dir = parser_install_dir,
  --   incremental_selection = {
  --     enable = true,
  --     keymaps = {
  --       init_selection = "<leader>,",
  --       node_incremental = "g,",
  --       scope_incremental = "grc",
  --       node_decremental = "g.",
  --     },
  --   },
  --   --[[ ensure_installed = {
  -- 	"zig",
  -- 	"typescript",
  -- 	"javascript",
  -- 	"go",
  -- 	"html",
  -- 	"lua",
  -- 	"nix",
  -- 	"markdown",
  -- 	"dockerfile",
  -- 	"c_sharp",
  -- 	"json",
  -- 	"gomod",
  -- 	"gosum",
  -- }, ]]
  --   auto_install = true,
  --   folds = {
  --     enable = false,
  --   },
  --   highlight = {
  --     enable = true,
  --     disable = { "lua" },
  --     -- use_languagetree = false,
  --     additional_vim_regex_highlighting = false,
  --   },
  --   indent = {
  --     enable = false,
  --   },
  --   textobjects = {
  --     select = {
  --       enable = true,
  --
  --       disable = {
  --         "lua",
  --         "odin",
  --         -- "typescript",
  --         -- "zig",
  --       },
  --
  --       -- Automatically jump forward to textobj, similar to targets.vim
  --       lookahead = true,
  --
  --       keymaps = {
  --         -- You can use the capture groups defined in textobjects.scm
  --         ["af"] = "@function.outer",
  --         ["if"] = "@function.inner",
  --         ["ac"] = "@class.outer",
  --         ["i/"] = "@comment.inner",
  --         ["a/"] = "@comment.outer",
  --         ["i;"] = "@statement.inner",
  --         ["a;"] = "@statement.outer",
  --
  --         -- You can optionally set descriptions to the mappings (used in the desc parameter of
  --         -- nvim_buf_set_keymap) which plugins like which-key display
  --         ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
  --         -- You can also use captures from other query groups like `locals.scm`
  --         -- ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
  --       },
  --       -- You can choose the select mode (default is charwise 'v')
  --       --
  --       -- Can also be a function which gets passed a table with the keys
  --       -- * query_string: eg '@function.inner'
  --       -- * method: eg 'v' or 'o'
  --       -- and should return the mode ('v', 'V', or '<c-v>') or a table
  --       -- mapping query_strings to modes.
  --       selection_modes = {
  --         ["@parameter.outer"] = "v", -- charwise
  --         ["@function.outer"] = "v", -- linewise
  --         ["@class.outer"] = "V", -- linewise
  --       },
  --       -- If you set this to `true` (default is `false`) then any textobject is
  --       -- extended to include preceding or succeeding whitespace. Succeeding
  --       -- whitespace has priority in order to act similarly to eg the built-in
  --       -- `ap`.
  --       --
  --       -- Can also be a function which gets passed a table with the keys
  --       -- * query_string: eg '@function.inner'
  --       -- * selection_mode: eg 'v'
  --       -- and should return true or false
  --       include_surrounding_whitespace = true,
  --     },
  --     swap = {
  --       enable = true,
  --
  --       swap_next = {
  --         ["<leader>a"] = "@parameter.inner",
  --       },
  --       swap_previous = {
  --         ["<leader>A"] = "@parameter.inner",
  --       },
  --     },
  --     move = {
  --       enable = true,
  --       disable = { "lua" },
  --
  --       goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
  --       goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
  --       goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
  --       goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
  --     },
  --   },
  -- },
  dependencies = {
    -- {
    --   "nvim-treesitter/nvim-treesitter-context",
    --   config = function()
    --     require("treesitter-context").setup({
    --       enable = false, -- Enable this plugin (Can be enabled/disabled later via commands)
    --       max_lines = 6, -- How many lines the window should span. Values <= 0 mean no limit.
    --       min_window_height = 35, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    --       line_numbers = true,
    --       multiline_threshold = 20, -- Maximum number of lines to show for a single context
    --       trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    --       mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
    --       -- Separator between context and content. Should be a single character string, like '-'.
    --       -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    --       separator = nil,
    --       zindex = 20, -- The Z-index of the context window
    --       on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    --     })
    --   end,
    -- },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
      config = function()
        require("nvim-treesitter-textobjects").setup({
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v", -- charwise
            ["@function.outer"] = "v", -- linewise
            ["@class.outer"] = "V", -- linewise
          },
          include_surrounding_whitespace = true,
          set_jumps = true,
        })

        --         ["af"] = "@function.outer",
        --         ["if"] = "@function.inner",
        --         ["ac"] = "@class.outer",
        --         ["i/"] = "@comment.inner",
        --         ["a/"] = "@comment.outer",
        --         ["i;"] = "@statement.inner",
        --         ["a;"] = "@statement.outer",
        --
        --         -- You can optionally set descriptions to the mappings (used in the desc parameter of
        --         -- nvim_buf_set_keymap) which plugins like which-key display
        --         ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },

        vim.keymap.set({ "x", "o" }, "af", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "if", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@function.inner", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "ac", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@class.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "ic", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@class.inner", "textobjects")
        end)
        -- You can also use captures from other query groups like `locals.scm`
        vim.keymap.set({ "x", "o" }, "as", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
        end)

        vim.keymap.set({ "x", "o" }, "a/", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@comment.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "i/", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@comment.inner", "textobjects")
        end)

        vim.keymap.set({ "x", "o" }, "a;", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@statement.outer", "textobjects")
        end)
        vim.keymap.set({ "x", "o" }, "i;", function()
          require("nvim-treesitter-textobjects.select").select_textobject("@statement.inner", "textobjects")
        end)

        -- keymaps
        vim.keymap.set("n", "<leader>a", function()
          require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
        end)
        vim.keymap.set("n", "<leader>A", function()
          require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.outer")
        end)

        -- keymaps
        -- You can use the capture groups defined in `textobjects.scm`
        vim.keymap.set({ "n", "x", "o" }, "]f", function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "n", "x", "o" }, "]c", function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
        end)
        -- You can also pass a list to group multiple queries.
        vim.keymap.set({ "n", "x", "o" }, "]o", function()
          require("nvim-treesitter-textobjects.move").goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
        end)
        -- You can also use captures from other query groups like `locals.scm` or `folds.scm`
        vim.keymap.set({ "n", "x", "o" }, "]s", function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@local.scope", "locals")
        end)
        vim.keymap.set({ "n", "x", "o" }, "]z", function()
          require("nvim-treesitter-textobjects.move").goto_next_start("@fold", "folds")
        end)

        vim.keymap.set({ "n", "x", "o" }, "]F", function()
          require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "n", "x", "o" }, "]C", function()
          require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
        end)

        vim.keymap.set({ "n", "x", "o" }, "[f", function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "n", "x", "o" }, "[c", function()
          require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
        end)

        vim.keymap.set({ "n", "x", "o" }, "[F", function()
          require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
        end)
        vim.keymap.set({ "n", "x", "o" }, "[C", function()
          require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
        end)

        -- Go to either the start or the end, whichever is closer.
        -- Use if you want more granular movements
        vim.keymap.set({ "n", "x", "o" }, "]d", function()
          require("nvim-treesitter-textobjects.move").goto_next("@conditional.outer", "textobjects")
        end)
        vim.keymap.set({ "n", "x", "o" }, "[d", function()
          require("nvim-treesitter-textobjects.move").goto_previous("@conditional.outer", "textobjects")
        end)

        -- When in diff mode, we want to use the default
        -- vim text objects c & C instead of the treesitter ones.
        -- local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
        -- local configs = require("nvim-treesitter.configs")
        -- for name, fn in pairs(move) do
        --   if name:find("goto") == 1 then
        --     move[name] = function(q, ...)
        --       if vim.wo.diff then
        --         local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
        --         for key, query in pairs(config or {}) do
        --           if q == query and key:find("[%]%[][cC]") then
        --             vim.cmd("normal! " .. key)
        --             return
        --           end
        --         end
        --       end
        --       return fn(q, ...)
        --     end
        --   end
        -- end
      end,
    },
  },
  config = function(_, opts)
    local installed = require("nvim-treesitter").get_installed()

    vim.api.nvim_create_autocmd("FileType", {
      pattern = installed,
      callback = function()
        vim.treesitter.start()
      end,
    })
  end,
  -- config = function(_, opts)
  --   require("nvim-treesitter.configs").setup(opts)
  --
  --   local augroup = vim.api.nvim_create_augroup("ts_indent_filetypes", { clear = true })
  --   vim.api.nvim_create_autocmd("FileType", {
  --     group = augroup,
  --     pattern = { "html", "templ", "vento" },
  --     callback = function()
  --       vim.bo.indentexpr = "nvim_treesitter#indent()"
  --     end,
  --   })
  -- end,
}
