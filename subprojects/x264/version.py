#!/usr/bin/env python3
#
# x264 version.py
#
# Extracts versions for build:
#  - api version based on X264_BUILD in x264.h
#  - revision based on git rev-list | wc -l
#  - commit hash
#
# Usage:
# version.py [--build | --revision | --commit-hash | --package-version]
import argparse
import subprocess
import os
import sys
import shutil

if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser(description='Extract x264 version, revision or commit hash')
    group = arg_parser.add_mutually_exclusive_group()
    group.add_argument('--build', action='store_true')
    group.add_argument('--revision', action='store_true')
    group.add_argument('--commit-hash', action='store_true')
    group.add_argument('--package-version', action='store_true')
    args = arg_parser.parse_args()

    srcroot = os.path.dirname(__file__)

    # API version
    api_version = None
    f = open(os.path.join(srcroot, 'x264.h'), 'r')
    for line in f:
        if line.startswith('#define X264_BUILD '):
            api_version = line[19:].strip()
        if api_version:
            break
    f.close()

    if not api_version:
       print('Warning: Could not extract API version from X264_BUILD in x264.h in', srcroot, file=sys.stderr)
       sys.exit(-1)

    if args.build:
       print(api_version)
       sys.exit(0)

    ver = 0
    head_commit = 'x'

    # check if git checkout
    git_dir = os.path.join(srcroot, '.git')
    is_git = os.path.isdir(git_dir) or os.path.isfile(git_dir)
    have_git = shutil.which('git') is not None

    # revision
    if is_git and have_git:
       git_cmd = subprocess.run(['git', '--git-dir=' + git_dir, 'rev-list', 'HEAD'], stdout=subprocess.PIPE)
       if git_cmd.returncode:
           print('Warning: Could not extract localver via git rev-list in', srcroot, file=sys.stderr)
           sys.exit(-1)
       localver = len(git_cmd.stdout.decode('ascii').strip().split('\n'))
       head_commit = git_cmd.stdout.decode('ascii').strip().split('\n').pop(0)[0:7]

       if localver > 1:
           git_cmd = subprocess.run(['git', '--git-dir=' + git_dir, 'rev-list', 'origin/master..HEAD'], stdout=subprocess.PIPE)
           if git_cmd.returncode:
               print('Warning: Could not extract revision via git rev-list in', srcroot, file=sys.stderr)
               sys.exit(-1)
           ver_diff = len(git_cmd.stdout.decode('ascii').strip().split('\n'))
           ver = localver - ver_diff

           if ver_diff != 0:
               ver = '{0}+{1}'.format(ver,ver_diff)
           else:
               ver = '{0}'.format(ver)

           # locally modified?
           git_cmd = subprocess.run(['git', '--git-dir=' + git_dir, 'status'], stdout=subprocess.PIPE)
           if git_cmd.returncode:
               print('Warning: Could not obtain git status in', srcroot, file=sys.stderr)
               sys.exit(-1)
           if git_cmd.stdout.find(b'modified:') >= 0:
               ver += 'M'

    elif os.path.isfile(os.path.join(srcroot, 'x264_config.h')): # version config shipped in tarball
        f = open(os.path.join(srcroot, 'x264_config.h'), 'r')
        for line in f:
            if line.startswith('#define X264_VERSION '):
                head_commit = line[21:].strip().strip('"').strip().split()[-1]
                ver = line[21:].strip().strip('"').strip().split()[0][1:]
        f.close()

    else: # not git, and no version config in tarball
       print('Warning: Could not extract versions via git rev-list or x264_config.h', file=sys.stderr)
       if is_git and not have_git:
         print('Warning: git repository but git command not available!', file=sys.stderr)
       print('0.{0}.999'.format(api_version))
       sys.exit(-1)

    if args.revision:
       print(ver)
       sys.exit(0)

    if args.commit_hash:
       print(head_commit)
       sys.exit(0)

    if args.package_version:
       print('0.{0}.{1}'.format(api_version, ver))
       sys.exit(0)

    # print everything
    print('0.{0}.{1} {2}'.format(api_version, ver, head_commit))
