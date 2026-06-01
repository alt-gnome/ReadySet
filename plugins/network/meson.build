plugin_network_deps = [
  librs_dep,
  network_manager_dep,
  # network_manager_gtk4_dep,
]

plugin_network_sources = files(
  'page.vala',
  'plugin.vala',
  'utils.vala',
)

plugin_network_pretty_name = 'Network'
plugin_network_name = 'network'

subdir('data')

plugin_network_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w'
]

shared_module(
  plugin_network_name,
  plugin_network_resources,
  plugin_network_sources,
  dependencies: plugin_network_deps,
  c_args: plugin_network_c_args,
  install: true,
  install_dir: steps_plugins_dir
)
