# Building AMRS

AMRS builds with CMake and a Fortran compiler (gfortran or Intel ifx), on Linux and Windows.
This replaces the old Visual Studio project. The sources are in `src/` (APEX1501), `src/MODFLOW`
(MODFLOW-NWT, RT3D and the APEX-MODFLOW link code) and `src/SALINITY`.

## Just want the program?

Download a build from the [Releases page](https://github.com/spark-hydro/AMRS/releases):

| File | For |
|---|---|
| `amrs-<version>-gnu-win_amd64-Rel.zip` | Windows (gfortran) |
| `amrs-<version>-gnu-lin_x86_64-Rel.zip` | Linux (gfortran, static) |
| `amrs-<version>-ifx-lin_x86_64-Rel.zip` | Linux (Intel ifx) |

Unzip, then run the executable from inside your model folder (the one with `APEXRUN.DAT`).

To check a download, compare it with the `SHA256SUMS` file on the release page
(`sha256sum -c SHA256SUMS` on Linux, `Get-FileHash <file> -Algorithm SHA256` in PowerShell).
See [Antivirus warnings](#antivirus-warnings) if your system flags the Windows file.

## Requirements

- A Fortran compiler: gfortran 13 or newer, or Intel ifx
- CMake 3.22 or newer
- Ninja (the presets use it)
- Python 3, only for the regression test

Install on Arch: `sudo pacman -S gcc-fortran cmake ninja python`
Install on Ubuntu/Debian: `sudo apt install gfortran cmake ninja-build python3`

## Linux, gfortran

Run from the repository folder:

```bash
cmake --preset gfortran_release_linux
cmake --build build/release
```

The executable is `build/release/amrs-<version>-gnu-lin_x86_64-Rel`. For a debug build with
array-bounds checks use `gfortran_debug_linux` and `build/debug`. The Debug presets also trap
floating-point errors, and the salinity code does invalid operations on purpose
(see [KNOWN_ISSUES.md](KNOWN_ISSUES.md)), so a Debug build stops in `rt_salt.f` on a normal model.
For a full run in Debug turn the traps off:

```bash
cmake --preset gfortran_debug_linux -D AMRS_FPE_TRAP=OFF
cmake --build build/debug
```

Without presets:

```bash
cmake -B build -G Ninja -D CMAKE_Fortran_COMPILER=gfortran -D CMAKE_BUILD_TYPE=Release
cmake --build build
```

## Linux, Intel ifx

```bash
source /opt/intel/oneapi/setvars.sh        # path depends on where oneAPI is installed
cmake -S . -B build/ifx -G Ninja -D CMAKE_BUILD_TYPE=Release -D CMAKE_Fortran_COMPILER=ifx
cmake --build build/ifx
```

`-B build/ifx` keeps it separate from a gfortran build. Use `-D CMAKE_BUILD_TYPE=Debug` for Debug
(add `-D AMRS_FPE_TRAP=OFF` for a full run, as above). The Intel runtime is linked statically, so
the executable runs on machines without oneAPI.

## Windows, gfortran (MSYS2)

1. Install [MSYS2](https://www.msys2.org) and open the **UCRT64** shell.
2. Install the tools:
   ```bash
   pacman -S mingw-w64-ucrt-x86_64-gcc-fortran mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
   ```
3. In that shell, go to the repository folder (drive `E:` is `/e/`) and run:
   ```bash
   cmake --preset gfortran_release_windows
   cmake --build build/release
   ```

The executable is `build\release\amrs-<version>-gnu-win_amd64-Rel.exe`. The release workflow
builds Windows this way on GitHub. A full run of the model on Windows against the reference has
not been checked yet.

## Antivirus warnings

The Windows executable is built from this source by GitHub Actions (MinGW gfortran, statically
linked) and is not code signed. Some antivirus programs and cloud scanners (for example the one
in OneDrive) flag unsigned executables like this one as malware: a false positive. Before you
trust or allow the file:

- check that the download matches `SHA256SUMS` from the release page (see above);
- optionally look the SHA-256 of the `.exe` up on [virustotal.com](https://www.virustotal.com):
  one or two heuristic hits among many engines point to a false positive;
- if you prefer not to download an executable, build it yourself on your machine
  (see [Windows, gfortran (MSYS2)](#windows-gfortran-msys2) above);
- you can report a false positive to Microsoft at
  <https://www.microsoft.com/en-us/wdsi/filesubmission>.

If the sums do not match, do not run the file; open an issue instead.

## Running a model

Run the executable from inside the model folder, which must contain `APEXRUN.DAT`,
`APEXCONT.DAT`, `APEXFILE.DAT`, `APEXDIM.DAT` and the other APEX input files, a `MODFLOW` folder
(with `modflow.mfn` and the `apexmf_*.txt` link files) and, when salinity is simulated, a
`SALINITY` folder (with `salt_input`).

For example, with a copy of the example model (a run writes its output files into the folder,
so do not run inside `data/animas` itself):

```bash
cp -r data/animas /tmp/mymodel
cd /tmp/mymodel
/path/to/repo/build/release/amrs-*-Rel
```

On Linux, file names are case-sensitive: the names in the input files must match the files
exactly. Windows-style `\` in the file names read from the MODFLOW input files is accepted.

To see which version you have, without a model:

```bash
amrs-<version>-gnu-lin_x86_64-Rel --version
```

The same information is printed at the start of every run.

## Docker

The `Dockerfile` builds AMRS with CMake and gfortran on Ubuntu 24.04 and gives a small image that
runs a model from a mounted folder. Useful for cloud and cluster runs, or when you do not want to
install a compiler.

Ready-made images are published with every release on the GitHub Container Registry, so you do
not need to build anything:

```bash
docker pull ghcr.io/spark-hydro/amrs:latest          # or a version, e.g. :v0.1.0
docker run --rm ghcr.io/spark-hydro/amrs:latest --version
docker run --rm -v /path/to/my_model:/model ghcr.io/spark-hydro/amrs:latest
```

The image contains two builds of the program. The normal (fast) build runs by default. If a run
fails or you want more checks, start the container with `-e DEBUG=1` to use the **debug build**,
which checks array bounds and reports the array and line where something goes wrong. It is about
3 times slower, so use it only to find a problem:

```bash
docker run --rm -e DEBUG=1 -v /path/to/my_model:/model ghcr.io/spark-hydro/amrs:latest
```

`DEBUG=0`, `DEBUG=false` or leaving it out gives the normal build. The banner at the start of the
run shows which one is running (`Release` or `Debug`). The debug build in the image leaves out the
floating-point traps that the Debug builds made with CMake have.

To build the image yourself from the source:

```bash
docker build -t amrs --build-arg VERSION=$(git describe --tags --always) .
docker run --rm amrs --version
docker run --rm -v /path/to/my_model:/model amrs
```

- `-v /path/to/my_model:/model` attaches your model folder (with `APEXRUN.DAT`); the outputs are
  written back into it. Add `--user "$(id -u):$(id -g)"` so the files belong to you instead of root.
- `VERSION` is only used for the version shown by `--version`; without it the image says `unknown`.

## Testing

`data/animas` is an example model (three years, 1987-1989) with reference outputs from the Windows
build `amrs_rel24-003` (Intel ifort), the build of this source. The regression script runs the
model on a temporary copy and compares the outputs with the reference:

```bash
python3 scripts/regress.py build/release/amrs-*-Rel data/animas
```

It takes about 75 seconds with a Release build (about 4 minutes with Debug) and ends with
`PASSED` or `FAILED`. It also runs through CTest:

```bash
ctest --test-dir build/release
```

The run must finish normally and write every compared file with the same number of values and no
NaN. The numbers are compared as a whole-file relative error (`relL2`):

- `SITE75.DWS`, `.MWS`, `.WSS`: limit 1e-2 (the builds differ by 1e-4 or less)
- the other APEX files and the MODFLOW flow, recharge, percolation and channel files: limit 2e-1
  (the builds differ by 6.4e-2 or less)
- the RT3D concentration and solute-load files (nitrate, phosphorus, salt) are only reported:
  they differ from the Windows ifort run by 0.01-0.25 with gfortran and 0.4-1.2 with ifx, and
  Windows ifort Release and Debug builds already differ by up to 0.13 from each other

The reasons, and what was found in the salt chemistry, are in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).
`--strict` gives the old per-value test (`--rtol`, default 1e-3) for comparing two builds that
should be identical, and `--compare DIR` checks outputs that are already in a folder instead of
running the model. `--keep` keeps the scratch folder.

The script compares against the output files that are in the folder you give it, so the check is
only independent when those files come from a different, trusted build, as they do in
`data/animas`. Everything a run writes in `data/animas` is ignored by git except the 37 compared
reference files (`data/animas/.gitignore`).

## Good to know

- The version in the executable name and the startup banner comes from `git describe --tags`
  and is set when CMake configures. After a new commit, run the first `cmake` command again to refresh it.
- Old executables stay in `build/` when the version changes. `regress.py` uses the newest one.
- The gfortran flags (`-std=legacy -fdec -fallow-argument-mismatch`, fixed-line length off) are
  needed for the legacy APEX/MODFLOW code; warnings are turned off with `-w`. Remove `-w` in
  `CMakeLists.txt` to see them. Release builds do not trap floating-point errors; Debug builds do
  unless `-D AMRS_FPE_TRAP=OFF` is given (Intel: `-fpe0` in Debug, `-fpe3` otherwise).
- MODFLOW binary files are written as unformatted stream files (the same bytes as the Intel
  `FORM='BINARY'`).
- GitHub Actions builds with gfortran (gcc 13) and ifx, in Release and Debug, and runs the regression on
  every pull request (`.github/workflows/build.yml`); it also builds the Docker image and runs the
  regression inside it. Pushing a tag like `v0.1.0` builds the three downloads above, attaches
  them to a release and publishes the Docker image (`.github/workflows/release.yml`).
