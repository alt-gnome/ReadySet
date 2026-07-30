plugin_software_blueprints = files(
  'ui/page.blp',
)

plugin_software_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Software.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_software_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
    build_always_stale: true,
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_software_name + '.plugin',

  configuration: {
    'NAME': plugin_software_pretty_name,
    'MODULE': plugin_software_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: steps_plugins_dir
)

install_data(
  files('org.altlinux.ReadySet.Plugin.Software.rules'),
  install_dir: rulesdir,
)

install_emptydir(pkgdata_dir / plugin_software_name / 'sources.d')
