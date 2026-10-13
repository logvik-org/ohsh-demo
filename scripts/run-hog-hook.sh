#!/usr/bin/env bash
# Run Top/demo/pre-creation.tcl the way hog does when it creates the project,
# which writes the .src lists in Top/demo/list from the manifests.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# Vivado runs the hook with PYTHONHOME pointing at its own Python. A directory
# without a Python in it has the same effect on a hook that passes it on.
PYTHONHOME="$REPO/Top" tclsh <<TCL
namespace eval globalSettings {}
set globalSettings::repo_path {$REPO}
source {$REPO/Top/demo/pre-creation.tcl}
TCL
