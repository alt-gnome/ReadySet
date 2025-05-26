systemd_dep = dependency('systemd', version: '>= 242')

systemd_system_unit_dir = systemd_dep.get_variable(
  pkgconfig: 'systemd_system_unit_dir',
  pkgconfig_define: ['prefix', get_option('prefix')]
)

# Install bins
install_data(
  files(
    'alt-mobile/ready-set-alt-mobile-run',
  ),
  install_mode: 'rwxr-xr-x',
  install_dir: get_option('prefix') / get_option('libexecdir')
)
