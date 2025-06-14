return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  -- optional: provides snippets for the snippet source
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      version = "v2.*",
      dependencies = {
        "rafamadriz/friendly-snippets",
      },
      config = function()
        require("luasnip").setup({
          enable_autosnippets = true,
        })
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip").add_snippets("all", {
          require("neomax.configs.snippets.todo"),
        })

        -- Important! This removes the SUPER annoying behavior that for whatever reason is on
        -- by default that leaves the snippet session hanging around when exiting insert mode. NO IDEA
        -- why this is how it works by default, or why there is no settings to disable this
        -- behavior, since it seems OBVIOUSLY bad and broken.
        -- https://github.com/L3MON4D3/LuaSnip/issues/258
        -- vim.api.nvim_create_autocmd("ModeChanged", {
        --   pattern = "*",
        --   callback = function()
        --     if
        --       ((vim.v.event.old_mode == "s" and vim.v.event.new_mode == "n") or vim.v.event.old_mode == "i")
        --       and require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
        --       and not require("luasnip").session.jump_active
        --     then
        --       require("luasnip").unlink_current()
        --     end
        --   end,
        -- })
      end,
    },
    "windwp/nvim-autopairs",
    "folke/lazydev.nvim",
  },

  -- use a release tag to download pre-built binaries
  version = "1.*",
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  opts = {
    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    keymap = {
      -- preset = "default",
      preset = "none",
      ["<Right>"] = { "accept", "snippet_forward", "fallback" },
      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      ["<C-l>"] = { "snippet_forward", "accept", "fallback" },
      ["<C-h>"] = { "snippet_backward", "accept", "fallback" },
      ["<C-k>"] = { "select_prev", "fallback" },
      ["<C-j>"] = { "select_next", "fallback" },
      -- ["<Tab>"] = { "snippet_forward", "fallback" },
      -- ["<S-Tab>"] = { "snippet_backward", "fallback" },
    },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      documentation = { auto_show = false, auto_show_delay_ms = 100 },
      accept = {
        auto_brackets = {
          enabled = false,
          -- kind_resolution = {
          -- 	enabled = true,
          -- },
          -- default_brackets = { "(", ")", "{", "}", "[", "]" },
          -- semantic_token_resolution = {
          -- 	enabled = true,
          -- },
        },
      },
      ghost_text = {
        enabled = true,
      },
    },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    --
    snippets = {
      preset = "luasnip",
    },

    sources = {
      default = {
        "lsp",
        "path",
        "snippets",
        "buffer",
      },
      providers = {
        buffer = {
          score_offset = -10,
        },
        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          -- make lazydev completions top priority (see `:h blink.cmp`)
          score_offset = 100,
        },
      },
    },

    signature = {
      enabled = true,
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
