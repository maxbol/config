return {
  -- "maxbol/treesorter.nvim",
  dir = "~/src/treesorter.nvim/",
  cmd = "TSort",
  config = function()
    require("treesorter").setup()
  end,
}
