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

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description='Find filter registrations in allfilters.c')

    arg_parser.add_argument('--full', action='store_true')

    arg_parser.add_argument('files', metavar='FILE', nargs='*',
                            type=argparse.FileType('r'),
                            help='File with lists of declarations, ' +
                            'or "-" for standard input')

    args = arg_parser.parse_args()

    things = []

    for infile in args.files:
        for line in infile:
            if not args.full:
                matches = re.match(r'^[^#]*extern AVFilter\s*ff_[^_]*_(.*);', line.strip())
            else:
                matches = re.match(r'^[^#]*extern AVFilter\s*ff_(.*_.*);', line.strip())
            if (matches):
                if not args.full:
                    print ('%s_filter' % matches.group(1).strip())
                else:
                    print (matches.group(1).strip())
