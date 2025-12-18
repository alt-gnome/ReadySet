plugin_is_language_deps = [
  gio_dep,
  gnome_desktop_dep,
  librs_dep,
  polkit_dep,
]

plugin_is_language_sources = files(
  'box.vala',
  'locale-data.vala',
  'page.vala',
  'plugin.vala',
  'row.vala',
  'select-title.vala',
  'utils.vala',
)

plugin_is_language_pretty_name = 'Language'
plugin_is_language_name = 'language'

subdir('data')

plugin_is_language_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

shared_module(
  plugin_is_language_name,
  plugin_is_language_resources,
  plugin_is_language_sources,
  dependencies: plugin_is_language_deps,
  c_args: rs_app_c_args,
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
