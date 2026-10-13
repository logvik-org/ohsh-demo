#!/usr/bin/env bash
# Fail if a manifest of the design lacks a dependency its sources use, or lists
# its sources in an order that does not compile.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ohsh --check -t "$REPO" tb_top_demo
