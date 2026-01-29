configure_file(
  input: gis + '.in',
  output: '@BASENAME@',
  configuration: {
    'DATADIR': datadir,
    'PACKAGE': gis,
  },
  install_dir: datadir / 'dconf' / 'profile',
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
  install_dir: datadir / gis,
)
