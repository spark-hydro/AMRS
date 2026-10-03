# Known issues found while porting to CMake / gfortran / ifx

Found 2026-10-02 while comparing gfortran 16, ifx 2025.3 and the Windows ifort reference
(`data/animas`, 3-year run). None of these were changed in the model (a port must not change the
science), except where marked. They are for the model authors to decide.

## 1. Negative concentrations feed a NaN into the salt chemistry (`src/MODFLOW/rt_salt.f`)

- The RT3D solver leaves **negative concentrations**: 1,874 of 3,537 active cells (53%) on day 1 of
  the example run, about 400 a day in year 1, about 16 a day by year 3.
- `salt_solve` computes the ionic strength from those concentrations, so it can be negative, and
  `activity_coefficient` takes `I_Prep_in**0.5`: **NaN** in `LAMDA`, then in the solubility
  constants `salt_K1..5`.
- In `CaCO3`, `MgCO3`, `CaSO4`, `MgSO4`, `NaCl` both tests (`Trial_Ksp.GT.Ksp`, `M1.GT.Solv`) are
  then false, so the code takes the last branch, "solid will be completely dissolved". Every
  negative-concentration cell dissolves **all** of its solid mineral. Whether a comparison with NaN
  is false depends on the compiler's floating-point model.
- NaN does not reach the output on gfortran or on ifx with default flags.
- Suggested fix (changes results, needs a new reference): skip the chemistry for cells with a
  non-positive or NaN ionic strength, or clamp negative concentrations to zero after transport.
  Tested in a scratch copy: it changes only the salt (`cSalt`) results.

## 2. `cationexchange` takes square roots of non-positive numbers (fixed, same results)

`Con_Ca**0.5` etc. were evaluated before the `Con <= 0` check; the result was then replaced by
`-10` and `salt_solve` ignored all four values. Under strict floating point (ifx `-fp-model=precise`)
this NaN leaked into the APEX daily output (`SITE75.DWS/.RCH/.MWS`). The subroutine now returns the
same `-10` flags before the square roots. **Output is identical** (37 output files compared, 0
differ, gfortran Release, 3-year example). With this and the guard in item 1, ifx Debug with
`-fpe0 -fp-model=precise` runs the whole example with no floating-point trap.

## 3. Cation exchange never runs in the example

`salt_solve` skips the exchange when any of Ca, Mg, Na, K is `<= 0`. In the example that is
3,536,997 of 3,537,000 cell-visits, so the cation-exchange code has no effect.

## 4. Smaller points

- `SkipedIEX` (`rt_salt.f`) is incremented but never initialised (only a counter).
- `if(isnan(x)) dum = 10` stubs (debugger breakpoints) in `rt_run.f`, `rt_ssm.f`, `EYSED.f90`: they
  do nothing and may be removed by the optimiser.
- `salt_solve` is called when RT3D option `trnop(6)` is on, regardless of `ISALT` in `APEXCONT.DAT`.
  With `ISALT=0` and `trnop(6)` on, the salt arrays are unallocated (bounds error in Debug).
- Free-form string continuations without a leading `&` (15 places) put the leading blanks inside the
  string on gfortran and are rejected by ifx; they now have `&` (report header text only).

## 5. Reference run and compiler dependence (why the regression tolerance is tiered)

Reference outputs in `data/animas`: 3-year run of `amrs_rel24-003.exe` (Intel ifort, Windows), the
build of the source in this repository (rev.24-003). Other Windows builds were compared on the same
inputs: `amrs_rel230127`, `amrs_rel24-002`, `amrs_deb24-002` and `APEX-MODFLOW-Salt-V2` give the old
`SITE75.MWS` monthly values (38.27 in Jan 1987); only rev.24-003 gives 3.609e+07, as gfortran and
ifx do. So an older executable is not a valid reference for this source.

Whole-file relative error (`relL2`) against the reference, 3-year example:

| Group | gfortran Release (Debug the same) | ifx Linux (default flags) |
|---|---|---|
| `SITE75.MWS` | 1.5e-10 | 2.9e-9 |
| other APEX `SITE75.*` | <= 7.9e-4 | <= 4.5e-3 |
| MODFLOW flow, recharge, percolation, channel depth | <= 1.4e-2 | <= 2.8e-2 |
| RT3D nitrate, phosphorus, salt, river loads | 0.01 - 0.25 | 0.38 - 1.2 |

Between Windows ifort builds on the same inputs, Release and Debug already differ in the RT3D
transport files (Debug vs Release 0.01 - 0.13), so a transport difference of that size between
compilers is not a porting error. ifx differs most; the cause is not found (not the salt NaN path,
not uninitialised locals `-init=zero,arrays`, not the floating-point model `-fp-model=precise`, not
the optimisation level; `-save` does not run on ifx: "allocate error"). `scripts/regress.py`
therefore gates the APEX and MODFLOW flow files and only reports the RT3D transport files. Gates:
`SITE75.DWS/.MWS/.WSS` 1e-2 (seen <= 1e-4), all other gated files 2e-1 (seen <= 6.4e-2, on ifx 2025.2
Debug in GitHub Actions: `amf_apex_channel` 6.4e-2, `SITE75.SWT` 4.0e-2), i.e. at least 3x the worst value.
