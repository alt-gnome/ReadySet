plugin_test_deps = [
  librs_dep,
]

plugin_test_sources = files(
  'error-page.vala',
  'page.vala',
  'plugin.vala',
)

plugin_test_pretty_name = 'Tests'
plugin_test_name = 'tests'

subdir('data')

plugin_test_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

shared_module(
  plugin_test_name,
  plugin_test_resources,
  plugin_test_sources,
  dependencies: plugin_test_deps,
  c_args: plugin_test_c_args,
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
