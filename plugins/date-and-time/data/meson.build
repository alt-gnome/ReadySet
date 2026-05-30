plugin_date_and_time_blueprints = files(
  'ui/page.blp',
  'ui/date-and-time-selector.blp',
  'ui/timezone-list.blp',
  'ui/infinity-carousel.blp',
)

plugin_date_and_time_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.DateAndTime.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_date_and_time_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
    build_always_stale: true,
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_date_and_time_name + '.plugin',

  configuration: {
    'NAME': plugin_date_and_time_pretty_name,
    'MODULE': plugin_date_and_time_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: steps_plugins_dir
)
