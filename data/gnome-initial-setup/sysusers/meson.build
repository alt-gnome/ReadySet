configure_file(
  input: gis + '.conf.in',
  output: gis + '.conf',
  configuration: {
    'GIS': gis,
  },
  install_dir: systemd_sysusers_dir,
)
