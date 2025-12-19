plugin_user_blueprints = files(
  'ui/context-row.blp',
  'ui/margin-label.blp',
  'ui/page-password.blp',
  'ui/page-username.blp',
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
