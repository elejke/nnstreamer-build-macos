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

import re
from collections import defaultdict

GRAPH = defaultdict(dict)

def build_graph(pattern):
    with open('configure', 'r') as f:
        for l in f.readlines():
            l = l.strip()
            if re.match(r'^.*_' + pattern + '=\".*\"$', l):
                label, selector = l.split('=')

                if '$' in label or '$' in selector:
                    print ('Warning: skip line: %s', l)
                    continue

                label = label.rsplit('_', 1 + pattern.count('_'))[0].lower()

                parent_labels = [plabel.lower() for plabel in selector.strip('\"').split()]
                GRAPH[label][pattern] = parent_labels

build_graph('select')
build_graph('deps')
build_graph('suggest')
build_graph('deps_any')
build_graph('conflict')
build_graph('if')
build_graph('if_any')

from pprint import pformat
with open('depgraph.py', 'w') as f:
    f.write ('GRAPH = %s\n' % pformat (dict(GRAPH)))
