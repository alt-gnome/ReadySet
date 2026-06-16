plugin_test_pretty_name = 'Tests Pageless'
plugin_test_name = 'tests-pageless'

plugin_test_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w',
  '-DG_LOG_DOMAIN="TestsPageless"',
]

shared_module(
  plugin_test_name,
  'plugin.vala',
  dependencies: librs_dep,
  c_args: plugin_test_c_args,
  install: get_option('install_tests'),
  install_dir: steps_plugins_dir
)

configure_file(
  input: 'data/plugin.in',
  output: plugin_test_name + '.plugin',
  configuration: {
    'NAME': plugin_test_pretty_name,
    'MODULE': plugin_test_name,
    'VERSION': meson.project_version(),
  },
  install: get_option('install_tests'),
  install_dir: steps_plugins_dir,
)
