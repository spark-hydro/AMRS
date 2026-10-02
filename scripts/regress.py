#!/usr/bin/env python3
"""Regression check for AMRS.

Copies the dataset to a scratch folder, deletes its old outputs, runs the
executable there, and compares the new outputs with the reference outputs shipped
in the dataset (written by the Windows/Intel build). The dataset itself is never
modified.

    python3 scripts/regress.py build/release/amrs-*-Rel data/animas

Always required (every file): the run exits 0 and prints the completion text, the file
is written, it has the same number of values as the reference, and it has no NaN/Infinity.

Tolerance (see RULES below). Two error measures per file, both relative to the file's
own size, so near-zero values do not blow up the comparison:
    relL2 = ||new - ref|| / ||ref||          (whole-file error)
    nmax  = max|new - ref| / max|ref|        (largest single difference)
Files are gated on relL2 per group; the RT3D transport files are only reported.
Why: the reference is one Intel (ifort, Windows) run. The salt/nitrate/phosphorus
transport results are very sensitive to the compiler and its flags (gfortran Release and
Debug agree with each other, differ from ifort by relL2 ~0.05-0.08; ifx on Linux differs by
~1.0), so a numeric gate on them would only measure the compiler. The thresholds are about
3x above the worst difference seen on gfortran 16 and ifx 2025.3, to catch real breakage
(wrong flow, missing output, NaN) and not compiler noise.

    --strict   per-value relative tolerance (--rtol, default 1e-3) on every file: for
               comparing two builds that should be identical (same compiler and flags).
    --compare DIR   do not run the model; compare the outputs already in DIR.

Exit code 0 = run finished and every gated file is within tolerance.
"""
import argparse
import glob
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[EeDd][-+]?\d+)?')
BAD = re.compile(r'\b(nan|[-+]?inf(inity)?)\b', re.I)
# Files compared (paths relative to the model folder). APEX output names are <site>.<ext>, so
# match by extension. Left out on purpose: *.OUT and MODFLOW/*.lst (embed dates and timings),
# fort.*, RUN1501.SUM, *.apexmf (copies). Do not add *.SUB: SUB0075.SUB is an input.
PATTERNS = ['*.DWS', '*.MWS', '*.RCH', '*.SWT', '*.WSS',
            'MODFLOW/amf_*.out']
# First matching rule wins: (regex on the relative path, 'gate' or 'info', max relL2 for 'gate').
# Observed relL2 (gfortran Release = Debug / ifx, 3-year animas dataset) in the comments.
RULES = [
    # APEX outputs: <= 5.8e-3 (gfortran), <= 6.8e-3 (ifx)
    (r'^(?!MODFLOW/)', 'gate', 2e-2),
    # RT3D concentrations and solute loads to/from the river: 0.01-0.08 (gfortran), 0.1-1.0 (ifx)
    (r'^MODFLOW/amf_(RT3D_c|RT_riv|apex_riv)', 'info', None),
    # MODFLOW flow, recharge, percolation, channel depth: <= 1.2e-2 (gfortran), <= 3.2e-2 (ifx)
    (r'^MODFLOW/', 'gate', 1e-1),
]
# Text the program prints when a run finishes normally; set to None to skip the check.
DONE_TEXT = 'Normal termination of simulation'


def read(path):
    # the APEX header line holds the run date and time ("APEX1501 v20181201  2026 10 1 ..."): skip it
    with open(path, errors='ignore') as fh:
        return ''.join(l for l in fh if 'APEX1501 v' not in l)


def numbers(text):
    return [float(t.replace('D', 'E').replace('d', 'e')) for t in NUM.findall(text)]


def rule_for(name):
    for pat, mode, tol in RULES:
        if re.search(pat, name.replace(os.sep, '/')):
            return mode, tol
    return 'gate', 1e-1


def measures(a, b):
    """relL2, nmax for two equal-length lists."""
    amax = max((abs(x) for x in a), default=0.0) or 1.0
    anorm = math.sqrt(sum(x * x for x in a)) or 1.0
    l2 = math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b))) / anorm
    nmax = max((abs(x - y) for x, y in zip(a, b)), default=0.0) / amax
    return l2, nmax


def strict(a, b, rtol, floor):
    """Old per-value test: (max_rel_diff, n_over_rtol, n_over_1e-2)."""
    worst, bad, bad2 = 0.0, 0, 0
    for x, y in zip(a, b):
        d = abs(x - y) / max(abs(x), abs(y), floor)
        worst = max(worst, d)
        bad += d > rtol
        bad2 += d > 1e-2
    return worst, bad, bad2


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument('paths', nargs='+', metavar='exe... dataset',
                    help='executable(s) followed by the model folder. If a glob matches\n'
                         'several executables (the name changes with each commit), the newest is used.\n'
                         'With --compare: just the model folder.')
    ap.add_argument('--strict', action='store_true', help='per-value tolerance on every file')
    ap.add_argument('--rtol', type=float, default=1e-3, help='--strict: max relative difference (default 1e-3)')
    ap.add_argument('--floor', type=float, default=1e-6, help='--strict: denominator floor for tiny values')
    ap.add_argument('--compare', metavar='DIR', help='compare the outputs in DIR, do not run the model')
    ap.add_argument('--keep', action='store_true', help='keep the scratch run folder')
    args = ap.parse_args()

    ref_dir = os.path.abspath(args.paths[-1])
    exe = None
    if not args.compare:
        if len(args.paths) < 2:
            ap.error('need an executable and a dataset folder')
        exes = [p for p in args.paths[:-1] if os.path.isfile(p)]
        if not exes:
            sys.exit(f'executable not found: {args.paths[:-1]}')
        exe = os.path.abspath(max(exes, key=os.path.getmtime))
        print(f'executable: {exe}')
    if not os.path.isfile(os.path.join(ref_dir, 'APEXRUN.DAT')):
        sys.exit(f'no APEXRUN.DAT in {ref_dir}')

    ref_files = sorted({os.path.relpath(p, ref_dir) for pat in PATTERNS
                        for p in glob.glob(os.path.join(ref_dir, pat))})
    if not ref_files:
        sys.exit('no reference output files found in the dataset')

    run_dir = os.path.abspath(args.compare) if args.compare else tempfile.mkdtemp(prefix='amrs_regress_')
    failed = False
    try:
        print(f'run folder: {run_dir}')
        if not args.compare:
            shutil.copytree(ref_dir, run_dir, dirs_exist_ok=True)
            # Linux is case-sensitive, Windows is not: add a lowercase copy of any
            # file whose name has capitals (e.g. Tmp1.Tmp -> tmp1.tmp).
            for top, _dirs, names in os.walk(run_dir):
                for name in names:
                    low = name.lower()
                    if low != name and not os.path.exists(os.path.join(top, low)):
                        shutil.copy2(os.path.join(top, name), os.path.join(top, low))
            # Remove old outputs so a file that is not rewritten is caught.
            for name in ref_files:
                os.remove(os.path.join(run_dir, name))

            t0 = time.time()
            with open(os.path.join(run_dir, 'run.log'), 'w') as log:
                rc = subprocess.run([exe], cwd=run_dir, stdout=log, stderr=subprocess.STDOUT).returncode
            with open(os.path.join(run_dir, 'run.log'), errors='ignore') as fh:
                done = DONE_TEXT is None or DONE_TEXT in fh.read()
            print(f'run: exit {rc}, {time.time() - t0:.1f} s, '
                  f'{"completed" if done else "DID NOT COMPLETE"}')
            failed = rc != 0 or not done

        if args.strict:
            print(f'\n{"file":38s} {"values":>8s} {"max rel diff":>13s}  result')
        else:
            print(f'\n{"file":38s} {"values":>8s} {"relL2":>9s} {"nmax":>9s}  {"rule":12s} result')
        n_info = 0
        for name in ref_files:
            new = os.path.join(run_dir, name)
            if not os.path.isfile(new):
                print(f'{name:38s}  FAIL (not written)')
                failed = True
                continue
            ref_text, new_text = read(os.path.join(ref_dir, name)), read(new)
            a, b = numbers(ref_text), numbers(new_text)
            if len(a) != len(b):
                print(f'{name:38s} {len(a):8d}  FAIL (value count {len(a)} vs {len(b)})')
                failed = True
                continue
            if BAD.search(new_text):
                print(f'{name:38s} {len(a):8d}  FAIL (NaN or Infinity in the output)')
                failed = True
                continue
            if args.strict:
                worst, bad, bad2 = strict(a, b, args.rtol, args.floor)
                ok = bad == 0
                failed |= not ok
                print(f'{name:38s} {len(a):8d} {worst:13.2e}  '
                      f'{"ok" if ok else f"FAIL ({bad} over {args.rtol:g}, {bad2} over 1e-2)"}')
                continue
            l2, nmax = measures(a, b)
            mode, tol = rule_for(name)
            if mode == 'info':
                n_info += 1
                label, res = 'info', 'info (reported, not gated)'
            else:
                ok = l2 <= tol
                failed |= not ok
                label, res = f'relL2<={tol:g}', 'ok' if ok else f'FAIL (relL2 {l2:.2e} > {tol:g})'
            print(f'{name:38s} {len(a):8d} {l2:9.2e} {nmax:9.2e}  {label:12s} {res}')
        if n_info:
            print(f'\n{n_info} transport files are reported only (see the docstring of this script).')
        print('\nPASSED' if not failed else '\nFAILED')
        if failed:
            args.keep = True
        return 1 if failed else 0
    finally:
        if args.keep or args.compare:
            print(f'kept: {run_dir}')
        else:
            shutil.rmtree(run_dir, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
