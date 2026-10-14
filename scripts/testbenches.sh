# shellcheck shell=bash
# Sourced by the simulation scripts: the testbenches named on their command
# line, or all of the ones that run without a test framework of their own.
# VUnit's testbench has its own runner, scripts/sim-vunit.sh.
TESTBENCHES=("$@")
if [ ${#TESTBENCHES[@]} -eq 0 ]; then
  TESTBENCHES=(tb_top_demo tb_top_demo_uvvm tb_top_demo_osvvm)
fi
