dv_config = configuration_data()

install_headers('dv_types.h', 'dv.h', subdir: 'libdv')

dv_sources = [
  'dv.c',
  'dct.c',
  'idct_248.c',
  'weighting.c',
  'quant.c',
  'vlc.c',
  'place.c',
  'parse.c',
  'bitstream.c',
  'YUY2.c',
  'YV12.c',
  'rgb.c',
  'audio.c',
  'util.c',
  'encode.c',
  'headers.c',
  'enc_input.c',
  'enc_audio_input.c',
  'enc_output.c',
]

testvlc_asm_sources = []

dv_asm_sources_table = {
  'x86': [
    'vlc_x86.S',
    'quant_x86.S',
    'idct_block_mmx.S',
    'dct_block_mmx.S',
    'rgbtoyuv.S',
    'encode_x86.S',
    'transpose_x86.S',
  ],
  'x86_64': [
    'vlc_x86_64.S',
    'quant_x86_64.S',
    'idct_block_mmx_x86_64.S',
    'dct_block_mmx_x86_64.S',
    'rgbtoyuv_x86_64.S',
    'encode_x86_64.S',
    'transpose_x86_64.S',
  ]
}

# x86 / x86_64 assembly support

have_asm = false
cpu_family = host_machine.cpu_family()

if cpu_family in ['x86', 'x86_64'] and cc.get_id() != 'msvc' and not get_option('asm').disabled()
  have_asm = cc.compiles(files('transpose_@0@.S'.format(cpu_family)),
     args: cc.get_supported_arguments(['-Werror']),
     name: '.S assembly file')
endif

if get_option('asm').enabled() and not have_asm
  error('Assembly optimizations were requested, but are not available with this architecture/compiler.')
endif

if have_asm
  cdata.set10('ARCH_@0@'.format(cpu_family.to_upper().underscorify()), true)

  # This is just a sanity check. We might not catch all cases, but then compilation will (hopefully) fail later.
  if cc.get_id() != 'msvc'
    attributes_werror_arg = cc.get_supported_arguments(['-Werror=attributes'])
    if not cc.compiles('typedef struct { char a[64] __attribute__ ((aligned (32))); } b;', args: attributes_werror_arg)
      error('Don\'t know how to align struct members with this compiler, but assembly is enabled which requires proper alignment.')
    endif
  endif

  dv_sources += dv_asm_sources_table[cpu_family]

  testvlc_asm_sources = ['testvlc_@0@.S'.format(cpu_family)]

  asm_structs = [
    ['dv_videosegment_t', ['i', 'k', 'bs', 'mb', 'isPAL']],
    ['dv_macroblock_t', ['b', 'eob_count', 'vlc_error', 'qno', 'sta', 'i', 'j', 'k']],
    ['dv_block_t', ['coeffs', 'dct_mode', 'class_no', 'reorder', 'reorder_sentinel', 'offset', 'end', 'eob', 'mark']],
    ['bitstream_t', ['buf']],
  ]

  asm_defines = [
    'DV_QUALITY_BEST',
    'DV_QUALITY_FASTEST',
    'DV_QUALITY_COLOR',
    'DV_QUALITY_AC_MASK',
    'DV_QUALITY_DC',
    'DV_QUALITY_AC_1',
    'DV_QUALITY_AC_2',
    'DV_WEIGHT_BIAS',
  ]

  asm_check_prefix = '''
    #include <stddef.h>
    #include "libdv/dv.h"
    '''

  # We generate asmoff.h via meson instead of calling the gasmoff tool
  cdata_asm = configuration_data()

  foreach struct : asm_structs
    struct_name = struct[0]
    struct_members = struct[1]

    cdata_asm.set('@0@_size'.format(struct_name),
      cc.sizeof(struct_name, prefix: asm_check_prefix))

    foreach m : struct_members  
      cdata_asm.set('@0@_@1@'.format(struct_name, m),
        cc.compute_int('offsetof(@0@,@1@)'.format(struct_name, m),
                       prefix: asm_check_prefix,
                       high: 8192))
    endforeach
  endforeach

  asmoff_h = configure_file(output: 'asmoff.h', configuration: cdata_asm)
  dv_sources += [asmoff_h]
endif

cfg_summary += {'assembly optimizations': have_asm}

libdv = library('dv', dv_sources,
  include_directories: config_inc,
  dependencies: [popt_dep, threads_dep, libm],
  soversion: soversion,
  version: libversion,
  vs_module_defs: 'libdv.def',
  install: true)

dv_dep = declare_dependency(link_with: libdv,
  include_directories: include_directories('.', '..'))

# we diverge from the autotools build and create a dv_config.h file to
# work around the complete brokeness of the libdv dv_types.h header which
# includes config.h (which might be from the libdv-using application!)
dv_config.set10('LIBDV_HAVE_LIBPOPT', popt_dep.found())

if host_machine.endian() == 'little'
  dv_config.set('LIBDV_LITTLE_ENDIAN_BITFIELD', true)
else
  dv_config.set('LIBDV_BIG_ENDIAN_BITFIELD', true)
endif

dv_config.set10('LIBDV_USING_ASM', have_asm)

configure_file(output: 'dv_config.h', configuration: dv_config,
  install_dir: get_option('includedir') / 'libdv',
  install: true)

# pkg-config file
static_cflags = [] # FIXME
pkg = import('pkgconfig')
pkg.generate(libdv,
  name: 'libdv',
  description: 'DV software codec library',
  extra_cflags: static_cflags)
  
# utilities
if not get_option('utils').disabled() and cc.get_id() != 'msvc'
  foreach util : ['dovlc', 'recode', 'reppm', 'enctest']
    executable(util, '@0@.c'.format(util),
      include_directories: config_inc,
      dependencies: [dv_dep, threads_dep],
      install: false)
  endforeach
elif get_option('utils').enabled()
  error('Utilities required via options but are not buildable on this platform.')
endif

# unit tests
if not get_option('tests').disabled()
  test('bitstream',
    executable('testbitstream', 'testbitstream.c', 'bitstream.c',
      include_directories: config_inc,
      install: false))
  test('vlc',
    executable('testvlc', 'testvlc.c', 'vlc.c', 'bitstream.c', testvlc_asm_sources,
      include_directories: config_inc,
      install: false))
endif
