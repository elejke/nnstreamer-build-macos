#!/usr/bin/python
"""
Simple and dirty script to update the `.def` files using `nm`.
"""
import subprocess
import sys
import argparse
import os
import glob

parser = argparse.ArgumentParser()
parser.add_argument('builddir')
args = parser.parse_args()

for lib in glob.glob(os.path.join(args.builddir, "lib*.so")):
    out = subprocess.check_output(["nm", lib]).decode()
    symbols = []
    libname = os.path.basename(lib)[3:].replace('.so', '')
    for l in out.split('\n'):
        if not l:
            continue

        try:
            _, stype, symbol  = l.split(' ')
        except:
            continue

        # This symbols are macros when built with MSVC
        if symbol in ['avpriv_open', 'avpriv_tempfile']:
            continue

        if stype.islower() or stype in ['A']:
            continue

        if stype in ['R', 'S', 'D', 'G']:
            symbol += ' DATA'

        symbols.append(symbol)

    symbols = sorted(symbols)
    deffile = os.path.join('compat', 'windows', libname + '.def')
    print("Updating %s" % deffile)
    with open(deffile, 'w') as f:
        f.write('EXPORTS\n')
        f.write('\n'.join(symbols))