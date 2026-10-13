#!/usr/bin/env bash
# Compile the testbench and everything it needs with NVC, one library at a time
# in the order ohsh writes to libraries.src, then run it.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$REPO/build/nvc"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

ohsh -t "$REPO" -w demo -o "$BUILD" tb_top_demo

while IFS= read -r lib; do
  mapfile -t sources < "$BUILD/${lib}_vhdl.src"
  nvc --std=2008 -L. --work="$lib" -a --relaxed "${sources[@]}"
done < "$BUILD/libraries.src"

nvc --std=2008 -L. --work=demo -e tb_top_demo -r
