rs_app_vapi_sources = files(
  'config.vapi',
)

rs_app_vala_sources = files(
  'pages/end-page.vala',

  'widgets/devel/window.vala',

  'widgets/nothing-to-show.vala',
  'widgets/pages-indicator.vala',
  'widgets/positioned-stack.vala',
  'widgets/step-row.vala',
  'widgets/steps-main-page.vala',
  'widgets/steps-sidebar.vala',

  'about.vala',
  'application.vala',
  'main.vala',
  'options-handler.vala',
  'pages-model.vala',
  'utils.vala',
  'window-content.vala',
  'window.vala',
)

rs_app_dependencies = [
  gdm_dep,
  gee_dep,
  libadwaita_dep,
  libpeas_dep,
  librs_dep,
]

rs_app_sources = [
  rs_app_vala_sources,
  rs_app_vapi_sources,
  rs_app_resources,
]

rs_app_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

rs_app_vala_args = [
  '--gresources', rs_app_resource_files,
  '--gresourcesdir=data/',
  '--vapidir', meson.project_source_root() / 'vapi',
]

if get_option('is_devel')
  rs_app_vala_args += [
    '--define=DEVEL',
  ]
endif

configure_file(output: 'config.h', configuration: global_conf)
rs_app_config_h_dir = include_directories('.')

executable(
  'ready-set',
  rs_app_sources,
  include_directories: rs_app_config_h_dir,
  dependencies: rs_app_dependencies,
  link_args: ['-lm'],
  c_args: rs_app_c_args,
  vala_args: rs_app_vala_args,
  install: true,
  install_dir: get_option('prefix') / get_option('libexecdir')
)
