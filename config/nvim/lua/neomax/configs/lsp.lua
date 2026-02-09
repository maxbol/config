local hooks = require("neomax.configs.lsp-hooks")

local capabilities = {
  textDocument = {
    completion = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
      completionItem = {
        documentationFormat = { "markdown", "plaintext" },
        snippetSupport = true,
        preselectSupport = true,
        insertReplaceSupport = true,
        labelDetailsSupport = true,
        deprecatedSupport = true,
        commitCharactersSupport = true,
        tagSupport = { valueSet = { 1 } },
        resolveSupport = {
          properties = {
            "documentation",
            "detail",
            "additionalTextEdits",
          },
        },
      },
    },
  },
}

-- if you just want default config for the servers then put them in a table
local servers = {
  "cssls",
  "buf_ls",
  "vtsls",
  "nixd",
  "gopls",
  "golangci_lint_ls",
  "zls",
  "dockerls",
  "docker_compose_language_service",
  "pyright",
  "gleam",
  "rust_analyzer",
  "glsl_analyzer",
  "ocamllsp",
  "ols",
  "vala_ls",
  "mesonlsp",
  "nushell",
  "tinymist",
  {
    "lua_ls",
    {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    },
  },
  {
    "clangd",
    {
      cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--header-insertion=iwyu",
        "--completion-style=detailed",
        "--function-arg-placeholders",
        "--fallback-style=llvm",
      },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
        clangdFileStatus = true,
      },
    },
  },
  {
    "sourcekit",
    {
      capabilities = {
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        },
      },
      filetypes = { "swift" },
    },
  },
  {
    "html",
    {
      filetypes = { "html", "vento", "templ" },
      init_options = {
        provideFormatter = false,
      },
    },
  },
  {
    "eslint",
    {
      on_attach = function(_, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          command = "LspEslintFixAll",
        })
      end,
      single_file_support = false,
    },
  },
}

hooks.config_servers(servers, capabilities)

require("ufo").setup()
