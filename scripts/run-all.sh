#!/usr/bin/env bash
# Run every check CI runs. Needs ohsh, VUnit, GHDL, NVC and tclsh.
set -euo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
for check in check-manifests sim-ghdl sim-nvc sim-vunit sim-hog; do
  echo "=== $check"
  "$SCRIPTS/$check.sh"
done
