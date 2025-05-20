systemd_dep = dependency('systemd', version: '>= 242')

systemd_system_unit_dir = systemd_dep.get_variable(
  pkgconfig: 'systemd_system_unit_dir',
  pkgconfig_define: ['prefix', get_option('prefix')]
)

# altlinux

install_data(
  files(
    'altlinux/ready-set-altlinux-run',
  ),
  install_mode: 'rwxr-xr-x',
  install_dir: get_option('prefix') / get_option('libexecdir')
)

# ximper

install_data(
  files(
    'ximper/ready-set-ximper',
    'ximper/ready-set-ximper-post',
    'ximper/ready-set-ximper-run',
  ),
  install_mode: 'rwxr-xr-x',
  install_dir: get_option('prefix') / get_option('libexecdir')
)

install_data(
  files(
    'ximper/ready-set-ximper.service',
  ),
  install_dir: systemd_system_unit_dir
)

install_data(
  files(
    'ximper/setup.target',
  ),
  install_dir: systemd_system_unit_dir
)
