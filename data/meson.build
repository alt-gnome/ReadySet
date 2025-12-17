rs_app_blueprints = custom_target('blueprints',
  input: files(
    'ui/context-row.blp',
    'ui/end-page.blp',
    'ui/input-chooser.blp',
    'ui/input-row.blp',
    'ui/language-page.blp',
    'ui/language-row.blp',
    'ui/keyboard-page.blp',
    'ui/languages-box.blp',
    'ui/margin-label.blp',
    'ui/nothing-to-show.blp',
    'ui/pages-indicator.blp',
    'ui/password-strength.blp',
    'ui/step-row.blp',
    'ui/steps-main-page.blp',
    'ui/steps-sidebar.blp',
    'ui/test-error-page.blp',
    'ui/test-page.blp',
    'ui/user-page.blp',
    'ui/welcome-page.blp',
    'ui/window-content.blp',
    'ui/window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

rs_app_resource_files = files('@0@.gresource.xml'.format(app_id))
rs_app_resources = gnome.compile_resources(
  'ready-set-app-resources',
  rs_app_resource_files,
  dependencies: rs_app_blueprints,
  c_name: 'ready_set_app'
)

rules_conf = configuration_data()
rules_conf.set('USERNAME', get_option('username'))
rules_conf.set('SYSCONFDIR', sysconfdir)

configure_file(
  input: 'org.altlinux.ReadySet.rules.in',
  output: 'org.altlinux.ReadySet.rules',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'polkit-1', 'rules.d'),
  configuration: rules_conf,
)

subdir('icons')
subdir('tools')
