#!/usr/bin/env python3

# Copyright (c) 2018 Mathieu Duponchelle <mathieu@centricular.com>
#
# This file is part of the FFmpeg Meson build
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, see <http://www.gnu.org/licenses/>.

import os
import sys
import filecmp
import argparse

def replace_if_changed(new, old):
    '''
    Compare contents and only replace if changed to avoid triggering a rebuild.
    '''
    try:
        changed = not filecmp.cmp(new, old, shallow=False)
    except FileNotFoundError:
        changed = True
    if changed:
        os.replace(new, old)
    else:
        os.remove(new)

# Used to output list of muxers, demuxers, encoders, etc.
if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description='print elements lists')
    arg_parser.add_argument('--struct-name', metavar='STRING',
                            default='',
                            help='Struct name, eg AVCodec')
    arg_parser.add_argument('--name', metavar='STRING',
                            default='',
                            help='Variable name, eg codec_list')
    arg_parser.add_argument('--filename', metavar='STRING',
                            default='',
                            help='File to print lists of declarations to')
    arg_parser.add_argument('things', metavar='STRING', nargs='*',
                            default='',
                            help='List of things')

    args = arg_parser.parse_args()

    tmp_filename = args.filename + '~'
    with open(tmp_filename, 'w') as f:
        f.write('static const %s * const %s[] = {\n' % (args.struct_name, args.name))
        for thing in args.things:
            f.write('    &ff_%s,\n' % (thing))
        f.write('    NULL };\n')
    replace_if_changed(tmp_filename, args.filename)
