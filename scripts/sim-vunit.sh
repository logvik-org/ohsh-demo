#!/usr/bin/env bash
# Run the VUnit testbench with GHDL and with NVC.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
for simulator in ghdl nvc; do
  VUNIT_SIMULATOR="$simulator" python "$REPO/tb/tb_top_demo_vunit/run.py" \
    --output-path "$REPO/build/vunit/$simulator"
done
