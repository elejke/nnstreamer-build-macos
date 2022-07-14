project('x264', 'c',
  version: run_command(find_program('version.py'), '--package-version', check: true).stdout().strip(),
  default_options: ['optimization=2'],
  meson_version: '>= 0.52')

x264_ver = meson.project_version()
x264_rev = meson.project_version().split('.')[2]
x264_build = meson.project_version().split('.')[1]
x264_commit = run_command(find_program('version.py'), '--commit-hash', check: true).stdout().strip()

message('build: ' + x264_build)
message('commit: ' + x264_commit)
message('version: ' + x264_ver)
message('revision: ' + x264_rev)

cdata = configuration_data()

cc = meson.get_compiler('c')
host_system = host_machine.system()
host_cpu = host_machine.cpu_family()

libm = cc.find_library('m', required: false)

# Threads. https://github.com/mesonbuild/meson/issues/553
threads = dependency('threads', required: false)
cdata.set10('HAVE_THREAD', threads.found())
cdata.set10('HAVE_BEOSTHREAD', false)
cdata.set10('HAVE_POSIXTHREAD', threads.found() and host_system != 'windows')
cdata.set10('HAVE_WIN32THREAD', threads.found() and host_system == 'windows')

if host_system == 'linux'
  add_project_arguments('-D_GNU_SOURCE', language: 'c')
endif

buildtype = get_option('buildtype')
if buildtype.startswith('debug')
  add_project_arguments('-DDEBUG', language: 'c')
elif buildtype == 'release'
  if cc.get_id() != 'msvc'
    add_project_arguments('-O3', '-ffast-math', language: 'c')
  endif
endif

# Ignore several spurious warnings for things we do a lot in the code.
# If a warning is completely useless and spammy, use '/wdXXXX' to suppress it
# If a warning is harmless but hard to fix, use '/woXXXX' so it's shown once
# NOTE: Only add warnings here if you are sure they're spurious
if cc.get_id() == 'msvc'
  add_project_arguments(
      '/wd4018', # implicit signed/unsigned conversion
      '/wd4146', # unary minus on unsigned (beware INT_MIN)
      '/wd4244', # lossy type conversion (e.g. double -> int)
      '/wd4305', # truncating type conversion (e.g. double -> float)
      language : 'c')
else
  add_project_arguments(cc.get_supported_arguments([
        '-Wno-unused-parameter',
        '-Wno-sign-compare',
        '-Wno-old-style-declaration',
        '-Wunknown-attributes',
        '-Wattributes',
        '-Wignored-attributes',
        '-Wno-maybe-uninitialized',
      ]), language : 'c')
endif

#if cc.has_link_argument('-Wl,-z,relro')
#  add_project_link_arguments('-Wl,-z,relro', language: 'c')
#endif

if cc.has_argument('-fvisibility=hidden')
  add_project_arguments('-fvisibility=hidden', language: 'c')
endif

stack_alignment = 4
if host_cpu == 'x86_64' or host_cpu == 'aarch64'
  stack_alignment = 16
endif

if not cc.compiles('void f (void) { for (int i = 0; i < 9; i++ ); }')
  error('C99 compiler is needed for compilation.')
endif

if (host_cpu == 'x86' or host_cpu == 'x86_64') and cc.compiles('__attribute__((force_align_arg_pointer)) void foo (void) { }', name: 'force_align_arg_pointer func attribute')
  if cc.get_id() == 'gcc'
    if cc.has_argument('-mpreferred-stack-boundary=6')
      add_project_arguments('-mpreferred-stack-boundary=6', language: 'c')
      stack_alignment = 64
    elif cc.has_argument('-mstack-alignment=64')
      add_project_arguments('-mstack-alignment=64', language: 'c')
      stack_alignment = 64
    elif stack_alignment < 16
      if cc.has_argument('-mpreferred-stack-boundary=4')
        add_project_arguments('-mpreferred-stack-boundary=4', language: 'c')
        stack_alignment = 16
      elif cc.has_argument('-mpreferred-stack-boundary=16')
        add_project_arguments('-mpreferred-stack-boundary=16', language: 'c')
        stack_alignment = 16
      endif
    endif
  elif cc.get_id() == 'intel' #and host_cpu == 'x86'
    error('FIXME: intel compiler stack alignment')
  endif
endif

opt_bitdepth = get_option('bit-depth')
have_bitdepth8 = opt_bitdepth == 'all' or opt_bitdepth == '8'
have_bitdepth10 = opt_bitdepth == 'all' or opt_bitdepth == '10'
cdata.set10('HAVE_BITDEPTH8', have_bitdepth8)
cdata.set10('HAVE_BITDEPTH10', have_bitdepth10)

depths = []
if have_bitdepth8
  depths += [8]
endif
if have_bitdepth10
  depths += [10]
endif

have_x86_inline_asm = false
have_mmx = false

# FIXME: nasm path needs testing on non-Linux, esp. Windows
if host_cpu == 'x86' or host_cpu == 'x86_64'
  nasm = find_program('nasm', native: true, required: get_option('asm'))
  # TODO: make sure nasm is >= 2.13
  if nasm.found() and not get_option('asm').disabled()
    if cc.compiles('__asm__("pabsw %xmm0, %xmm0");',
                   name: 'Compiler supports gcc-style inline assembly')
      have_x86_inline_asm = true
    endif
    have_mmx = true
  endif
else
  nasm = disabler()
endif

asm_gen_objs = []
if nasm.found()
  if host_system == 'windows'
    outputname = '@BASENAME@.obj'
  else
    outputname = '@BASENAME@.o'
  endif

  if get_option('b_staticpic')
    asm_pic_def = '-DPIC'
  else
    asm_pic_def = '-UPIC'
  endif

  # Assembly has to be told when the symbols have to be prefixed with _
  if cc.symbols_have_underscore_prefix()
    asm_prefix_def = '-DPREFIX'
  else
    asm_prefix_def = '-UPREFIX'
  endif

  if host_cpu == 'x86' or host_cpu == 'x86_64'
    if host_cpu == 'x86'
      asm_arch_def = '-DARCH_X86_64=0'
      if host_system == 'windows'
        asm_outformat = 'win32'
      elif host_system == 'darwin'
        asm_outformat = 'macho32'
      elif host_system.endswith('bsd')
        asm_outformat = 'aoutb'
      else
        asm_outformat = 'elf32'
      endif
      asm_x = files('common/x86/dct-32.asm',
                    'common/x86/pixel-32.asm')
    elif host_cpu == 'x86_64'
      asm_arch_def = '-DARCH_X86_64=1'
      if host_system == 'windows'
        asm_outformat = 'win64'
      elif host_system == 'darwin'
        asm_outformat = 'macho64'
      elif host_system.endswith('bsd')
        asm_outformat = 'aoutb'
      else
        asm_outformat = 'elf64'
      endif
      asm_x = files('common/x86/dct-64.asm',
                    'common/x86/trellis-64.asm')
    endif

    asm_x += files('common/x86/bitstream-a.asm',
                   'common/x86/const-a.asm',
                   'common/x86/cabac-a.asm',
                   'common/x86/dct-a.asm',
                   'common/x86/deblock-a.asm',
                   'common/x86/mc-a.asm',
                   'common/x86/mc-a2.asm',
                   'common/x86/pixel-a.asm',
                   'common/x86/predict-a.asm',
                   'common/x86/quant-a.asm')
  endif

  asm_stackalign_def = '-DSTACK_ALIGNMENT=@0@'.format(stack_alignment)
  asm_incdir = 'x86' # FIXME

  foreach d : depths
    asm_gen = generator(nasm,
      output: outputname,
      arguments: ['-I@CURRENT_SOURCE_DIR@',
                  '-I@CURRENT_SOURCE_DIR@/common/@0@/'.format(asm_incdir),
                  asm_arch_def,
                  asm_stackalign_def,
                  '-f', asm_outformat,
                  '-o', '@OUTPUT@',
                  '@INPUT@',
                  '-DHIGH_BIT_DEPTH=@0@'.format((d > 8).to_int()),
                  '-DBIT_DEPTH=@0@'.format(d),
                  asm_pic_def,
                  asm_prefix_def,
                  '-Dprivate_prefix=x264_@0@'.format(d)])
    asm_genx_objs = [asm_gen.process(asm_x)]
    # These two are high and low bit-depth in separate files instead of in the
    # same file and selected with -DBIT_DEPTH
    if d == 8
      asm_genx_objs += asm_gen.process('common/x86/sad-a.asm')
    endif
    if d == 10
      asm_genx_objs += asm_gen.process('common/x86/sad16-a.asm')
    endif
    set_variable('asm_gen@0@_objs'.format(d), asm_genx_objs)
  endforeach

  asm_gen = generator(nasm,
    output: outputname,
    arguments: ['-I@CURRENT_SOURCE_DIR@',
                '-I@CURRENT_SOURCE_DIR@/common/@0@/'.format(asm_incdir),
                asm_arch_def,
                asm_stackalign_def,
                asm_pic_def,
                asm_prefix_def,
                '-f', asm_outformat,
                '-o', '@OUTPUT@',
                '@INPUT@'])
  asm_gen_objs = asm_gen.process('common/x86/cpu-a.asm')
endif

config_mak='''
CFLAGS=-Wno-maybe-uninitialized -Wshadow -Wall -std=gnu99 -fomit-frame-pointer -fno-tree-vectorize
'''

cdata.set10('HAVE_MALLOC_H', cc.has_header('malloc.h') and cc.has_function('memalign'))
cdata.set10('HAVE_STRING_H', cc.has_header('string.h')) # getopt.c
cdata.set10('HAVE_X86_INLINE_ASM', have_x86_inline_asm)
cdata.set10('HAVE_MMX', have_mmx)
cdata.set10('ARCH_X86_64', host_cpu == 'x86_64')
cdata.set10('ARCH_X86', host_cpu == 'x86')
cdata.set('STACK_ALIGNMENT', stack_alignment)
cdata.set10('HAVE_CPU_COUNT',
  cc.has_header_symbol('sched.h', 'CPU_COUNT', args: '-D_GNU_SOURCE'))
cdata.set10('HAVE_LOG2F',
  cc.has_function('log2f', dependencies: libm))
cdata.set10('HAVE_STRTOK_R',
  cc.has_function('strtok_r'))
cdata.set10('HAVE_CLOCK_GETTIME',
  cc.has_function('clock_gettime'))
cdata.set10('HAVE_MMAP', host_system != 'windows'
  and cc.has_header_symbol('sys/mman.h', 'MAP_PRIVATE'))
cdata.set10('HAVE_THP', host_system == 'linux'
  and (host_cpu == 'x86' or host_cpu == 'x86_64')
  and cc.has_header_symbol('sys/mman.h', 'MADV_HUGEPAGE'))

if cc.has_function('fseeko')
  cdata.set('fseek', 'fseeko')
  cdata.set('ftell', 'ftello')
elif cc.has_function('fseeko64')
  cdata.set('fseek', 'fseeko64')
  cdata.set('ftell', 'ftello64')
elif cc.has_function('_fseeki64')
  cdata.set('fseek', '_fseeki64')
  cdata.set('ftell', '_ftelli64')
endif

if host_system == 'bsd' # one to rule them all apparently
  cdata.set10('SYS_FREEBSD', true)
elif host_system == 'darwin'
  cdata.set10('SYS_MACOSX', true)
elif host_system == 'sunos' or host_system == 'solaris'
  cdata.set10('SYS_SunOS', true)
else
  cdata.set10('SYS_' + host_system.to_upper(), true)
endif

if host_system == 'windows'
  ret = cc.compiles('''#include <winapifamily.h>
    #if !WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP)
    #error "not winrt"
    #endif''', name: 'checking if building for WinRT')
  cdata.set10('HAVE_WINRT', ret)
endif

swscale_deps = []
lavf_deps = []
ffms_deps = []
gpac_deps = []
lsmash_deps = []

have_avs = false
use_avxsynth = false
have_swscale = false
have_lavf = false
have_ffms = false
have_gpac = false
have_lsmash = false

if get_option('cli')
  # avs
  if host_system == 'linux' or host_system == 'darwin'
    dl_dep = cc.find_library('dl', required: get_option('avs'))
    have_avs = dl_dep.found()
    avs_deps = [dl_dep]
    use_avxsynth = true
  elif host_system == 'windows'
    # FIXME
  endif

  # swscale
  swscale_dep = dependency('libswscale', required: get_option('swscale'),
                           fallback: ['FFmpeg', 'libswscale_dep'])
  avutil_dep = dependency('libavutil', required: get_option('swscale'),
                          fallback: ['FFmpeg', 'libavutil_dep'])
  have_swscale = swscale_dep.found() and avutil_dep.found()
  swscale_deps = [swscale_dep, avutil_dep]

  # lavf
  avformat_dep = dependency('libavformat', required: get_option('lavf'),
                            fallback: ['FFmpeg', 'libavformat_dep'])
  avcodec_dep = dependency('libavcodec', required: get_option('lavf'),
                            fallback: ['FFmpeg', 'libavcodec_dep'])
  avutil_dep = dependency('libavutil', required: get_option('lavf'),
                            fallback: ['FFmpeg', 'libavutil_dep'])
  have_lavf = avformat_dep.found() and avcodec_dep.found() and avutil_dep.found()
  lavf_deps = [avformat_dep, avcodec_dep, avutil_dep]

  have_lsmash = not get_option('lsmash').disabled()

  # ffms
  ffms_dep = dependency('ffms2', version: '>= 2.21.0', required: get_option('ffms'))
  swscale_dep = dependency('libswscale', required: get_option('ffms'),
                           fallback: ['FFmpeg', 'libswscale_dep'])
  have_ffms = ffms_dep.found() and swscale_dep.found()
  ffms_deps = [ffms_dep, swscale_dep]

  # gpac
  if not get_option('gpac').disabled()
    if cc.has_header('gpac/isomedia.h')
      gpac_lib = cc.find_library('gpac', required: get_option('gpac'))
      have_gpac = gpac_lib.found()
      gpac_deps = [gpac_lib]
    endif
  endif

  # lsmash
  lsmash_dep = dependency('liblsmash', required: get_option('lsmash'))
  have_lsmash = lsmash_dep.found()
  lsmash_deps = [lsmash_dep]
endif

cdata.set10('HAVE_SWSCALE', have_swscale)
cdata.set10('HAVE_LAVF', have_lavf)
cdata.set10('HAVE_AVS', have_avs)
cdata.set10('USE_AVXSYNTH', use_avxsynth)
cdata.set10('HAVE_VECTOREXT', true) # FIXME
cdata.set10('HAVE_GPL', true) # FIXME
cdata.set10('HAVE_INTERLACED', true) # FIXME
cdata.set10('HAVE_OPENCL', false)#'(BIT_DEPTH==8)') # FIXME
cdata.set10('HAVE_ALTIVEC', false) # FIXME
cdata.set10('HAVE_ALTIVEC_H', false) # FIXME
cdata.set10('HAVE_ARMV6', false) # FIXME
cdata.set10('HAVE_ARMV6T2', false) # FIXME
cdata.set10('HAVE_AARCH64', false) # FIXME
cdata.set10('HAVE_NEON', false) # FIXME
cdata.set10('HAVE_FFMS', have_ffms)
cdata.set10('HAVE_GPAC', have_gpac)
cdata.set10('HAVE_LSMASH', have_lsmash)
cdata.set10('HAVE_AS_FUNC', false) # FIXME
cdata.set10('HAVE_INTEL_DISPATCHER', false) # FIXME
cdata.set10('HAVE_MSA', false) # FIXME
cdata.set10('HAVE_VSX', false) # FIXME
cdata.set10('HAVE_ARM_INLINE_ASM', false) # FIXME

# write config.h
configure_file(output : 'config.h', configuration : cdata)

# x264_config.h
x264_config = configuration_data()
x264_config.set('X264_BIT_DEPTH', depths[0])
x264_config.set('X264_GPL', cdata.get('HAVE_GPL'))
x264_config.set('X264_INTERLACED', cdata.get('HAVE_INTERLACED'))
x264_config.set_quoted('X264_VERSION', ' r@0@ @1@'.format(x264_rev, x264_commit))
x264_config.set_quoted('X264_POINTVER', x264_ver)

chroma_format_opt = get_option('chroma-format')
if chroma_format_opt == 'all'
  x264_config.set('X264_CHROMA_FORMAT', 0)
else
  x264_config.set('X264_CHROMA_FORMAT', 'X264_CSP_I' + chroma_format_opt)
endif

configure_file(output : 'x264_config.h',
  configuration : x264_config,
  install_dir: get_option('includedir'))
install_headers('x264.h')

configinc = include_directories('.')

# Depth-agnostic sources
sources = [
  'common/osdep.c',
  'common/base.c',
  'common/cpu.c',
  'common/tables.c',
  'encoder/api.c',
]

# These need to be compiled once for each bit depth
sources_x = [
  'common/mc.c',
  'common/predict.c',
  'common/pixel.c',
  'common/macroblock.c',
  'common/frame.c',
  'common/dct.c',
  'common/cabac.c',
  'common/common.c',
  'common/rectangle.c',
  'common/set.c',
  'common/quant.c',
  'common/deblock.c',
  'common/vlc.c',
  'common/mvpred.c',
  'common/bitstream.c',
  'encoder/analyse.c',
  'encoder/me.c',
  'encoder/ratecontrol.c',
  'encoder/set.c',
  'encoder/macroblock.c',
  'encoder/cabac.c',
  'encoder/cavlc.c',
  'encoder/encoder.c',
  'encoder/lookahead.c',
]

if ['x86', 'x86_64'].contains(host_cpu) and nasm.found()
  sources_x += [
    'common/x86/mc-c.c',
    'common/x86/predict-c.c',
  ]
endif

cli_incs = []

# Depth-agnostic cli sources
cli_sources = [
  'x264.c',
  'autocomplete.c',
  'input/input.c',
  'input/timecode.c',
  'input/raw.c',
  'input/y4m.c',
  'output/raw.c',
  'output/matroska.c',
  'output/matroska_ebml.c',
  'output/flv.c',
  'output/flv_bytestream.c',
  'filters/filters.c',
  'filters/video/video.c',
  'filters/video/source.c',
  'filters/video/internal.c',
  'filters/video/resize.c',
  'filters/video/fix_vfr_pts.c',
  'filters/video/select_every.c',
  'filters/video/crop.c'
]

# These need to be compiled once for each bit depth
cli_sources_x = [
  'filters/video/cache.c',
  'filters/video/depth.c',
]

# Optional module sources
if threads.found()
  sources_x += ['common/threadpool.c']
  cli_sources_x += ['input/thread.c']

  if host_system == 'windows'
    sources += ['common/win32thread.c']
  endif
endif

# GPL-only files
if get_option('gpl')
  cli_sources += []
endif

# Optional module sources
cli_deps = []
if have_avs
  cli_sources += ['input/avs.c']
  cli_deps += avs_deps
endif

if have_swscale
  cli_deps += swscale_deps
endif

if have_lavf
  cli_sources += ['input/lavf.c']
  cli_deps += lavf_deps
endif

if have_ffms
  cli_sources += ['input/ffms.c']
  cli_deps += ffms_deps
endif

if have_gpac
  cli_sources += ['output/mp4.c']
  cli_deps += gpac_deps
endif

if have_lsmash
  cli_sources += ['output/mp4_lsmash.c']
  cli_deps += lsmash_deps
endif

win_res_objs = []
if host_system == 'windows'
  win = import('windows')
  win_res_objs = win.compile_resources('x264res.rc',
      include_directories: configinc)
endif

if not cc.has_function('getopt_long') or not cc.has_header('getopt.h')
  cli_sources += ['extras/getopt.c']
  cli_incs = include_directories('extras')
endif

# x264 lib

bsymbolic_args = []
sym_export_args = []
sym_import_args = []
default_library = get_option('default_library')
if default_library != 'static'
  if cc.get_id() != 'msvc'
    bsymbolic_args = cc.get_supported_link_arguments('-Wl,-Bsymbolic')
  endif
  sym_export_args = ['-DX264_API_EXPORTS']
  sym_import_args = ['-DX264_API_IMPORTS']
endif

x_libs = []
foreach depth : depths
  high_bit_depth = depth > 8 ? 1 : 0
  if nasm.found()
    asm_genx_objs = get_variable('asm_gen@0@_objs'.format(depth))
  else
    asm_genx_objs = []
  endif
  x_libs += static_library('x264-@0@'.format(depth), sources_x, asm_genx_objs,
    c_args: ['-DHIGH_BIT_DEPTH=@0@'.format(high_bit_depth),
             '-DBIT_DEPTH=@0@'.format(depth)] + sym_export_args,
    dependencies: [threads, libm],
    install: false)
endforeach

libx264 = library('x264',
  sources, asm_gen_objs, win_res_objs,
  c_args: sym_export_args,
  version: x264_build,
  dependencies: [threads, libm],
  link_whole: x_libs,
  link_args: bsymbolic_args,
  install: true)

libx264_dep = declare_dependency(link_with: libx264,
                                 compile_args: sym_import_args,
                                 include_directories: configinc)

pkgconfig = import('pkgconfig')
pkgconfig.generate(libx264,
  extra_cflags: sym_import_args,
  version: x264_ver.split('+')[0],
  description: 'H.264 (MPEG4 AVC) encoder library')

# x264 command line interface

if get_option('cli')
  cli_x_libs = []
  foreach depth : depths
    high_bit_depth = depth > 8 ? 1 : 0
    cli_x_libs += static_library('cli-@0@'.format(depth), cli_sources_x,
      c_args: ['-DHIGH_BIT_DEPTH=@0@'.format(high_bit_depth),
               '-DBIT_DEPTH=@0@'.format(depth)],
      install: false)
  endforeach

  x264_cli = executable('x264',
    cli_sources,
    c_args: ['-DHAVE_STRING_H'], # for getopt.c
    include_directories: cli_incs,
    dependencies: [libx264_dep, threads, libm, cli_deps],
    link_with: [cli_x_libs],
    install: true)

  # Hack for build target aliases
  python3 = import('python').find_installation()
  run_target('cli', command: [python3, '-c', 'exit'], depends: x264_cli)

  # install tools/bash-autocomplete.sh somewhere? (x264 build doesn't)
endif

executable('example', 'example.c',
  dependencies: [libx264_dep, threads, libm],
  install: false)

# and another time but link against static lib, if both are built
if default_library == 'both'
  executable('example-static', 'example.c',
    dependencies: [threads, libm],
    link_with: libx264.get_static_lib(),
    install: false)
endif