# nvim config tests

Specs for `lua/neomax/configs/make.lua` and `lua/neomax/configs/asm/`.

```sh
config/nvim/tests/run.sh              # everything
config/nvim/tests/run.sh model        # specs whose name matches "model"
```

Exit status is non-zero if anything fails, so it drops straight into CI or a
git hook.

## Two kinds of spec

**Pure specs** — `model_spec`, `lines_spec`, `make_spec` — run against dumps
committed under `fixtures/` and need no toolchain. These are the regression
guard that matters: they pin down how `llvm-objdump` and `llvm-dwarfdump`
output is parsed, which is where breakage will come from when a compiler
changes its formatting.

**Integration specs** — `disasm_spec`, `view_spec`, `decorate_spec`,
`integration_spec` — drive
real binaries, so they need the sample programs built first:

```sh
config/nvim/tests/fixtures/build.sh   # needs gcc; zig and go are optional
```

Without that they skip themselves rather than fail, so `run.sh` stays green on
a machine with no compilers.

## Fixtures

| file | what it pins down |
| --- | --- |
| `objdump-c.txt` | gcc `-O2 -g`: inlining across functions *and* files, non-monotonic line mapping, symbols with no debug info |
| `dwarfdump-c.txt` | DWARF 5 line table: `include_directories` / `file_names` joining, `end_sequence` rows |
| `objdump-zig-generics.txt` | Zig generic instantiations — symbol names containing commas, spaces and parens |

Regenerate them with:

```sh
llvm-objdump -d --line-numbers --symbolize-operands --no-show-raw-insn build/demo > fixtures/objdump-c.txt
llvm-dwarfdump --debug-line build/demo > fixtures/dwarfdump-c.txt
```

The absolute paths baked into the dumps are the build machine's; specs match
on basenames, so they do not need regenerating when the path changes.
