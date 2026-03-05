plugin_network_blueprints = files(
  'ui/page.blp',
)

plugin_network_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Network.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_network_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_network_name + '.plugin',

  configuration: {
    'NAME': plugin_network_pretty_name,
    'MODULE': plugin_network_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: steps_plugins_dir
)

install_data(
  files('org.altlinux.ReadySet.Plugin.Network.rules'),
  install_dir: rulesdir,
)
