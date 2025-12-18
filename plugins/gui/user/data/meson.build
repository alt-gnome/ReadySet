plugin_user_blueprints = files(
  'ui/context-row.blp',
  'ui/margin-label.blp',
  'ui/page.blp',
  'ui/password-strength.blp',
)

plugin_user_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.User.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_user_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_user_name + '.plugin',

  configuration: {
    'NAME': plugin_user_pretty_name,
    'MODULE': plugin_user_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)
