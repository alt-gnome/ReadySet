src_sources_dir = meson.current_source_dir()

rs_app_vapi_sources = files(
  'config.vapi',
)

plugin_manager_sources = files(
  'plugin-manager.vala',
)

rs_app_vala_sources = files(
  'completions/bash.vala',

  'dbus/osk.vala',
  'dbus/rs-system-service.vala',

  'pages/end-page.vala',
  'pages/existing-user-end-page.vala',

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
  'plugin-manager.vala',
  'utils.vala',
  'window-content.vala',
  'window.vala',
)

rs_app_dependencies = [
  gee_dep,
  libadwaita_dep,
  libpeas_dep,
  posix_dep,
] + librs_dependencies

if gdm_dep.found()
  rs_app_dependencies += gdm_dep
endif

rs_app_sources = [
  rs_app_vala_sources,
  rs_app_vapi_sources,
  rs_app_resources,
] + librs_sources

rs_app_c_args = [
  '-DG_LOG_DOMAIN="ReadySet"',
]

rs_app_vala_args = [
  '--gresources', rs_app_resource_files,
  '--gresourcesdir=data/',
  '--gresources', librs_resource_files,
  '--gresourcesdir=lib/data/',
  '--vapidir', meson.project_source_root() / 'vapi',
  '--pkg', 'linux',
]

if get_option('nightly')
  rs_app_vala_args += [
    '--define=DEVEL',
  ]
endif

if gdm_dep.found()
  rs_app_vala_args += [
    '--define=WITH_GDM',
  ]
endif

configure_file(output: 'config.h', configuration: global_conf)
rs_app_config_h_dir = include_directories('.')

executable(
  'ready-set',
  rs_app_sources,
  include_directories: [
    rs_app_config_h_dir,
    '../lib/src',
  ],
  dependencies: rs_app_dependencies,
  link_args: ['-lm'],
  c_args: rs_app_c_args,
  vala_args: rs_app_vala_args,
  install: true,
  install_dir: get_option('prefix') / get_option('libexecdir')
)
