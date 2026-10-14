#!/usr/bin/env bash
# Compile each testbench and everything it needs with GHDL, one library at a
# time in the order ohsh writes to libraries.src, then run it.
#
#   scripts/sim-ghdl.sh                      # every testbench
#   scripts/sim-ghdl.sh tb_top_demo_uvvm     # only these
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/testbenches.sh
source "$REPO/scripts/testbenches.sh"

for tb in "${TESTBENCHES[@]}"; do
  build="$REPO/build/ghdl/$tb"
  rm -rf "$build"
  mkdir -p "$build"
  # UVVM needs the Synopsys packages and relaxed rules. Every library gets
  # the same flags so that they can be used together.
  flags=(--std=08 --workdir="$build" -P"$build" -fsynopsys -frelaxed -Wno-hide -Wno-shared)

  ohsh -t "$REPO" -w demo -o "$build" "$tb"
  while IFS= read -r lib; do
    mapfile -t sources < "$build/${lib}_vhdl.src"
    ghdl -a "${flags[@]}" --work="$lib" "${sources[@]}"
  done < "$build/libraries.src"

  ghdl -e "${flags[@]}" --work=demo "$tb"
  (cd "$build" && ghdl -r "${flags[@]}" --work=demo "$tb")
done
