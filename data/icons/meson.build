foreach type : ['scalable', 'symbolic']
  new_name = ''
  if type == 'symbolic'
    new_name = app_id_dyn + '-symbolic.svg'
  else
    new_name = app_id_dyn + '.svg'
  endif

  install_data(
    'app/@0@@1@.svg'.format(type, devel_suffix),
    install_dir: datadir / 'icons' / 'hicolor' / type / 'apps',
    rename: new_name
  )
endforeach
