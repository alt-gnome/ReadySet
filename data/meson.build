rs_app_blueprints = custom_target('blueprints',
  input: files(
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

i18n.merge_file(
    input: configure_file(
        input: files(app_id_dyn + '.desktop.in.in'),
        output: app_id_dyn + '.desktop.in',
        configuration: {
          'LIBEXECDIR': libexecdir
        }
    ),
    output: app_id_dyn + '.desktop',
    install_dir: datadir / 'applications',
    po_dir: meson.project_source_root() / 'po',
    install: true,
    type: 'desktop'
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

configure_file(
    input: app_id + '.rules.in',
    output: app_id + '.rules',
    install: true,
    install_dir: rulesdir,
    configuration: {
      'SERVICE_NAME': app_id
    },
)

subdir('icons')

install_emptydir(sysconfdir / meson.project_name())
