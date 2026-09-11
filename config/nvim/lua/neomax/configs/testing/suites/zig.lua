return {
  adapter = function()
    return require("neotest-zig")({
      dap = {
        adapter = "lldb",
      },
      path_to_zig = "zig",
    })
  end,
}
