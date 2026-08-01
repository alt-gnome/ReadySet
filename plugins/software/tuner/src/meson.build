deps = [
  flatpak_dep,
  libserialize_dep,
  tuner_dep,
]

sources = files(
  'objects/apm-repo.vala',
  'objects/stplr-repo.vala',

  'page.vala',
  'plugin.vala',
  'source-binding.vala',
  'source-tuner.vala',
) + plugin_software_common_sources

tuner_plugin_c_args = [
  '-DG_LOG_DOMAIN="ReadySet-Software-Tuner"',
  '-DGETTEXT_PACKAGE="@0@"'.format(tuner_plugin_name),
]

tuner_plugin_vala_args = [

]

configure_file(output: 'config.h', configuration: conf_data)

shared_module(
  tuner_plugin_name, 
  resources,
  sources,
  dependencies: deps,
  install: true,
  c_args: tuner_plugin_c_args,
  vala_args: tuner_plugin_vala_args,
  install_dir: get_option('libdir') / 'tuner' / 'plugins'
)
