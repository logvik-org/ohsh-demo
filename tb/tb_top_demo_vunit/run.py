#!/usr/bin/env python3
"""Run tb_top_demo_vunit with VUnit, on the libraries and sources ohsh resolves.

VUnit works out the compile order from the files itself, so libraries.src only
says which libraries to create. Pick the simulator with VUNIT_SIMULATOR, for
example VUNIT_SIMULATOR=nvc.
"""

import subprocess
from pathlib import Path

from vunit import VUnit

REPO = Path(__file__).resolve().parents[2]
LISTS = REPO / "build" / "vunit" / "lists"


def read_lines(path: Path) -> list[str]:
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


subprocess.run(
    ["ohsh", "-t", str(REPO), "-w", "demo", "-o", str(LISTS), "tb_top_demo_vunit"],
    check=True,
)

vu = VUnit.from_argv(compile_builtins=False)
vu.add_vhdl_builtins()
for library_name in read_lines(LISTS / "libraries.src"):
    library = vu.add_library(library_name)
    for source in read_lines(LISTS / f"{library_name}_vhdl.src"):
        library.add_source_file(source)

vu.set_compile_option("ghdl.a_flags", ["-frelaxed", "-Wno-hide", "-Wno-shared"])
vu.set_sim_option("ghdl.elab_flags", ["-frelaxed"])
vu.set_compile_option("nvc.a_flags", ["--relaxed"])
vu.main()
