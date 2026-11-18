#!/usr/bin/env bash
#
# scripts/install.sh - install shae-haskell-expression-evaluator
#
# Installs GHC (Glasgow Haskell Compiler), builds the evaluator from
# src/Eval.hs, and installs the `eval` binary.
#
# Usage:
#   ./scripts/install.sh              # system-wide (sudo)
#   PREFIX=~/.local/bin ./scripts/install.sh
#
set -euo pipefail

PROJECT="shae-haskell-expression-evaluator"
BIN="eval"
PREFIX="${PREFIX:-/usr/local/bin}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# 1. Ensure GHC is available
# -----------------------------------------------------------------------------
if ! have_cmd ghc; then
  echo "[install] ghc not found; attempting to install via apt (Debian/Ubuntu)"
  if have_cmd apt-get; then
    sudo apt-get update -y
    sudo apt-get install -y ghc
  elif have_cmd apk; then
    sudo apk add ghc
  else
    echo "[install] error: no supported package manager found" >&2
    echo "[install] install GHC manually (https://www.haskell.org/ghc/) or via ghcup" >&2
    echo "[install]   https://www.haskell.org/ghcup/" >&2
    exit 1
  fi
fi

have_cmd ghc || { echo "[install] error: ghc still unavailable" >&2; exit 1; }
echo "[install] ghc: $(ghc --numeric-version)"

# -----------------------------------------------------------------------------
# 2. Build
# -----------------------------------------------------------------------------
echo "[install] building $(PROJECT)"
make -C "$ROOT_DIR" build

# -----------------------------------------------------------------------------
# 3. Install binary
# -----------------------------------------------------------------------------
echo "[install] installing $(BIN) to $(PREFIX)"
install -d "$PREFIX"
install -m 0755 "$ROOT_DIR/$BIN" "$PREFIX/$(PROJECT)"
echo "[install] done: $(PREFIX)/$(PROJECT)"
echo "[install] usage: $(PREFIX)/$(PROJECT) '1 + 2'"
