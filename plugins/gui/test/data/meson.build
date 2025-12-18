plugin_is_test_blueprints = files(
  'ui/error-page.blp',
  'ui/page.blp',
)

plugin_is_test_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Test.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_is_test_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_is_test_name + '.plugin',

  configuration: {
    'NAME': plugin_is_test_pretty_name,
    'MODULE': plugin_is_test_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
