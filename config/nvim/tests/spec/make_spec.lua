-- make.lua command/artifact storage: list-valued defaults, remembered picks.

local H = require("helpers")

vim.g.makefile_root = vim.fn.tempname() .. "/make"
local make = require("neomax.configs.make")

local cwd = "/tmp/neomax-make-spec"
local defs = {
  make = { "zig build", "zig build -Doptimize=ReleaseFast", "zig build -Doptimize=ReleaseSmall" },
}

-- no picks yet: the configured list, in order
local c = make.getLastCmds(defs, cwd)
H.eq(c.make.display, defs.make, "configured defaults come through in order")
H.eq(c.make.display[1], "zig build", "the first entry is the default")
H.eq(c.make.picks, {}, "nothing persisted yet")
H.eq(make.getLastCmds({ run = "zig build run" }, cwd).run.display, { "zig build run" }, "a string default still works")

-- a pick leads, and the unpicked defaults stay reachable
make.storeCmds("make", make.insertCmdInList({}, "zig build -Dcpu=native"), cwd)
H.eq(make.getLastCmds(defs, cwd).make.display, {
  "zig build -Dcpu=native",
  "zig build",
  "zig build -Doptimize=ReleaseFast",
  "zig build -Doptimize=ReleaseSmall",
}, "the pick leads, then the remaining defaults")

-- picking something already in the defaults moves it rather than duplicating
make.storeCmds("make", make.insertCmdInList({ "zig build -Dcpu=native" }, "zig build -Doptimize=ReleaseSmall"), cwd)
H.eq(make.getLastCmds(defs, cwd).make.display, {
  "zig build -Doptimize=ReleaseSmall",
  "zig build -Dcpu=native",
  "zig build",
  "zig build -Doptimize=ReleaseFast",
}, "a picked default moves to the front without duplicating")

-- only picks are persisted, so editing a language config takes effect at once
H.eq(
  vim.fn.readfile(make.getProjectFiles(cwd).make),
  { "zig build -Doptimize=ReleaseSmall", "zig build -Dcpu=native" },
  "only picks reach disk"
)
H.eq(make.getLastCmds({ make = { "zig build" } }, cwd).make.display, {
  "zig build -Doptimize=ReleaseSmall",
  "zig build -Dcpu=native",
  "zig build",
}, "defaults removed from the config disappear from the selector")

-- modes are independent
H.eq(make.getLastCmds(defs, cwd).lint.display, {}, "an unset mode is empty")
H.eq(
  make.getLastCmds({ asm = { "zig build -Doptimize=ReleaseFast" } }, cwd).asm.display,
  { "zig build -Doptimize=ReleaseFast" },
  "asm is a mode like any other"
)

-- === artifacts ===
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
vim.fn.writefile({ "#!/bin/sh" }, dir .. "/prog")
vim.fn.writefile({ "data" }, dir .. "/notexec")
vim.fn.setfperm(dir .. "/prog", "rwxr-xr-x")

H.eq(make.expandArtifacts(nil, dir), {}, "no spec yields nothing")
H.eq(make.expandArtifacts("nosuch/*", dir), {}, "a glob matching nothing yields nothing")
H.eq(make.expandArtifacts("notexec", dir), {}, "non-executables are skipped")
H.eq(make.expandArtifacts("prog", dir), { dir .. "/prog" }, "an executable is found")
H.eq(make.expandArtifacts({ "prog", "nosuch" }, dir), { dir .. "/prog" }, "a list of globs")
H.eq(
  make.expandArtifacts(function()
    return { "prog" }
  end, dir),
  { dir .. "/prog" },
  "a function spec"
)

-- artifacts that no longer exist are dropped rather than offered forever
make.storeCmds("artifact", { dir .. "/gone", dir .. "/prog" }, cwd)
H.eq(make.getLastCmds({}, cwd).artifact.picks, { dir .. "/prog" }, "vanished artifacts are dropped from picks")
