#!/usr/bin/env python3
"""Regression check for AMRS.

Copies the dataset to a scratch folder, deletes its old outputs, runs the
executable there, and compares every numeric value in the new outputs with
the reference outputs shipped in the dataset (written by the Windows/Intel
build). The dataset itself is never modified.

    python3 scripts/regress.py build/release/amrs-*-Rel data/Example

Exit code 0 = run finished and all files match within tolerance.
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[EeDd][-+]?\d+)?')
# Files compared (paths relative to the model folder). APEX output names are <site>.<ext>, so
# match by extension. Left out on purpose: *.OUT and MODFLOW/*.lst (embed dates and timings),
# fort.*, RUN1501.SUM, *.apexmf (copies). Do not add *.SUB: SUB0075.SUB is an input.
PATTERNS = ['*.DWS', '*.MWS', '*.RCH', '*.SWT', '*.WSS',
            'MODFLOW/amf_*.out']
# Text the program prints when a run finishes normally; set to None to skip the check.
DONE_TEXT = 'Normal termination of simulation'


def numbers(path):
    # the APEX header line holds the run date and time ("APEX1501 v20181201  2026 10 1 ..."): skip it
    with open(path, errors='ignore') as fh:
        text = ''.join(l for l in fh if 'APEX1501 v' not in l)
    return [float(t.replace('D', 'E').replace('d', 'e')) for t in NUM.findall(text)]


def compare(ref, new, rtol, floor):
    """Return (n_values, max_rel_diff, n_over_tol), or None if counts differ."""
    a, b = numbers(ref), numbers(new)
    if len(a) != len(b):
        return None, len(a), len(b)
    worst, bad, bad2 = 0.0, 0, 0
    for x, y in zip(a, b):
        d = abs(x - y) / max(abs(x), abs(y), floor)
        worst = max(worst, d)
        bad += d > rtol
        bad2 += d > 1e-2
    return (len(a), worst, bad, bad2), len(a), len(b)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument('paths', nargs='+', metavar='exe... dataset',
                    help='executable(s) followed by the model folder. If a glob matches\n'
                         'several executables (the name changes with each commit), the newest is used.')
    ap.add_argument('--rtol', type=float, default=1e-3, help='max relative difference (default 1e-3)')
    ap.add_argument('--floor', type=float, default=1e-6, help='denominator floor for tiny values')
    ap.add_argument('--keep', action='store_true', help='keep the scratch run folder')
    args = ap.parse_args()

    if len(args.paths) < 2:
        ap.error('need an executable and a dataset folder')
    exes = [p for p in args.paths[:-1] if os.path.isfile(p)]
    if not exes:
        sys.exit(f'executable not found: {args.paths[:-1]}')
    exe = os.path.abspath(max(exes, key=os.path.getmtime))
    ref_dir = os.path.abspath(args.paths[-1])
    print(f'executable: {exe}')
    if not os.path.isfile(os.path.join(ref_dir, 'APEXRUN.DAT')):
        sys.exit(f'no APEXRUN.DAT in {ref_dir}')

    ref_files = sorted({os.path.relpath(p, ref_dir) for pat in PATTERNS
                        for p in glob.glob(os.path.join(ref_dir, pat))})
    if not ref_files:
        sys.exit('no reference output files found in the dataset')

    run_dir = tempfile.mkdtemp(prefix='amrs_regress_')
    try:
        print(f'run folder: {run_dir}')
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
        print(f'\n{"file":38s} {"values":>8s} {"max rel diff":>13s}  result')
        for name in ref_files:
            new = os.path.join(run_dir, name)
            if not os.path.isfile(new):
                print(f'{name:38s} {"":8s} {"":13s}  FAIL (not written)')
                failed = True
                continue
            res, na, nb = compare(os.path.join(ref_dir, name), new, args.rtol, args.floor)
            if res is None:
                print(f'{name:38s} {na:8d} {"":13s}  FAIL (value count {na} vs {nb})')
                failed = True
            else:
                n, worst, bad, bad2 = res
                ok = bad == 0
                failed |= not ok
                print(f'{name:38s} {n:8d} {worst:13.2e}  {"ok" if ok else f"FAIL ({bad} over {args.rtol:g}, {bad2} over 1e-2)"}')
        print('\nPASSED' if not failed else '\nFAILED')
        if failed:
            args.keep = True
        return 1 if failed else 0
    finally:
        if args.keep:
            print(f'kept: {run_dir}')
        else:
            shutil.rmtree(run_dir, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
