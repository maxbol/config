#!/usr/bin/env bash
# Builds the sample binaries the integration specs disassemble.
# Specs that need these skip themselves when the binaries are absent, so this
# is only required for the toolchain-dependent half of the suite.
set -uo pipefail
cd "$(dirname "$0")"
mkdir -p build
rc=0

if command -v gcc >/dev/null; then
  gcc -O2 -g -o build/demo src/c/demo.c && echo "built build/demo (C)" || rc=1
else
  echo "skip: gcc not found"
fi

if command -v zig >/dev/null; then
  (cd src/zig && zig build-exe main.zig -O ReleaseFast -femit-bin=../../build/demo-zig >/dev/null 2>&1) \
    && echo "built build/demo-zig (Zig)" || echo "skip: zig build failed"
  # Cross-compiled targets prove the pipeline is not x86-specific. Zig ships
  # its own cross toolchain, so these need nothing else installed.
  for target in aarch64-linux riscv64-linux; do
    (cd src/zig && zig build-exe main.zig -target "$target" -O ReleaseFast \
      -femit-bin="../../build/demo-$target" >/dev/null 2>&1) \
      && echo "built build/demo-$target (Zig, cross)" \
      || echo "skip: zig cross build for $target failed"
  done
  rm -f src/zig/*.o build/*.o
else
  echo "skip: zig not found"
fi

if command -v dune >/dev/null; then
  # A multi-directory dune project: this is what makes dune record
  # /workspace_root paths, which path resolution has to see through.
  (cd src/ocaml && dune build >/dev/null 2>&1) \
    && cp src/ocaml/_build/default/bin/main.exe build/demo-ocaml.exe \
    && echo "built build/demo-ocaml.exe (OCaml)" \
    || echo "skip: dune build failed"
else
  echo "skip: dune not found"
fi

if command -v go >/dev/null; then
  (cd src/go && go build -gcflags='all=-N -l' -o ../../build/demo-go . >/dev/null 2>&1) \
    && echo "built build/demo-go (Go)" || echo "skip: go build failed"
else
  echo "skip: go not found"
fi

exit $rc
