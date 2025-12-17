rs_app_vapi_sources = files(
  'config.vapi',
)

rs_app_vala_sources = files(
  'pages/end/end-page.vala',

  'pages/keyboard/ibus-utils.vala',
  'pages/keyboard/input-chooser.vala',
  'pages/keyboard/input-row.vala',
  'pages/keyboard/keyboard-page.vala',

  'pages/language/lang-select-title.vala',
  'pages/language/language-page.vala',
  'pages/language/language-row.vala',
  'pages/language/languages-box.vala',
  'pages/language/locale-data.vala',

  'pages/test/test-error-page.vala',
  'pages/test/test-page.vala',

  'pages/user/user-page.vala',

  'pages/user-with-root/user-with-root-page.vala',

  'widgets/context-row.vala',
  'widgets/margin-label.vala',
  'widgets/nothing-to-show.vala',
  'widgets/pages-indicator.vala',
  'widgets/password-strength.vala',
  'widgets/positioned-stack.vala',
  'widgets/step-row.vala',
  'widgets/steps-main-page.vala',
  'widgets/steps-sidebar.vala',

  'about.vala',
  'application.vala',
  'data.vala',
  'main.vala',
  'utils-user.vala',
  'utils.vala',
  'window-content.vala',
  'window.vala',
)

rs_app_dependencies = [
  accountsservice_desktop_dep,
  gee_dep,
  gnome_desktop_dep,
  gtk_dep,
  ibus_dep,
  libadwaita_dep,
  libpeas_dep,
  polkit_dep,
  posix_dep,
  pwquality_dep,
  librs_is_dep,
]

rs_app_sources = [
  rs_app_vala_sources,
  rs_app_vapi_sources,
  rs_app_resources,
]

rs_app_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
  '-w'
]

rs_app_vala_args = [
  '--gresources', rs_app_resource_files,
  '--gresourcesdir=data/',
  '--vapidir', meson.current_source_dir() / '..' / 'vapi',
]

if get_option('have_ibus')
  rs_app_c_args += ['-DHAVE_IBUS']
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
