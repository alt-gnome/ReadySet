project(
  'ready-set',
  'vala',
  version: '0.3.1',
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
ibus_dep = dependency('ibus-1.0')
libadwaita_dep = dependency('libadwaita-1', version: '>= 1.7')
libpeas_dep = dependency('libpeas-2')
polkit_dep = dependency('polkit-gobject-1')
gdm_dep = dependency('gdm')
posix_dep = meson.get_compiler('vala').find_library('posix')

api_version = meson.project_version().split('.')[0]
pascal_name = 'ReadySet'
app_id = 'org.altlinux.' + pascal_name

if get_option('is_devel')
  app_id_dyn = app_id + '.Devel'
else
  app_id_dyn = app_id
endif

supported_languages_arr = []
linguas = fs.read(meson.current_source_dir() / 'po' / 'LINGUAS').split()

foreach lang : linguas
  supported_languages_arr += [lang]
endforeach
supported_languages_arr += ['en']

gis = 'gnome-initial-setup'

prefix = get_option('prefix')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option('localedir')
libdir = prefix / get_option('libdir')
sysconfdir = prefix / get_option('sysconfdir')
libexecdir = prefix / get_option('libexecdir')
rulesdir = datadir / 'polkit-1' / 'rules.d'
localstatedir = prefix / get_option('localstatedir')

steps_plugins_dir = libdir / meson.project_name() / 'plugins' / 'steps'
installers_plugins_dir = libdir / meson.project_name() / 'plugins' / 'installers'

global_conf = configuration_data()
global_conf.set_quoted('NAME', meson.project_name())
global_conf.set_quoted('APP_ID', app_id)
global_conf.set_quoted('APP_ID_DYN', app_id_dyn)
global_conf.set_quoted('G_LOG_DOMAIN', app_id)
global_conf.set_quoted('SYSCONFDIR', sysconfdir)
global_conf.set10('IS_DEVEL', get_option('is_devel'))
global_conf.set_quoted('VERSION', meson.project_version())
global_conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
global_conf.set_quoted('LIBDIR', libdir)
global_conf.set_quoted('DATADIR', datadir)
global_conf.set_quoted('LIBEXECDIR', libexecdir)
global_conf.set_quoted('GNOMELOCALEDIR', localedir)
global_conf.set_quoted('SUPPORTED_LANGUAGES', '|'.join(supported_languages_arr))
global_conf.set_quoted('GDMEXPORTDIR', join_paths(prefix, get_option('gdm_rundir'), gis))
global_conf.set_quoted('STEPS_PLUGINS_DIR', steps_plugins_dir)
global_conf.set_quoted('INSTALLERS_PLUGINS_DIR', installers_plugins_dir)

subdir('vapi')
subdir('data')
subdir('po')
subdir('service')
subdir('lib')
subdir('src')
subdir('plugins')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
