plugin_user_deps = [
  accountsservice_desktop_dep,
  gnome_desktop_dep,
  librs_dep,
  posix_dep,
  pwquality_dep,
]

plugin_user_sources = files(
  'context-row.vala',
  'margin-label.vala',
  'page.vala',
  'password-strength.vala',
  'plugin.vala',
  'utils.vala',
)

plugin_user_pretty_name = 'User'
plugin_user_name = 'user'

subdir('data')

plugin_user_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
  '-w'
]

plugin_user_vala_args = [
  '--vapidir', meson.current_source_dir() / 'vapi',
]

shared_module(
  plugin_user_name,
  plugin_user_resources,
  plugin_user_sources,
  dependencies: plugin_user_deps,
  c_args: plugin_user_c_args,
  vala_args: plugin_user_vala_args,
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
