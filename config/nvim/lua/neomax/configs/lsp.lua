local lspconfig = require("lspconfig")
local hooks = require("neomax.configs.lsp-hooks")

local on_attach = hooks.on_attach
local on_init = hooks.on_init

-- Add borders to floating windows
local lsp_float_border = {
  { "🭽", "FloatBorder" },
  { "▔", "FloatBorder" },
  { "🭾", "FloatBorder" },
  { "▕", "FloatBorder" },
  { "🭿", "FloatBorder" },
  { "▁", "FloatBorder" },
  { "🭼", "FloatBorder" },
  { "▏", "FloatBorder" },
}
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or lsp_float_border
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

local capabilities = require("blink.cmp").get_lsp_capabilities()
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
--
-- capabilities = vim.tbl_extend(
-- 	"keep",
-- 	capabilities or {},
-- 	require("blink.cmp").get_lsp_capabilities({
-- 		textDocument = { completion = { completionItem = { snippetSupport = true } } },
-- 	})
-- )

-- capabilities = vim.tbl_extend("keep", capabilities or {}, lsp_status.capabilities)

capabilities.textDocument.completion.completionItem = {
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
}

capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

-- if you just want default config for the servers then put them in a table
local servers = {
  "cssls",
  -- "clangd",
  "buf_ls",
  -- "tsserver",
  "eslint",
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
  "denols",
  "ols",
  "vala_ls",
  "mesonlsp",
  "nushell",
}

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    on_init = on_init,
    on_attach = on_attach,
    capabilities = capabilities,
  })
end

-- lspconfig.ols.setup({
-- 	on_init = on_init,
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- 	init_options = {
-- 		enable_format = true,
-- 		enable_hover = true,
-- 		enable_snippets = true,
-- 		enable_semantic_tokens = true,
-- 		enable_document_symbols = true,
-- 		enable_fake_methods = true,
-- 		enable_procedure_snippet = true,
-- 		enable_checker_only_saved = false,
-- 		enable_references = true,
-- 		enable_rename = true,
-- 	},
-- })

lspconfig.lua_ls.setup({
  on_init = on_init,
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
  root_dir = function(fname)
    local project_file_root = require("lspconfig.util").root_pattern("stylua.toml")(fname)
    if project_file_root ~= nil then
      return project_file_root
    end
    return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
  end,
})

local clangd_path = "clangd"

lspconfig.clangd.setup({
  on_init = on_init,
  on_attach = on_attach,
  capabilities = vim.tbl_extend("keep", capabilities, {
    offsetEncoding = { "utf-16" },
  }),
  root_dir = function(fname)
    return require("lspconfig.util").root_pattern(
      "Makefile",
      "configure.ac",
      "configure.in",
      "config.h.in",
      "meson.build",
      "meson_options.txt",
      "build.ninja"
    )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(fname) or require(
      "lspconfig.util"
    ).find_git_ancestor(fname)
  end,
  cmd = {
    clangd_path,
    -- "clangd",
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
})

-- lspconfig.omnisharp.setup({
--   on_init = on_init,
--   on_attach = on_attach,
--   capabilities = capabilities,
--   cmd = { "/home/max/.nix-profile/bin/OmniSharp" },
--   settings = {
--     FormattingOptions = {
--       OrganizeImports = true,
--     },
--     RoslynExtensionsOptions = {
--       EnableAnalyzersSupport = true,
--       EnableImportCompletion = true,
--     },
--   },
-- })
--
local sourcekit_capabilities = vim.tbl_extend("keep", capabilities or {}, {
  workspace = {
    didChangeWatchedFiles = {
      dynamicRegistration = true,
    },
  },
})

lspconfig.sourcekit.setup({
  on_init = on_init,
  on_attach = on_attach,
  capabilities = sourcekit_capabilities,
  filetypes = { "swift" },
})

lspconfig["html"].setup({
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "html", "vento", "templ" },
  init_options = {
    provideFormatter = false,
  },
})

lspconfig["denols"].setup({
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
  settings = {
    deno = {
      enable = true,
      suggest = {
        imports = {
          hosts = {
            ["https://deno.land"] = true,
          },
        },
      },
    },
  },
})

lspconfig.eslint.setup({
  on_init = on_init,
  on_attach = on_attach,
  capabilites = capabilities,
  single_file_support = false,
  root_dir = lspconfig.util.root_pattern(".eslintrc.js", "eslint.config.mjs", ".eslintrc"),
})

lspconfig["ts_ls"].setup({
  root_dir = lspconfig.util.root_pattern("package.json"),
  on_init = on_init,
  on_attach = on_attach,
  single_file_support = false,
  capabilities = capabilities,
  -- settings = {
  -- 	typescript = {
  -- 		inlayHints = {
  -- 			includeInlayParameterNameHints = "literal",
  -- 			includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  -- 			includeInlayFunctionParameterTypeHints = false,
  -- 			includeInlayVariableTypeHints = false,
  -- 			includeInlayPropertyDeclarationTypeHints = false,
  -- 			includeInlayFunctionLikeReturnTypeHints = true,
  -- 			includeInlayEnumMemberValueHints = true,
  -- 		},
  -- 	},
  -- 	javascript = {
  -- 		inlayHints = {
  -- 			includeInlayParameterNameHints = "all",
  -- 			includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  -- 			includeInlayFunctionParameterTypeHints = true,
  -- 			includeInlayVariableTypeHints = true,
  -- 			includeInlayPropertyDeclarationTypeHints = true,
  -- 			includeInlayFunctionLikeReturnTypeHints = true,
  -- 			includeInlayEnumMemberValueHints = true,
  -- 		},
  -- 	},
  -- },
})

-- vim.api.nvim_create_autocmd("LspAttach", {
-- 	callback = function(args)
-- 		local bufnr = args.buf
-- 		local client = vim.lsp.get_client_by_id(args.data.client_id)
-- 		if vim.tbl_contains({ "null-ls" }, client.name) then -- blacklist lsp
-- 			return
-- 		end
-- 		require("lsp_signature").on_attach({
-- 			bind = true,
-- 			handler_opts = {
-- 				border = "rounded",
-- 			},
-- 		}, bufnr)
-- 	end,
-- })

vim.lsp.set_log_level("ERROR")
require("ufo").setup()
