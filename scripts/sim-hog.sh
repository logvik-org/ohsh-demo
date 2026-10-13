#!/usr/bin/env bash
# Run the GHDL simulation set of the hog project the way a hog user would. hog
# does not run pre-creation.tcl for a GHDL simulation, so run it here first to
# write the list files hog reads.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
"$REPO/scripts/run-hog-hook.sh"
cd "$REPO"
./Hog/Do SIMULATION demo -simset demo
