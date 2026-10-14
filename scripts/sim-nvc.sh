#!/usr/bin/env bash
# Compile each testbench and everything it needs with NVC, one library at a
# time in the order ohsh writes to libraries.src, then run it.
#
#   scripts/sim-nvc.sh                       # every testbench
#   scripts/sim-nvc.sh tb_top_demo_uvvm      # only these
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/testbenches.sh
source "$REPO/scripts/testbenches.sh"

for tb in "${TESTBENCHES[@]}"; do
  build="$REPO/build/nvc/$tb"
  rm -rf "$build"
  mkdir -p "$build"

  ohsh -t "$REPO" -w demo -o "$build" "$tb"
  while IFS= read -r lib; do
    mapfile -t sources < "$build/${lib}_vhdl.src"
    (cd "$build" && nvc --std=2008 -L. --work="$lib" -a --relaxed "${sources[@]}")
  done < "$build/libraries.src"

  (cd "$build" && nvc --std=2008 -L. --work=demo -e "$tb" -r)
done
