plugin_welcome_blueprints = files(
  'ui/page.blp',
)

plugin_welcome_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Welcome.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_welcome_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_welcome_name + '.plugin',

  configuration: {
    'NAME': plugin_welcome_pretty_name,
    'MODULE': plugin_welcome_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
