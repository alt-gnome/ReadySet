librs_blueprints = custom_target('blueprints',
  input: files(
    'ui/base-page-desc.blp',
    'ui/base-page.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

librs_resource_files = files('@0@.Lib.gresource.xml'.format(app_id))
librs_resources = gnome.compile_resources(
  'libready-set-initial-setup-resources',
  librs_resource_files,
  dependencies: librs_blueprints,
  c_name: 'libready_set'
)
