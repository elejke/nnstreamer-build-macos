libswresample_majorver = '3'
minorver = '7'
microver = '100'

libswresample_version = libswresample_majorver + '.' + minorver + '.' + microver

libswresample_headers = files(
  'swresample.h',
)

#### --- GENERATED --- ####

libswresample_sources = files(
  'audioconvert.c',
  'dither.c',
  'options.c',
  'rematrix.c',
  'resample.c',
  'resample_dsp.c',
  'swresample.c',
  'swresample_frame.c',
)

libswresample_optional_sources = {
  'libsoxr' : files('soxr_resample.c'),
  'shared' : files('log2_tab.c'),
}

libswresample_x86asm_optional_sources = {
}

libswresample_mmx_optional_sources = {
}

libswresample_tests = [
  ['swresample', files('tests/swresample.c')],
]

libswresample_optional_tests = {
}

#### --- END GENERATED --- ####

# Version file
ver_conf = configuration_data()
ver_conf.set('majorver', libswresample_majorver)
ver_conf.set('minorver', minorver)
ver_conf.set('microver', microver)

configure_file(
  input: 'version.h.in',
  output: 'version.h',
  configuration: ver_conf,
  install_dir: join_paths(get_option('includedir'), 'libswresample'),
  install: true,
)

install_headers(libswresample_headers, subdir: 'libswresample')

configure_file(
  input: 'libswresample.v.in',
  output: 'libswresample.ver',
  configuration: ver_conf,
)

subdir('x86')
