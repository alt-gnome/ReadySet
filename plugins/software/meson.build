plugin_software_deps = [
  flatpak_dep,
  librs_dep,
  posix_dep,
]

plugin_software_program_sources = files(
  'program-utils.vala',
)

subdir('service')

plugin_software_common_sources = files(
  'config.vapi',
  'group.vala',
  'source.vala',
  'sources.vala',
  'utils-common.vala',
) + plugin_software_program_sources

plugin_software_sources = files(
  'page.vala',
  'plugin.vala',
  'source-row.vala',
  'utils.vala',
) + plugin_software_common_sources

plugin_software_pretty_name = 'Software'
plugin_software_name = 'software'

plugin_software_c_args = [
  '-DG_LOG_DOMAIN="Software"',
  '-DNEED_CONTEXT',
]

plugin_software_vala_args = [

]

conf_data = configuration_data()
conf_data.set_quoted('READYSET_DATADIR', pkgdata_dir)
conf_data.set_quoted('ARCH', host_machine.cpu_family())

subdir('tools')
subdir('data')
if get_option('with_software_tuner_plugin').enabled()
  subdir('tuner')
endif

configure_file(output: 'config.h', configuration: conf_data)

shared_module(
  plugin_software_name,
  plugin_software_resources,
  plugin_software_sources,
  dependencies: plugin_software_deps,
  c_args: plugin_software_c_args,
  vala_args: plugin_software_vala_args,
  install: true,
  install_dir: steps_plugins_dir
)
