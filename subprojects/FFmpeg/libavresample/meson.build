libavresample_majorver = '4'
minorver = '0'
microver = '0'

libavresample_version = libavresample_majorver + '.' + minorver + '.' + microver

cc = meson.get_compiler('c')

libavresample_headers = files(
  'avresample.h',
)

#### --- GENERATED --- ####

libavresample_sources = files(
  'audio_convert.c',
  'audio_data.c',
  'audio_mix.c',
  'audio_mix_matrix.c',
  'dither.c',
  'options.c',
  'resample.c',
  'utils.c',
)

libavresample_optional_sources = {
}

libavresample_x86asm_optional_sources = {
}

libavresample_mmx_optional_sources = {
}

libavresample_tests = [
  ['avresample', files('tests/avresample.c')],
]

libavresample_optional_tests = {
}

#### --- END GENERATED --- ####

# Version file
ver_conf = configuration_data()
ver_conf.set('majorver', libavresample_majorver)
ver_conf.set('minorver', minorver)
ver_conf.set('microver', microver)

configure_file(
  input: 'version.h.in',
  output: 'version.h',
  configuration: ver_conf,
  install_dir: join_paths(get_option('includedir'), 'libavresample'),
  install: true,
)

install_headers(libavresample_headers, subdir: 'libavresample')

configure_file(
  input: 'libavresample.v.in',
  output: 'libavresample.ver',
  configuration: ver_conf,
)

subdir('x86')
