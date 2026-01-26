rs_internal_vapi_sources = files(
  'config.vapi',
)

rs_internal_vala_sources = files(
  'main.vala',
  'service.vala',
  'utils.vala',
)

rs_internal_dependencies = [
  gee_dep,
  gio_dep,
  polkit_dep,
]

rs_internal_sources = [
  rs_internal_vala_sources,
  rs_internal_vapi_sources,
]

rs_internal_c_args = [
  '-w'
]

rs_internal_vala_args = [

]

if get_option('is_devel')
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

subdir('data')
