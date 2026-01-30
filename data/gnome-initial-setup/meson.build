install_symlink(
  gis,
  install_dir: libexecdir,
  pointing_to: libexecdir / meson.project_name()
)

i18n.merge_file(
  input: configure_file(
    input: files(gis + '.desktop.in.in'),
    output: gis + '.desktop.in',
    configuration: {
      'LIBEXECDIR': libexecdir
    }
  ),
  output: gis + '.desktop',
  install_dir: datadir / 'applications',
  po_dir: meson.project_source_root() / 'po',
  install: true,
  type: 'desktop'
)

configure_file(
  input: gis + '.service.in',
  output: gis + '.service',
  configuration: {
    'LIBEXECDIR': libexecdir
  },
  install_dir: systemd_user_unit_dir
)

install_data(
  files(gis + '-sysusers.conf'),
  install_dir: systemd_sysusers_dir,
  rename: [gis + '.conf']
)

configure_file(
  input: gis + '-tmpfiles.conf.in',
  output: gis + '.conf',
  configuration: {
    'LOCALSTATEDIR': localstatedir,
  },
  install_dir: systemd_tmpfiles_dir,
)

configure_file(
  input: gis + '.session.conf.in',
  output: gis + '.session.conf',
  configuration: {
    'THIS': gis,
  },
  install_dir: systemd_user_unit_dir / 'gnome-session@' + gis + '.target.d',
)

install_data(
  gis + '.session',
  install_dir: datadir / 'gnome-session' / 'sessions'
)

install_data(
  'initial-setup.json',
  install_dir: datadir / 'gnome-shell' / 'modes'
)

subdir('dconf')

install_emptydir(localstatedir/ 'run' / gis)
install_emptydir(localstatedir/ 'lib' / gis)
install_emptydir(datadir / gis)
