-- lazy.nvim
return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  ft = { "sln", "cs" },
  config = function()
    require("easy-dotnet").setup()
  end,
}
