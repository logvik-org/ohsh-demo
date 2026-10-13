#!/usr/bin/env bash
# Run the GHDL simulation set of the hog project the way a hog user would. hog
# reads the committed list files and does not run pre-creation.tcl for GHDL, so
# run scripts/check-hog-lists.sh first to know the lists are current.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
./Hog/Do SIMULATION demo -simset demo
