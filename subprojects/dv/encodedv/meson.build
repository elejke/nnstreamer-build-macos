install_man('encodedv.1', 'dvconnect.1', 'dubdv.1')

executable('encodedv', 'encodedv.c',
  include_directories: config_inc,
  dependencies: [dv_dep, popt_dep],
  install: true)

executable('dvconnect', 'dvconnect.c',
  include_directories: config_inc,
  dependencies: [dv_dep, popt_dep, threads_dep],
  install: true)

executable('dubdv', 'insert_audio.c',
  include_directories: config_inc,
  dependencies: [dv_dep, popt_dep],
  install: true)

# noinst_PROGRAMS
foreach p : ['fix_headers', 'scan_packet_headers', 'steal_header', 'ppmqscale', 'dvavi']
  executable(p, '@0@.c'.format(p),
    include_directories: config_inc,
    dependencies: [dv_dep, popt_dep],
    install: false)
endforeach
