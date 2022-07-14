libavdevice_majorver = '58'
minorver = '10'
microver = '100'

libavdevice_version = libavdevice_majorver + '.' + minorver + '.' + microver

cc = meson.get_compiler('c')

libavdevice_headers = files(
  'avdevice.h',
)

#### --- GENERATED --- ####

libavdevice_sources = files(
  'alldevices.c',
  'avdevice.c',
  'utils.c',
  'file_open.c',
)

libavdevice_optional_sources = {
  'alsa_indev' : files('alsa_dec.c','alsa.c','timefilter.c'),
  'alsa_outdev' : files('alsa_enc.c','alsa.c'),
  'android_camera_indev' : files('android_camera.c'),
  'avfoundation_indev' : files('avfoundation.m'),
  'bktr_indev' : files('bktr.c'),
  'caca_outdev' : files('caca.c'),
  'decklink_indev' : files('decklink_dec.cpp','decklink_dec_c.c','decklink_common.cpp'),
  'decklink_outdev' : files('decklink_enc.cpp','decklink_enc_c.c','decklink_common.cpp'),
  'dshow_indev' : files('dshow_crossbar.c','dshow.c','dshow_enummediatypes.c','dshow_enumpins.c','dshow_filter.c','dshow_pin.c','dshow_common.c'),
  'fbdev_indev' : files('fbdev_dec.c','fbdev_common.c'),
  'fbdev_outdev' : files('fbdev_enc.c','fbdev_common.c'),
  'gdigrab_indev' : files('gdigrab.c'),
  'iec61883_indev' : files('iec61883.c'),
  'jack_indev' : files('jack.c','timefilter.c'),
  'kmsgrab_indev' : files('kmsgrab.c'),
  'lavfi_indev' : files('lavfi.c'),
  'libcdio_indev' : files('libcdio.c'),
  'libdc1394_indev' : files('libdc1394.c'),
  'openal_indev' : files('openal-dec.c'),
  'opengl_outdev' : files('opengl_enc.c'),
  'oss_indev' : files('oss_dec.c','oss.c'),
  'oss_outdev' : files('oss_enc.c','oss.c'),
  'pulse_indev' : files('pulse_audio_dec.c','pulse_audio_common.c','timefilter.c'),
  'pulse_outdev' : files('pulse_audio_enc.c','pulse_audio_common.c'),
  'sdl2_outdev' : files('sdl2.c'),
  'shared' : files('reverse.c'),
  'sndio_indev' : files('sndio_dec.c','sndio.c'),
  'sndio_outdev' : files('sndio_enc.c','sndio.c'),
  'v4l2_indev' : files('v4l2.c','v4l2-common.c','timefilter.c'),
  'v4l2_outdev' : files('v4l2enc.c','v4l2-common.c'),
  'vfwcap_indev' : files('vfwcap.c'),
  'xcbgrab_indev' : files('xcbgrab.c'),
  'xv_outdev' : files('xv.c'),
}

libavdevice_x86asm_optional_sources = {
}

libavdevice_mmx_optional_sources = {
}

libavdevice_optional_tests = {
  'jack_indev' : [
    ['timefilter', files('tests/timefilter.c')],
  ],
}

languages_map += {
  'avfoundation_indev': ['objc'],
  'decklink_outdev': ['cpp'],
  'decklink_indev': ['cpp'],
}
#### --- END GENERATED --- ####

# Version file
ver_conf = configuration_data()
ver_conf.set('majorver', libavdevice_majorver)
ver_conf.set('minorver', minorver)
ver_conf.set('microver', microver)

configure_file(
  input: 'version.h.in',
  output: 'version.h',
  configuration: ver_conf,
  install_dir: join_paths(get_option('includedir'), 'libavdevice'),
  install: true,
)

install_headers(libavdevice_headers, subdir: 'libavdevice')

configure_file(
  input: 'libavdevice.v.in',
  output: 'libavdevice.ver',
  configuration: ver_conf,
)
