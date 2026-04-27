configure_file(
  input: gis + '.conf.in',
  output: gis + '.conf',
  configuration: {
    'LOCALSTATEDIR': localstatedir,
    'GIS': gis,
  },
  install_dir: systemd_tmpfiles_dir,
)
