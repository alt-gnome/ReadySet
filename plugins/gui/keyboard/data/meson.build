plugin_keyboard_blueprints = files(
  'ui/input-chooser.blp',
  'ui/input-row.blp',
  'ui/page.blp',
)

plugin_keyboard_resources = gnome.compile_resources(
  'resources',
  '@0@.Plugin.Keyboard.gresource.xml'.format(app_id),
  source_dir: meson.current_build_dir(),
  dependencies: custom_target(
    'blueprints',
    
    input: plugin_keyboard_blueprints,
    output: '.',
    command: [ find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@' ],
  )
)

configure_file(
  input: 'plugin.in',
  output: plugin_keyboard_name + '.plugin',

  configuration: {
    'NAME': plugin_keyboard_pretty_name,
    'MODULE': plugin_keyboard_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: libdir / meson.project_name() / 'plugins'
)

install_data(
  files('org.altlinux.ReadySet.Plugin.Keyboard.rules'),
  install_dir: join_paths(get_option('datadir'), 'polkit-1', 'rules.d'),
)
