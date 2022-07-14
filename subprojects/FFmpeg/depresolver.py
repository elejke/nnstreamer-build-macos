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

'''
Adapted from check_deps in the configure script.
Based on the graph described in depgraph.py, and the system
configuration, this script determines the components to enable.
'''

import argparse
import re
import itertools
import sys

from collections import defaultdict, OrderedDict

from depgraph import GRAPH

LIBRARY_LIST = [
  'avcodec',
  'avdevice',
  'avfilter',
  'avformat',
  'avresample',
  'avutil',
  'postproc',
  'swresample',
  'swscale',
]


class CircularDependency(Exception):
    pass


def parse_conf(path):
    res = {}
    with open(path, 'r') as f:
        for l in f.readlines():
            l = l.strip()
            m = re.match('#define\s+(.*)\s+(.+)', l)
            if m:
                res[m.group(1).lower()] = int(m.group(2))
    return res


def enabled(conf, thing):
    return conf.get(thing, 0) == 1


def disabled(conf, thing):
    return conf.get(thing, 1) == 0


def enable_weak(conf, thing):
    conf[thing] = conf.get(thing, 1)


def enable(conf, thing):
    conf[thing] = 1


def disable(conf, thing):
    conf[thing] = 0


def enable_deep(conf, thing):
    if enabled(conf, thing):
        return

    node = GRAPH.get(thing, {})
    dep_sel = node.get('select', [])
    dep_sgs = node.get('suggest', [])

    for dep in dep_sel:
        enable_deep(conf, dep)
        enable(conf, dep)

    for dep in dep_sgs:
        enable_deep_weak (conf, dep)


def enable_deep_weak(conf, thing):
    if disabled(conf, thing):
        return

    enable_deep(conf, thing)
    enable_weak(conf, thing)


def resolve(conf, thing, flattened_deps, checking={}):
    if thing in checking:
        if checking[thing]:
            raise CircularDependency(thing)
        return

    checking[thing] = True

    node = GRAPH.get(thing, {})

    dep_all = node.get('deps', [])
    dep_any = node.get('deps_any', [])
    dep_con = node.get('conflict', [])
    dep_sel = node.get('select', [])
    dep_sgs = node.get('suggest', [])
    dep_ifa = node.get('if', [])
    dep_ifn = node.get('if_any', [])

    for dep in itertools.chain(dep_all, dep_any, dep_con, dep_sel, dep_sgs,
            dep_ifa, dep_ifn):
        resolve(conf, dep, flattened_deps)

    if dep_ifa and all([enabled(conf, ifa) for ifa in dep_ifa]):
        enable_weak(conf, thing)

    if dep_ifn and any([enabled(conf, ifn) for ifn in dep_ifn]):
        enable_weak(conf, thing)

    if dep_all and not all([enabled(conf, dep) for dep in dep_all]):
        disable(conf, thing)

    if dep_any and not any([enabled(conf, dep) for dep in dep_any]):
        disable(conf, thing)

    if dep_con and not all([disabled(conf, con) for con in dep_con]):
        disable(conf, thing)

    if dep_sel and any([disabled(conf, sel) for sel in dep_sel]):
        disable(conf, thing)

    if enabled(conf, thing):
        for dep in itertools.chain(dep_sel, dep_sgs):
            enable_deep_weak(conf, dep)

    for dep in itertools.chain(dep_all, dep_any, dep_sel, dep_sgs):
        if enabled(conf, dep):
            flattened_deps[thing].update({dep: None})
            flattened_deps[thing].update(flattened_deps[dep])

    checking[thing] = False


def parse_components(path):
    res = []
    with open(path, 'r') as f:
        for l in f.readlines():
            l = l.strip()
            m = re.match('#define\s+(.*)', l)
            if m:
                res.append(m.group(1).lower())
    return res


if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input')
    parser.add_argument('components')
    args = parser.parse_args()

    conf = parse_conf(args.input)

    flattened_deps = defaultdict(OrderedDict)

    things = parse_components(args.components)
    things = [thing.lower() for thing in things]

    for thing in things:
        resolve (conf, thing, flattened_deps)

    for thing in things:
        if not thing in conf:
            conf[thing] = 0

    for key, value in conf.items():
        print ('%s=%d' % (key, value))

    print('//BEGIN_DEPENDS')

    for comp, deps in flattened_deps.items():
        if enabled(conf, comp):
            deps.update({comp: None})
        print ('%s=%s' % (comp, ','.join(deps)))
