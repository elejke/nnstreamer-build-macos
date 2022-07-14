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

import argparse
import os
import re
import sys

# Used to extract list of muxers, demuxers, encoders, etc.
if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description='Find extern declarations in all*.c')

    arg_parser.add_argument('--suffix', metavar='STRING',
                            default='',
                            help='Variable name suffix, e.g. muxer')
    arg_parser.add_argument('--type', metavar='STRING',
                            default='',
                            help='Variable type, e.g. AVOutputFormat')
    arg_parser.add_argument('--thing-suffix', metavar='STRING',
                            default='',
                            help='suffix to add to the thing name')
    arg_parser.add_argument('files', metavar='FILE', nargs='*',
                            type=argparse.FileType('r'),
                            help='File with lists of declarations, ' +
                            'or "-" for standard input')

    args = arg_parser.parse_args()

    things = []

    for infile in args.files:
        for line in infile:
            matches = re.match(r'^extern.*' + args.type + ' *ff_([^ ]*)_' + args.suffix + ';', line.strip())
            if matches:
                things += [matches.group(1).strip()]

    for thing in things:
        print('%s_%s' % (thing, args.thing_suffix))
