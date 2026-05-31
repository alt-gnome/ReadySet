plugin_test_installer_deps = [
  librs_dep,
]

plugin_test_installer_sources = files(
  'plugin.vala',
)

plugin_test_installer_pretty_name = 'Test Installer'
plugin_test_installer_name = 'test-installer'

plugin_test_installer_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w',
  '-DG_LOG_DOMAIN="TestInstaller"',
]

configure_file(
  input: 'plugin.in',
  output: plugin_test_installer_name + '.plugin',

  configuration: {
    'NAME': plugin_test_installer_pretty_name,
    'MODULE': plugin_test_installer_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: installers_plugins_dir
)

shared_module(
  plugin_test_installer_name,
  plugin_test_installer_sources,
  dependencies: plugin_test_installer_deps,
  c_args: plugin_test_installer_c_args,
  install: true,
  install_dir: installers_plugins_dir
)
