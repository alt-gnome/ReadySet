blueprints = custom_target('blueprints',
  input: files(
    'ui/base-page-desc.blp',
    'ui/base-page.blp',
    'ui/context-row.blp',
    'ui/end-page.blp',
    'ui/help-overlay.blp',
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
    'ui/test-page.blp',
    'ui/user-page.blp',
    'ui/welcome-page.blp',
    'ui/window-content.blp',
    'ui/window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

resource_files = files('@0@.gresource.xml'.format(app_id))
resources = gnome.compile_resources(
  'ready-set-resources',
  resource_files,
  dependencies: blueprints,
  c_name: 'ready_set'
)
