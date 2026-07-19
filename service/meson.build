rs_internal_vapi_sources = files(
  'config.vapi',
)

hooks_sources = files(
  'hooks.vala',
)

rs_internal_vala_sources = files(
  'copy-to-user.vala',
  'main.vala',
  'polkit.vala',
  'service.vala',
) + hooks_sources

rs_internal_dependencies = [
  gee_dep,
  gio_dep,
  polkit_dep,
  posix_dep,
]

rs_internal_sources = [
  rs_internal_vala_sources,
  rs_internal_vapi_sources,
]

rs_internal_c_args = [
  '-w'
]

rs_internal_vala_args = [
  '--define=FOR_SERVICE',
]

if get_option('nightly')
  rs_internal_vala_args += [
    '--define=DEVEL',
  ]
endif

configure_file(output: 'config.h', configuration: global_conf)
rs_internal_config_h_dir = include_directories('.')

executable(
  app_id,
  rs_internal_sources,
  include_directories: rs_internal_config_h_dir,
  dependencies: rs_internal_dependencies,
  c_args: rs_internal_c_args,
  vala_args: rs_internal_vala_args,
  install: true,
  install_dir: libexecdir
)

service_sources = meson.current_source_dir()

subdir('data')
