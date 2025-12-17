librs_is_blueprints = custom_target('blueprints',
  input: files(
    'ui/base-page-desc.blp',
    'ui/base-page.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

librs_is_resource_files = files('@0@.Lib.InitialSetup.gresource.xml'.format(app_id))
librs_is_resources = gnome.compile_resources(
  'libready-set-initial-setup-resources',
  librs_is_resource_files,
  dependencies: librs_is_blueprints,
  c_name: 'libready_set_initial_setup'
)
