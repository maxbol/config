return {
  "seblyng/roslyn.nvim",
  ft = { "cs", "sln" },
  config = function(opts)
    local lspHooks = require("neomax.configs.lsp-hooks")
    print("on_attach", lspHooks.on_attach)

    vim.lsp.config("roslyn", {
      on_attach = lspHooks.on_attach,
      ["csharp|inlay_hints"] = {
        csharp_enable_inlay_hints_for_implicit_object_creation = true,
        csharp_enable_inlay_hints_for_implicit_variable_types = true,
      },
      ["csharp|code_lens"] = {
        dotnet_enable_references_code_lens = true,
      },
      ["csharp|symbol_search"] = {
        dotnet_search_reference_assemblies = true,
      },
    })

    require("roslyn").setup(opts)
  end,
  opts = {
    -- your configuration comes here; leave empty for default settings
  },
}
