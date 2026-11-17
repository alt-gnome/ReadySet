gis_shell_component = 'org.gnome.Shell'
gis_gnome_session_required_components = [
    'org.gnome.SettingsDaemon.A11ySettings',
    'org.gnome.SettingsDaemon.Color',
    'org.gnome.SettingsDaemon.Datetime',
    'org.gnome.SettingsDaemon.Housekeeping',
    'org.gnome.SettingsDaemon.Keyboard',
    'org.gnome.SettingsDaemon.MediaKeys',
    'org.gnome.SettingsDaemon.Power',
    'org.gnome.SettingsDaemon.PrintNotifications',
    'org.gnome.SettingsDaemon.Rfkill',
    'org.gnome.SettingsDaemon.ScreensaverProxy',
    'org.gnome.SettingsDaemon.Sharing',
    'org.gnome.SettingsDaemon.Smartcard',
    'org.gnome.SettingsDaemon.Sound',
    'org.gnome.SettingsDaemon.UsbProtection',
    'org.gnome.SettingsDaemon.Wacom',
    'org.gnome.SettingsDaemon.XSettings',
]

gis_user_session_wanted_components = gis_gnome_session_required_components

install_symlink(
  gis,
  install_dir: libexecdir,
  pointing_to: meson.project_name()
)

i18n.merge_file(
  input: configure_file(
    input: files(gis + '.desktop.in.in'),
    output: gis + '.desktop.in',
    configuration: {
      'LIBEXECDIR': libexecdir,
      'systemd_hidden': 'true',
    }
  ),
  output: gis + '.desktop',
  install_dir: datadir / 'applications',
  po_dir: meson.project_source_root() / 'po',
  install: true,
  type: 'desktop'
)

subdir('sysusers')

gis_user_session_wanted_targets = []
foreach component: gis_user_session_wanted_components
  gis_user_session_wanted_targets += 'Wants=@0@.target'.format(component)
endforeach

configure_file(
  input: gis + '.session.conf.in',
  output: gis + '.conf',
  configuration: {
    'this_component': gis,
    'requires_component': gis_shell_component,
    'wants_required_components': '\n'.join(gis_user_session_wanted_targets),
  },
  install_dir: systemd_user_unit_dir / 'gnome-session@' + gis + '.target.d',
)

configure_file(
  input: gis + '.session.in',
  output: gis + '.session',
  configuration: {
    'this_component': gis,
    'gnome_session_required_components': ';'.join(
      [gis_shell_component, gis] + gis_gnome_session_required_components
    ),
  },
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

subdir('post-act')
