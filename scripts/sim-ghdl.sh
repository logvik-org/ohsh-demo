#!/usr/bin/env bash
# Compile the testbench and everything it needs with GHDL, one library at a time
# in the order ohsh writes to libraries.src, then run it.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$REPO/build/ghdl"
rm -rf "$BUILD"
mkdir -p "$BUILD"
GHDL_FLAGS=(--std=08 --workdir="$BUILD" -P"$BUILD" -frelaxed -Wno-hide -Wno-shared)

ohsh -t "$REPO" -w demo -o "$BUILD" tb_top_demo

while IFS= read -r lib; do
  mapfile -t sources < "$BUILD/${lib}_vhdl.src"
  ghdl -a "${GHDL_FLAGS[@]}" --work="$lib" "${sources[@]}"
done < "$BUILD/libraries.src"

ghdl -e "${GHDL_FLAGS[@]}" --work=demo tb_top_demo
(cd "$BUILD" && ghdl -r "${GHDL_FLAGS[@]}" --work=demo tb_top_demo)
