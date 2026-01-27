systemd_system_unit_dir = systemd.get_variable(pkgconfig: 'systemdsystemunitdir')

dbus_conf = configuration_data()
dbus_conf.set('LIBEXECDIR', libexecdir)
dbus_conf.set('SERVICE_NAME', app_id)
dbus_conf.set('NAME', meson.project_name())
dbus_conf.set('USER', 'root')

configure_file(
  input: meson.project_name() + '.service.in',
  output: meson.project_name() + '.service',
  configuration: dbus_conf,
  install: true,
  install_dir: systemd_system_unit_dir
)

configure_file(
  input: app_id + '.service.in',
  output: app_id + '.service',
  configuration: dbus_conf,
  install_dir: datadir / 'dbus-1' / 'system-services'
)

configure_file(
  input: app_id + '.policy.in',
  output: app_id + '.policy',
  configuration: dbus_conf,
  install: true,
  install_dir: datadir / 'polkit-1' / 'actions'
)

configure_file(
  input: app_id + '.conf.in',
  output: app_id + '.conf',
  configuration: dbus_conf,
  install: true,
  install_dir: sysconfdir / 'dbus-1' / 'system.d'
)

install_emptydir(datadir / meson.project_name() / 'pre-hooks')
install_emptydir(datadir / meson.project_name() / 'post-hooks')
