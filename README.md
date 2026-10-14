# ohsh-demo

A small FPGA design laid out as a [hog](https://hog.readthedocs.io) repository,
used to test [ohsh](https://github.com/logvik-org/ohsh) in an environment like
a real project's: hog, two third-party HDL libraries and two verification
libraries as git submodules, several libraries, and a source tree that is more
than a handful of files.

The design receives bytes on a UART and sends them back with the case of every
letter swapped. A button turns the swapping off and on again. It uses
[Open Logic](https://github.com/open-logic/open-logic) for the UART, the FIFO
and the reset synchronizer, and [colibri](https://gitlab.cern.ch/colibri/colibri)
to synchronize, debounce and detect the presses of the button.

The same test is written four times, once plainly and once with each of
[UVVM](https://github.com/UVVM/UVVM), [OSVVM](https://github.com/OSVVM/OSVVM)
and [VUnit](https://vunit.github.io): a message goes in over the UART and comes
back with its case swapped, then the button is pressed and the next message
comes back unchanged.

## Layout

```
ohsh-demo/
├── Hog/                     hog, a git submodule
├── lib/
│   ├── open-logic/          Open Logic, a git submodule (with en_cl_fix inside)
│   ├── colibri/             colibri, a git submodule
│   ├── uvvm/                UVVM, a git submodule
│   └── osvvm/               OSVVM, a git submodule
├── manifests/               ohsh manifests for the submodules, see below
│   ├── open-logic/
│   ├── colibri/
│   ├── uvvm/
│   └── osvvm/
├── src/                     the design, one directory and manifest per module
│   ├── demo_pkg/            library demo_common
│   ├── byte_transform/      library demo (the top library)
│   ├── uart_echo/           library demo
│   └── top_demo/            library demo, the top entity
├── tb/                      the testbenches, each with a manifest_tb.json
│   ├── tb_top_demo/         plain VHDL
│   ├── tb_top_demo_uvvm/    UVVM, with its UART VVC
│   ├── tb_top_demo_osvvm/   OSVVM, with a scoreboard
│   └── tb_top_demo_vunit/   VUnit, two test cases, and its run.py
├── constraints/             Arty A7-35T pins and clock
├── Top/demo/
│   ├── hog.conf
│   ├── pre-creation.tcl     runs ohsh every time hog creates the project
│   └── list/
│       ├── colibri.src      ┐
│       ├── demo.src         │
│       ├── demo_common.src  ├ written by ohsh, not in git
│       ├── olo.src          ┘
│       ├── constraints.con  written by hand
│       └── demo.sim         written by hand, the GHDL simulation set
└── scripts/                 the checks CI runs
```

| Library | Modules | Comes from |
|---|---|---|
| `olo` | `open_logic` | `lib/open-logic`, through `manifests/open-logic` |
| `colibri` | `colibri_common` and 22 more | `lib/colibri`, through `manifests/colibri` |
| `demo_common` | `demo_pkg` | `src/` |
| `uvvm_util`, `uvvm_vvc_framework`, `bitvis_vip_scoreboard`, `bitvis_vip_uart` | one each, of the same name | `lib/uvvm`, through `manifests/uvvm` |
| `osvvm` | `osvvm` | `lib/osvvm`, through `manifests/osvvm` |
| `demo` | `byte_transform`, `uart_echo`, `top_demo` and the four testbenches | `src/`, `tb/` |

## Third-party libraries

None of the libraries has ohsh manifests, and the files of a submodule cannot
be changed without forking it. Their manifests therefore live in this
repository, under `manifests/`, and point into the submodules. Between them the
libraries show the three ways to write them.

### Open Logic: one manifest that reads the library's compile order

`manifests/open-logic/manifest.json`:

```json
{
  "module": "open_logic",
  "source_lists": [
    "../../lib/open-logic/compile_order.txt"
  ]
}
```

Open Logic ships its own compile order in `compile_order.txt`, so the manifest
reads the file list from there with `source_lists` instead of copying it. When
Open Logic is updated, the manifest follows without any change. All of Open
Logic goes into the library `olo`, which is the name its documentation uses.

### colibri: manifests written by `ohsh --create`

colibri ships no compile order (its `utils/hog/colibri.src` is sorted by name,
which only works for tools that sort the files themselves). So its manifests
were written by `ohsh --create`, which reads the sources to find the
dependencies between the modules and the order of their files. With
`--manifest-dir` it writes them into this repository instead of into the
submodule:

```bash
ohsh --create -t lib/colibri/src --manifest-dir manifests/colibri
```

That gives one module per source directory, with paths such as
`../../../lib/colibri/src/common/debouncer.vhdl`. Three things were done by hand
afterwards, which is typical for a library of this size:

- Every module name got the prefix `colibri_`, because module names must be
  unique across the repository and `common` or `uart` are not.
- `comms/cc_gearbox.vhdl` became a module of its own, `colibri_cc_gearbox`.
  It uses the FIFOs of `memory`, which use `comms/gearbox.vhdl`, so the two
  directories depended on each other in a loop, which ohsh rejects.
- For the same reason, `memory/mem_pkg.vhdl` became `colibri_mem_pkg`, which
  `memory` and `memory/optimized` both use.

`ohsh --fix -t .` then added the dependencies the split modules need, and
`ohsh --check -t .` confirms that all manifests match their sources.

The design only uses `colibri_common`, so only its 18 files end up in
`colibri.src`, not the whole library.

### UVVM: one manifest per library, each reading its compile order

UVVM ships the compile order of each of its libraries in
`<library>/script/compile_order.txt`, with paths relative to that file. So, as
for Open Logic, each manifest only points at that file, for example
`manifests/uvvm/bitvis_vip_uart/manifest.json`:

```json
{
  "module": "bitvis_vip_uart",
  "source_lists": [
    "../../../lib/uvvm/bitvis_vip_uart/script/compile_order.txt"
  ],
  "dependencies": {
    "uvvm_util": ["uvvm_util"],
    "uvvm_vvc_framework": ["uvvm_vvc_framework"],
    "bitvis_vip_scoreboard": ["bitvis_vip_scoreboard"]
  }
}
```

Only the four libraries the UART VVC needs have manifests. UVVM has many more
VIPs, which get a manifest the same way when a testbench needs one.

### OSVVM: a manifest written by hand

OSVVM's compile order is `osvvm.pro`, a script that picks some files by
simulator and VHDL version, so no list file to point at exists.
`manifests/osvvm/manifest.json` lists the files by hand, as `osvvm.pro` picks
them for VHDL-2008 on GHDL and NVC: the `deprecated/*_c.vhd` variants where the
2019 versions need VHDL-2019, and the default settings packages. A newer OSVVM
may change that list, so compare it with `osvvm.pro` when updating.

### VUnit

VUnit is installed with pip and brings its own `vunit_lib`, so it needs no
manifest. `tb/tb_top_demo_vunit/run.py` runs ohsh and adds every library in
`libraries.src` to VUnit with its sources. VUnit works out the compile order
itself, so it only uses the lists to know which files go into which library.

### When a library is updated

Update the submodule, then run `ohsh --check -t .`. The Open Logic and UVVM
manifests follow their compile orders without changes, and the OSVVM one needs
comparing with `osvvm.pro`. For colibri, run the `--create`
command again to get manifests for new directories, and `--fix` for new
dependencies.

## hog

`Top/demo/pre-creation.tcl` runs ohsh every time hog creates the project, so
the `.src` lists always match the manifests when Vivado reads them:

```bash
./Hog/Do CREATE demo      # needs Vivado and ohsh on PATH
```

The lists are build output, so git ignores them. A fresh clone has none until
hog creates the project, and hog's GHDL simulation reads them without creating
one, so write them first with `scripts/run-hog-hook.sh`, which runs
`pre-creation.tcl` the way hog does:

```bash
scripts/run-hog-hook.sh
./Hog/Do SIMULATION demo -simset demo
```

The constraints and the simulation set are not HDL sources, so they are in list
files written by hand and committed.

hog's simulation runs the plain testbench only. hog puts every file of a
simulation set into one library named after the set, while UVVM and OSVVM must
each be compiled into libraries of their own.

## Running the checks

Install ohsh and VUnit (`pip install ohsh vunit-hdl`),
[GHDL](https://github.com/ghdl/ghdl), [NVC](https://www.nickg.me.uk/nvc/) and
`tclsh` with tcllib, then:

```bash
git clone --recurse-submodules https://github.com/logvik-org/ohsh-demo.git
cd ohsh-demo
scripts/run-all.sh
```

| Script | What it checks |
|---|---|
| `check-manifests.sh` | `ohsh --check` finds no missing dependency or misordered sources. |
| `sim-ghdl.sh` | For the plain, UVVM and OSVVM testbenches, GHDL compiles every library in the order of `libraries.src` and the testbench passes. |
| `sim-nvc.sh` | The same with NVC. |
| `sim-vunit.sh` | VUnit runs both test cases of the VUnit testbench, with GHDL and with NVC. |
| `sim-hog.sh` | `pre-creation.tcl` writes the hog lists the way hog runs it, then `./Hog/Do SIMULATION demo` runs the testbench with GHDL from them. |

CI runs all of them on every pull request.

## License

Apache License 2.0, see [LICENSE](LICENSE). The submodules keep their own
licenses: hog, UVVM and OSVVM are Apache-2.0, Open Logic uses the PSI HDL
Library License, and colibri is CERN-OHL-W-2.0.
