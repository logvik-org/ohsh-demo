# ohsh-demo

A small FPGA design laid out as a [hog](https://hog.readthedocs.io) repository,
used to test [ohsh](https://github.com/logvik-org/ohsh) in an environment like
a real project's: hog and two third-party HDL libraries as git submodules,
several libraries, and a source tree that is more than a handful of files.

The design receives bytes on a UART and sends them back with the case of every
letter swapped. A button turns the swapping off and on again. It uses
[Open Logic](https://github.com/open-logic/open-logic) for the UART, the FIFO
and the reset synchronizer, and [colibri](https://gitlab.cern.ch/colibri/colibri)
to synchronize, debounce and detect the presses of the button.

## Layout

```
ohsh-demo/
├── Hog/                     hog, a git submodule
├── lib/
│   ├── open-logic/          Open Logic, a git submodule (with en_cl_fix inside)
│   └── colibri/             colibri, a git submodule
├── manifests/
│   ├── open-logic/          ohsh manifest for Open Logic, see below
│   └── colibri/             ohsh manifests for colibri, see below
├── src/                     the design, one directory and manifest per module
│   ├── demo_pkg/            library demo_common
│   ├── byte_transform/      library demo (the top library)
│   ├── uart_echo/           library demo
│   └── top_demo/            library demo, the top entity
├── tb/tb_top_demo/          self-checking testbench, with manifest_tb.json
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
| `demo` | `byte_transform`, `uart_echo`, `top_demo`, `tb_top_demo` | `src/`, `tb/` |

## Third-party libraries

Neither library has ohsh manifests, and the files of a submodule cannot be
changed without forking it. Their manifests therefore live in this repository,
under `manifests/`, and point into the submodules. Each library shows one of
two ways to write them.

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

### When a library is updated

Update the submodule, then run `ohsh --check -t .`. The Open Logic manifest
follows its compile order without changes. For colibri, run the `--create`
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

## Running the checks

Install ohsh, [GHDL](https://github.com/ghdl/ghdl), [NVC](https://www.nickg.me.uk/nvc/)
and `tclsh` with tcllib, then:

```bash
git clone --recurse-submodules https://github.com/logvik-org/ohsh-demo.git
cd ohsh-demo
scripts/run-all.sh
```

| Script | What it checks |
|---|---|
| `check-manifests.sh` | `ohsh --check` finds no missing dependency or misordered sources. |
| `sim-ghdl.sh` | GHDL compiles every library in the order of `libraries.src` and the testbench passes. |
| `sim-nvc.sh` | The same with NVC. |
| `sim-hog.sh` | `pre-creation.tcl` writes the hog lists the way hog runs it, then `./Hog/Do SIMULATION demo` runs the testbench with GHDL from them. |

CI runs all of them on every pull request.

## License

Apache License 2.0, see [LICENSE](LICENSE). The submodules keep their own
licenses: hog is Apache-2.0, Open Logic uses the PSI HDL Library License, and
colibri is CERN-OHL-W-2.0.
