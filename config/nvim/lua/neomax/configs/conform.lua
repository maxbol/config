local utils = require("neomax.utils")

local jsfmt = function(bufnr)
  local biomeProject = utils.find_project_cwd({ "biome.json" }, vim.fn.getcwd(), vim.api.nvim_buf_get_name(bufnr))
  if biomeProject ~= nil then
    return { "biome" }
  end
  return { "prettierd" }
end

local options = {
  formatters_by_ft = {
    nix = { "alejandra" },

    lua = { "stylua" },

    typescriptreact = jsfmt,
    javascriptreact = jsfmt,
    typescript = jsfmt,
    javascript = jsfmt,
    css = jsfmt,
    graphql = jsfmt,
    html = { "prettier_html" },
    vento = { "prettier_html" },
    templ = { "prettier_html" },

    json = { "fixjson" },

    sh = { "shfmt" },

    go = {
      "gofmt",
      "goimports",
    },

    ocaml = {
      "ocamlformat",
    },

    -- cs = {
    --   "csharpier",
    -- },

    -- sql = {
    -- 	"sqlfluff",
    -- },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  formatters = {
    prettier_html = {
      command = "prettier",
      args = {
        "--parser",
        "html",
      },
    },
    csharpier = {
      command = "dotnet-csharpier",
      args = {
        "--write-stdout",
      },
    },
    sqlfluff = {
      command = "sqlfluff",
      args = {
        "fix",
        "--disable-progress-bar",
        "-f",
        "-n",
        "-",
      },
      stdin = true,
    },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

require("conform").setup(options)
