# FIXME: requires Gtk+ and an ancient version at that, needs more work.
# Apparently works with gtk2 though.
'''
gtk_dep = dependency('gtk+-x11-2.0', required: get_option('gtk'))

sdl_dep = dependency('sdl2', version: '>= 1.1.6', required: get_option('sdl'))

xv_dep = dependency('xv', required: get_option('xv'))

cdata.set10('HAVE_GTK', gtk_dep.found())
cdata.set10('HAVE_SDL', sdl_dep.found())
cdata.set10('HAVE_LIBXV', xv_dep.found())

if not gtk_dep.found()
  message('playdv needs GTK+ 2.x')
  subdir_done()
endif

executable('playdv', 'playdv.c', 'display.c', 'oss.c',
  include_directories: config_inc,
  dependencies: [dv_dep, sdl_dep, gtk_dep, xv_dep, popt_dep, dependency('x11'), dependency('xshm')],
  install: true)

if not popt_dep.found()
  warning('playdv needs the popt package for command line parsing.')
endif

install_man('playdv.1')
'''
