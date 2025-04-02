desktop_file = i18n.merge_file(
  input: '@0@.desktop.in'.format(app_id_dyn),
  output: '@0@.desktop'.format(app_id_dyn),
  type: 'desktop',
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'applications'
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

appstream_file = i18n.merge_file(
  input: '@0@.metainfo.xml.in'.format(app_id),
  output: '@0@.metainfo.xml'.format(app_id),
  po_dir: '../po',
  install: true,
  install_dir: get_option('datadir') / 'metainfo'
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('Validate appstream file', appstreamcli, args: ['validate', appstream_file])
endif

install_data('@0@.gschema.xml'.format(app_id),
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
  test('Validate schema file',
  compile_schemas,
  args: ['--strict', '--dry-run', meson.current_source_dir()])
endif

blueprints = custom_target('blueprints',
  input: files(
    'ui/base-page-desc.blp',
    'ui/base-page.blp',
    'ui/carousel-page-titles.blp',
    'ui/end-page.blp',
    'ui/help-overlay.blp',
    'ui/language-page.blp',
    'ui/language-row.blp',
    'ui/languages-box.blp',
    'ui/nothing-to-show.blp',
    'ui/step-row.blp',
    'ui/steps-main-page.blp',
    'ui/steps-sidebar.blp',
    'ui/test-page.blp',
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

subdir('icons')
