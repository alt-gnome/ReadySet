plugin_welcome_deps = [
  librs_dep,
]

plugin_welcome_sources = files(
  'page.vala',
  'plugin.vala',
)

plugin_welcome_pretty_name = 'Welcome'
plugin_welcome_name = 'welcome'

subdir('data')

plugin_welcome_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

shared_module(
  plugin_welcome_name,
  plugin_welcome_resources,
  plugin_welcome_sources,
  dependencies: plugin_welcome_deps,
  c_args: plugin_welcome_c_args,
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
