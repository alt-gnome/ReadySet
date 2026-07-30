resources = gnome.compile_resources(
  'resources',
  'gresource.xml',
  source_dir: meson.current_build_dir(),
)

appstream_file = i18n.merge_file(
  input: 'tuner-plugin.metainfo.xml.in',
  output: tuner_plugin_id + '.metainfo.xml',
  po_dir: meson.project_source_root() / 'po',
  install: true,
  install_dir: get_option('datadir') / 'metainfo'
)

configure_file(
  input: 'plugin.in',
  output: tuner_plugin_name + '.plugin',

  configuration: {
    'NAME': tuner_plugin_pretty_name,
    'MODULE': tuner_plugin_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: get_option('libdir') / 'tuner' / 'plugins'
)
