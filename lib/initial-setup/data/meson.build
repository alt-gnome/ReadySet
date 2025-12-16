lib_blueprints = custom_target('blueprints',
  input: files(
    'ui/base-page-desc.blp',
    'ui/base-page.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

lib_resource_files = files('@0@.Lib.InitialSetup.gresource.xml'.format(app_id))
lib_resources = gnome.compile_resources(
  'libready-set-resources',
  lib_resource_files,
  dependencies: lib_blueprints,
  c_name: 'libready_set'
)
