rs_app_vapi_sources = files(
  'config.vapi',
)

rs_app_vala_sources = files(
  'application.vala',
  'main.vala',
  'utils.vala',
)

rs_app_dependencies = [
  librs_dep,
]

rs_app_sources = [
  rs_app_vala_sources,
  rs_app_vapi_sources,
]

rs_app_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

rs_app_vala_args = [

]

if get_option('is_devel')
  rs_app_vala_args += [
    '--define=DEVEL',
  ]
endif

internal_app_id = 'org.altlinux.' + pascal_name + 'Internal'

if get_option('is_devel')
  internal_app_id_dyn = internal_app_id + '.Devel'
else
  internal_app_id_dyn = internal_app_id
endif

internal_config = configuration_data()
internal_config.merge_from(global_conf)
internal_config.set_quoted('APP_ID', internal_app_id)
internal_config.set_quoted('APP_ID_DYN', internal_app_id_dyn)
configure_file(output: 'config.h', configuration: internal_config)
rs_app_config_h_dir = include_directories('.')

executable(
  'ready-set-ruler',
  rs_app_sources,
  include_directories: rs_app_config_h_dir,
  dependencies: rs_app_dependencies,
  c_args: rs_app_c_args,
  vala_args: rs_app_vala_args,
  install: true,
  install_dir: get_option('prefix') / get_option('libexecdir')
)
