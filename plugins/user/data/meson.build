plugin_user_blueprints = files(
  'ui/avatar-chooser.blp',
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

rules_conf = configuration_data()
rules_conf.set('LIBEXECDIR', libexecdir)

configure_file(
  input: 'org.altlinux.ReadySet.Plugin.User.rules.in',
  output: 'org.altlinux.ReadySet.Plugin.User.rules',
  install: true,
  install_dir: rulesdir,
  configuration: rules_conf,
)

subdir('tools')
