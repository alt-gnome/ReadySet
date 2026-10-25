unit_files = {}

if gdm_dep.found()
  gis = 'gnome-initial-setup'
  subdir(gis)

  unit_files += {
    gis / gis + '.service' : [],
    gis / meson.project_name() + '-existing-user-gnome.service' : [ 'gnome-session.target.wants/' ],
  }
endif

if get_option('phrog').enabled()
  subdir('phrog')

  unit_files += {
    'phrog' / meson.project_name() + '-existing-user-phrog.service' : [ 'gnome-session.target.wants/' ],
  }
endif

foreach unit, wants: unit_files
  configure_file(
    input: unit + '.in',
    output: fs.name (unit),
    configuration: {
      'LIBEXECDIR': libexecdir
    },
    install_dir: systemd_user_unit_dir
  )

  foreach target: wants
    meson.add_install_script(meson.project_source_root() / 'tools' / 'meson-add-wants.sh', systemd_user_unit_dir, target, fs.name (unit))
  endforeach
endforeach
