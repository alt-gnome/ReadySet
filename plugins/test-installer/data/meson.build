plugin_license_agreement_blueprints = files(
  'ui/disks-page.blp',
)

plugin_license_agreement_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Installer.TestInstaller.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_license_agreement_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
    build_always_stale: true,
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_test_installer_name + '.plugin',

  configuration: {
    'NAME': plugin_test_installer_pretty_name,
    'MODULE': plugin_test_installer_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: installers_plugins_dir
)
