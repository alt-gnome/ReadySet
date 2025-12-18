plugin_is_welcome_deps = [
  librs_dep,
]

plugin_is_welcome_sources = files(
  'page.vala',
  'plugin.vala',
)

plugin_is_welcome_pretty_name = 'Welcome'
plugin_is_welcome_name = 'welcome'

subdir('data')

plugin_is_welcome_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

shared_module(
  plugin_is_welcome_name,
  plugin_is_welcome_resources,
  plugin_is_welcome_sources,
  dependencies: plugin_is_welcome_deps,
  c_args: rs_app_c_args,
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
