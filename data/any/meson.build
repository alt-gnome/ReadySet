systemd_system_unit_dir = systemd.get_variable(pkgconfig: 'systemdsystemunitdir')

configure_file(
  input: meson.project_name() + '-any.service.in',
  output: meson.project_name() + '-any.service',
  configuration: {
    'LIBEXECDIR': libexecdir,
    'NAME': meson.project_name(),
  },
  install: true,
  install_dir: systemd_system_unit_dir
)

configure_file(
  input: 'greetd-config.toml',
  output: 'greetd.toml',
  configuration: {
    'LIBEXECDIR': libexecdir,
    'NAME': meson.project_name(),
  },
  install: true,
  install_dir: pkgdata_dir / 'any'
)

bootutil_vala_sources = files(
  'bootutil.vala',
  'config.vapi',
)

bootutil_dependencies = [
  librs_dep,
  posix_dep,
]

configure_file(output: 'config.h', configuration: global_conf)

executable(
  meson.project_name() + '-bootutil',
  bootutil_vala_sources,
  dependencies: bootutil_dependencies,
  include_directories: include_directories('.'),
  install: true,
  install_dir: libexecdir
)
