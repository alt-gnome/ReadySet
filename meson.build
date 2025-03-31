project(
  'ready-set',
  ['c', 'vala'],
  version: '0.1.0',
  meson_version: '>= 1.0.0',
  license: 'GPL-3.0-or-later',
)

fs = import('fs')
i18n = import('i18n')
gnome = import('gnome')

gtk = dependency('gtk4', version: '>= 4.16')
libadwaita = dependency('libadwaita-1', version: '>= 1.6')
gnome_desktop = dependency('gnome-desktop-4')
gee = dependency('gee-0.8')
accountsservice_desktop = dependency('accountsservice')

dependencies = [
  gtk,
  libadwaita,
  gnome_desktop,
  gee,
  accountsservice_desktop
]

add_project_arguments(
  '-include', 'config.h',
  language: ['c']
)

add_project_arguments(
  '--target-glib', '2.76',
  '--vapidir', meson.current_source_dir(),
  language: ['vala']
)

app_id = 'space.rirusha.ReadySet'

if get_option('is_devel')
  name_postfix = ' (Development)'
  app_id_dyn = app_id + '-Devel'
else
  name_postfix = ''
  app_id_dyn = app_id
endif

supported_languages_arr = []
linguas = fs.read(meson.current_source_dir() / 'po' / 'LINGUAS').split()

foreach lang : linguas
  supported_languages_arr += [lang]
endforeach
supported_languages_arr += ['en']

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('APP_ID_DYN', app_id_dyn)
conf.set_quoted('G_LOG_DOMAIN', app_id)
conf.set10('IS_DEVEL', get_option('is_devel'))
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('DATADIR', get_option('prefix') / get_option('datadir'))
conf.set_quoted('GNOMELOCALEDIR', get_option('prefix') / get_option('localedir'))
conf.set10('GNOME_DESKTOP_USE_UNSTABLE_API', true)
conf.set_quoted('SUPPORTED_LANGUAGES', '|'.join(supported_languages_arr))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('data')
subdir('po')
subdir('src')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
