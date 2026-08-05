plugin_software_service_deps = [
  api_base_dep,
  flatpak_dep,
  librss_dep,
]

plugin_software_service_sources = files(
  'plugin.vala',
) + plugin_software_program_sources

plugin_software_service_pretty_name = 'Software root service'
plugin_software_service_name = 'software-sources'

configure_file(
  input: 'plugin.in',
  output: plugin_software_service_name + '.plugin',

  configuration: {
    'NAME': plugin_software_service_pretty_name,
    'MODULE': plugin_software_service_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: service_plugins_dir
)

plugin_software_service_c_args = [
  '-DG_LOG_DOMAIN="ReadySetSoftware"',
]

shared_module(
  plugin_software_service_name,
  plugin_software_service_sources,
  dependencies: plugin_software_service_deps,
  c_args: plugin_software_service_c_args,
  install: true,
  install_dir: service_plugins_dir
)

install_data(
  'policy',
  install_dir: datadir / 'polkit-1' / 'actions',
  rename: 'org.altlinux.ReadySet.Software.policy'
)
