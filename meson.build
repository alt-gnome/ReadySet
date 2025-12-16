project(
  'ready-set',
  'vala',
  version: '0.2.8',
  meson_version: '>= 1.1',
  license: 'GPL-3.0-or-later',
)

fs = import('fs')
i18n = import('i18n')
gnome = import('gnome')
pkgconfig = import('pkgconfig')

glib_min_version = '2.76'

accountsservice_desktop_dep = dependency('accountsservice')
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-unix-2.0')
gnome_desktop_dep = dependency('gnome-desktop-4')
gtk_dep = dependency('gtk4', version: '>= 4.18')
ibus_dep = dependency('ibus-1.0')
libadwaita_dep = dependency('libadwaita-1', version: '>= 1.7')
libpeas_dep = dependency('libpeas-2')
polkit_dep = dependency('polkit-gobject-1')
posix_dep = meson.get_compiler('vala').find_library('posix')
pwquality_dep = dependency('pwquality')

pascal_name = 'ReadySet'
app_id = 'org.altlinux.' + pascal_name

if get_option('is_devel')
  name_postfix = ' (Development)'
  app_id_dyn = app_id + '.Devel'
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

sysconfdir = get_option('prefix') / get_option('sysconfdir')

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('APP_ID_DYN', app_id_dyn)
conf.set_quoted('G_LOG_DOMAIN', app_id)
conf.set_quoted('SYSCONFDIR', sysconfdir)
conf.set10('IS_DEVEL', get_option('is_devel'))
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LIBDIR', get_option('prefix') / get_option('libdir'))
conf.set_quoted('DATADIR', get_option('prefix') / get_option('datadir'))
conf.set_quoted('GNOMELOCALEDIR', get_option('prefix') / get_option('localedir'))
conf.set_quoted('SUPPORTED_LANGUAGES', '|'.join(supported_languages_arr))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('data')
subdir('po')
subdir('lib')
subdir('src')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
