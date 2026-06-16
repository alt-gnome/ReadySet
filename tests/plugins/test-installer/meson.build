plugin_test_installer_deps = [
  librs_dep,
]

plugin_test_installer_sources = files(
  'disks-page.vala',
  'plugin.vala',
)

plugin_test_installer_pretty_name = 'Test Installer'
plugin_test_installer_name = 'test-installer'

plugin_test_installer_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w',
  '-DG_LOG_DOMAIN="TestInstaller"',
]

subdir('data')

shared_module(
  plugin_test_installer_name,
  plugin_test_installer_sources + plugin_license_agreement_resources,
  dependencies: plugin_test_installer_deps,
  c_args: plugin_test_installer_c_args,
  install: get_option('install_tests').enabled(),
  install_dir: installers_plugins_dir
)

configure_file(
  input: 'data/plugin.in',
  output: plugin_test_installer_name + '.plugin',
  configuration: {
    'NAME': plugin_test_installer_pretty_name,
    'MODULE': plugin_test_installer_name,
    'VERSION': meson.project_version(),
  },
  install: get_option('install_tests').enabled(),
  install_dir: installers_plugins_dir,
)
