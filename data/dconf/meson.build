configure_file(
  input: meson.project_name() + '.in',
  output: '@BASENAME@',
  configuration: {
    'DATADIR': datadir,
    'PACKAGE': meson.project_name(),
  },
  install_dir: get_option('datadir') / 'dconf' / 'profile',
)

custom_target('initial-setup-dconf-defaults',
  output: 'initial-setup-dconf-defaults',
  input: files(
    'defaults/00-upstream-settings',
    'defaults/locks/00-upstream-settings-locks',
  ),
  command: [
    find_program('dconf'),
    'compile',
    '@OUTPUT@',
    meson.current_source_dir() / 'defaults',
  ],
  install: true,
  install_dir: get_option('datadir') / meson.project_name(),
)
