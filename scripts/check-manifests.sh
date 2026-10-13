#!/usr/bin/env bash
# Fail if a manifest, of the design or of a third-party library, lacks a
# dependency its sources use, or lists its sources in an order that does not
# compile.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ohsh --check -t "$REPO"
