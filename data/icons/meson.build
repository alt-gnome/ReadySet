foreach type : ['scalable', 'symbolic']
  install_data(
    'app/@0@@1@.svg'.format(type, devel_suffix),
    install_dir: datadir / 'icons' / 'hicolor' / type / 'apps',
    rename: app_id_dyn + '.svg'
  )
endforeach
