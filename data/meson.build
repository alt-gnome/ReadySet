rs_app_blueprints = custom_target('blueprints',
  input: files(
    'ui/devel-add-context-dialog.blp',
    'ui/devel-window.blp',
    'ui/end-page.blp',
    'ui/nothing-to-show.blp',
    'ui/pages-indicator.blp',
    'ui/step-row.blp',
    'ui/steps-main-page.blp',
    'ui/steps-sidebar.blp',
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

systemd = dependency('systemd')
systemd_sysusers_dir = systemd.get_variable(pkgconfig: 'sysusers_dir')
systemd_tmpfiles_dir = systemd.get_variable(pkgconfig: 'tmpfiles_dir')

install_data(
  files(meson.project_name() + '-sysusers.conf'),
  install_dir: systemd_sysusers_dir,
  rename: [meson.project_name() + '.conf']
)

install_data(
  files(meson.project_name() + '-tmpfiles.conf'),
  install_dir: systemd_tmpfiles_dir,
  rename: [meson.project_name() + '.conf']
)

subdir('icons')
