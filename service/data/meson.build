systemd_system_unit_dir = systemd.get_variable(pkgconfig: 'systemdsystemunitdir')

dbus_conf = configuration_data()
dbus_conf.set('LIBEXECDIR', libexecdir)
dbus_conf.set('SERVICE_NAME', service_name)
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
  input: service_name + '.service.in',
  output: service_name + '.service',
  configuration: dbus_conf,
  install_dir: datadir / 'dbus-1' / 'system-services'
)

configure_file(
  input: service_name + '.policy.in',
  output: service_name + '.policy',
  configuration: dbus_conf,
  install: true,
  install_dir: datadir / 'polkit-1' / 'actions'
)

configure_file(
  input: service_name + '.conf.in',
  output: service_name + '.conf',
  configuration: dbus_conf,
  install: true,
  install_dir: sysconfdir / 'dbus-1' / 'system.d'
)

install_emptydir(datadir / meson.project_name() / 'rules.d')
install_emptydir(datadir / meson.project_name() / 'pre-hooks')
install_emptydir(datadir / meson.project_name() / 'post-hooks')
