project('libdv', 'c', version: '1.0.0',
  meson_version: '>= 0.53',
  default_options: ['buildtype=debugoptimized'])

soversion = '4'
libversion = '4.0.3'

cc = meson.get_compiler('c')

# to enable GNU extensions of glibc, notably large file support
add_project_arguments('-D_GNU_SOURCE', '-DHAVE_CONFIG_H', language: 'c')

# so MSVC defines M_PI etc.
if cc.get_id() == 'msvc'
  add_project_arguments('-D_USE_MATH_DEFINES', language: 'c')
endif

extra_cargs = cc.get_supported_arguments([
  '-Werror=attributes',
  '-Wno-unused-function',
  '-Wno-unused-variable',
  '-Wno-unused-but-set-variable',
  '-Wno-pointer-sign',
])

add_project_arguments(extra_cargs, language: 'c')

cfg_summary = {}

cdata = configuration_data()

config_inc = include_directories('.')

cdata.set10('DEBUG', get_option('debug'))

cdata.set_quoted('VERSION', meson.project_version())

foreach alignment : ['8', '32', '64']
  cdata.set('ALIGN@0@'.format(alignment), 'LIBDV_ALIGN@0@'.format(alignment))
endforeach

cdata.set('__inline__', 'inline') # it being 2020 and all

libm = cc.find_library('m', required: false)

# Don't bother with popt on non-gcc build, because we make heavy use of 
# gcc struct initialization extension in our popt code.  (Could be fixed)
if cc.get_id() == 'gcc'
  popt_dep = dependency('popt', required: get_option('popt'))
  cdata.set10('HAVE_LIBPOPT', popt_dep.found())
else
  assert(not get_option('popt').enabled(), 'popt requested via options but was not found.')
  popt_dep = dependency('', required: false)
endif

if get_option('yuv-format') == 'YV12'
  cdata.set10('YUV_420_USE_YV12', true)
endif
cfg_summary += {'YUV format': get_option('yuv-format')}

threads_dep = dependency('threads')

check_headers = [
  'dlfcn.h',
  'fcntl.h',
  'unistd.h',
  'inttypes.h',
  'memory.h',
  'stdint.h',
  'stdlib.h',
  'string.h',
  'strings.h',
  'sys/param.h',
  'sys/stat.h',
  'sys/types.h',
  'sys/time.h',
  'linux/videodev.h',
  'sys/soundcard.h',
]

foreach h : check_headers
  cdata.set10('HAVE_@0@'.format(h.underscorify().to_upper()), cc.has_header(h))
endforeach

cdata.set10('STDC_HEADERS', true)

check_funcs = ['mmap', 'gettimeofday', 'getpagesize', 'sched_setscheduler', 'localtime_r']
foreach f : check_funcs
  cdata.set10('HAVE_@0@'.format(f.underscorify().to_upper()), cc.has_function(f))
endforeach

# This is an inline function on windows and needs the time.h header to be detected
cdata.set10('HAVE_LOCALTIME_S', cc.has_function('localtime_s', prefix: '#include <time.h>'))

cdata.set('HAVE_ATTRIBUTE_DESTRUCTOR', cc.has_function_attribute('destructor'))

cdata.set10('DV_IS_BIG_ENDIAN', host_machine.endian() == 'big')
cdata.set10('DV_IS_LITTLE_ENDIAN', host_machine.endian() == 'little')

# need to define these if needed
#assert(cc.has_type('off_t'))
#assert(cc.has_type('size_t'))

subdir('libdv')

if not get_option('tools').disabled()
  if cdata.get('HAVE_UNISTD_H') == 1
    # TODO: subdir('playdv')
    subdir('encodedv')
  elif get_option('tools').enabled()
    error('Tools required via options but are not buildable on this platform.')
  endif
endif

configure_file(output: 'config.h', configuration: cdata)

summary(cfg_summary, bool_yn: true)
