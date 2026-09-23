#!/usr/bin/env bash
# Runs the nvim config test suite. Optional argument filters specs by name.
set -euo pipefail
cd "$(dirname "$0")"
exec nvim --headless -l run.lua "$@"
