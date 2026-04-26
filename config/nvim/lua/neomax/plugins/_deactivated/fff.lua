return {
  "dmtrKovalenko/fff.nvim",
  build = "nix run .#release",
  opts = {
    debug = {
      enabled = false,
    },
  },
  lazy = false,
}
