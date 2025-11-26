return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  opts = {
    open_cmd = "firefox %s --class typst-preview",
    dependencies_bin = {
      ["tinymist"] = "tinymist",
      ["websocat"] = "websocat",
    },
  }, -- lazy.nvim will implicitly calls `setup {}`
}
