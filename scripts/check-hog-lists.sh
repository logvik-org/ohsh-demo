#!/usr/bin/env bash
# Run Top/demo/pre-creation.tcl the way hog does when it creates the project,
# then fail if the list files it wrote differ from the committed ones.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LIST_DIR=Top/demo/list
cd "$REPO"

# Vivado runs the hook with PYTHONHOME pointing at its own Python. A directory
# without a Python in it has the same effect on a hook that passes it on.
PYTHONHOME="$REPO/Top" tclsh <<TCL
namespace eval globalSettings {}
set globalSettings::repo_path {$REPO}
source {$REPO/Top/demo/pre-creation.tcl}
TCL

if [ -n "$(git status --porcelain "$LIST_DIR")" ]; then
  git status --short "$LIST_DIR"
  echo "hog list files are out of date: run Top/demo/pre-creation.tcl or" >&2
  echo "scripts/check-hog-lists.sh and commit the result" >&2
  exit 1
fi
echo "hog list files match the manifests"
