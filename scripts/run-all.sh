#!/usr/bin/env bash
# Run every check CI runs. Needs ohsh, GHDL, NVC and tclsh on PATH.
set -euo pipefail

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
for check in check-manifests check-hog-lists sim-ghdl sim-nvc sim-hog; do
  echo "=== $check"
  "$SCRIPTS/$check.sh"
done
