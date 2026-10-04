[![Release](https://img.shields.io/github/v/release/spark-hydro/AMRS?style=flat-square)](https://github.com/spark-hydro/AMRS/releases)
[![Docker](https://ghcr-badge.egpl.dev/spark-hydro/amrs/latest_tag?trim=major&label=docker&color=%23007ec6)](https://github.com/spark-hydro/AMRS/pkgs/container/amrs)
[![Build](https://img.shields.io/github/actions/workflow/status/spark-hydro/AMRS/build.yml?branch=main&style=flat-square&label=build%20%2B%20regression%20test)](https://github.com/spark-hydro/AMRS/actions/workflows/build.yml)
[![Downloads](https://img.shields.io/github/downloads/spark-hydro/AMRS/total?style=flat-square)](https://github.com/spark-hydro/AMRS/releases)
[![License](https://img.shields.io/github/license/spark-hydro/AMRS?style=flat-square)](LICENSE)

# AMRS (APEX-MODFLOW-RT3D-Salt)

AMRS couples the agroecosystem model **APEX** (APEX1501) with the groundwater models
**MODFLOW-NWT** and **RT3D**, and a salinity module, in one executable. APEX calculates
land-surface, field and channel processes by subarea and passes recharge and solute loads to
MODFLOW and RT3D. MODFLOW calculates groundwater heads and the exchange with the river network,
RT3D transports nitrate, phosphorus and the salt ions (Ca, Mg, Na, K, SO4, Cl, CO3, HCO3), and the
results are passed back to APEX.

The source is in `src/`: APEX1501 in `src` itself, MODFLOW-NWT, RT3D and the code that links them
in `src/MODFLOW`, and the salinity code in `src/SALINITY`.

## Download

Ready-to-run executables are on the
[Releases page](https://github.com/spark-hydro/AMRS/releases):

| File | For |
|---|---|
| `amrs-<version>-gnu-win_amd64-Rel.zip` | Windows |
| `amrs-<version>-gnu-lin_x86_64-Rel.zip` | Linux (gfortran, static) |
| `amrs-<version>-ifx-lin_x86_64-Rel.zip` | Linux (Intel ifx) |

Each release also has a `SHA256SUMS` file to check the downloads. The Windows executable is not
code signed, and Windows Defender and other antivirus programs sometimes flag such files by mistake; see
[Antivirus warnings](BUILD.md#antivirus-warnings).

## Quick start

1. Unzip the executable for your system.
2. Run it from inside your model folder, the one that contains `APEXRUN.DAT` (and the other APEX
   input files, a `MODFLOW` folder and, if salinity is simulated, a `SALINITY` folder):

   ```bash
   cd my_model_folder
   /path/to/amrs-<version>-gnu-lin_x86_64-Rel
   ```

3. To see which version you have (no model needed):

   ```bash
   amrs-<version>-gnu-lin_x86_64-Rel --version
   ```

On Linux, file names are case-sensitive: the names in the input files must match the files exactly.

## Example model

`data/animas` is the Animas model (1000 m MODFLOW grid, three years, 1987-1989) with reference
outputs from the Windows build `amrs_rel24-003` (Intel ifort). Copy it before running, because a
run writes its outputs into the model folder:

```bash
cp -r data/animas /tmp/mymodel
cd /tmp/mymodel
/path/to/amrs-<version>-gnu-lin_x86_64-Rel
```

## Build from source

See **[BUILD.md](BUILD.md)** for requirements and step-by-step instructions for Linux
(gfortran, Intel ifx) and Windows (gfortran). In short, on Linux:

```bash
cmake --preset gfortran_release_linux
cmake --build build/release
```

## Docker

A ready-made Docker image lets you run the model in a container, for example on a cloud server or a
cluster, without installing a compiler (see [BUILD.md](BUILD.md#docker) to build it yourself):

```bash
docker pull ghcr.io/spark-hydro/amrs:latest
docker run --rm -v /path/to/my_model:/model ghcr.io/spark-hydro/amrs:latest
```

If something goes wrong, add `-e DEBUG=1` to use the debug build (about 3 times slower; it checks
array bounds and names the array and line of a problem). See [BUILD.md](BUILD.md#docker).

Images for every release are on the GitHub Container Registry
([`ghcr.io/spark-hydro/amrs`](https://github.com/spark-hydro/AMRS/pkgs/container/amrs)).

## Testing

`scripts/regress.py` runs the example model and compares the outputs with the reference outputs.
GitHub Actions does this for gfortran and ifx on every pull request, and builds the downloads
above when a version tag such as `v0.1.0` is pushed. The comparison gates the APEX and MODFLOW flow
files and only reports the RT3D transport files, because those depend on the compiler. See
[BUILD.md](BUILD.md#testing) and [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## Credits and citation

The APEX-MODFLOW-RT3D-Salt coupling code (the `amrt_*` files in `src/MODFLOW` and the salinity
code in `src/SALINITY`) was developed for the papers below; see the author notes at the top of the
source files. APEX1501, MODFLOW-NWT and RT3D are the work of their respective developers.

If you use AMRS in your work, please cite:

> Bailey, R. T., Jeong, J., Park, S., and Green, C. H. M. (2022). Simulating salinity transport in
> High-Desert landscapes using APEX-MODFLOW-Salt. *Journal of Hydrology*, 610, 127873.
> [doi:10.1016/j.jhydrol.2022.127873](https://doi.org/10.1016/j.jhydrol.2022.127873)

See also the original APEX-MODFLOW paper and the APEXMOD plugin paper:

> Bailey, R. T., Tasdighi, A., Park, S., Tavakoli-Kivi, S., Abitew, T., Jeong, J., Green, C. H. M.,
> and Worqlul, A. W. (2021). APEX-MODFLOW: A new integrated model to simulate hydrological
> processes in watershed systems. *Environmental Modelling & Software*, 143, 105093.
> [doi:10.1016/j.envsoft.2021.105093](https://doi.org/10.1016/j.envsoft.2021.105093)

> Park, S., Jeong, J., Motter, E., Bailey, R. T., and Green, C. H. M. (2023). Introducing APEXMOD -
> A QGIS plugin for developing coupled surface-subsurface hydrologic modeling framework of APEX,
> MODFLOW, and RT3D-Salt. *Environmental Modelling & Software*, 165, 105723.
> [doi:10.1016/j.envsoft.2023.105723](https://doi.org/10.1016/j.envsoft.2023.105723)

## License

Released under the GNU Lesser General Public License v2.1, as SWAT-MODFLOW3. See [LICENSE](LICENSE).
