project(
  'ready-set',
  'vala',
  version: '0.13.0.rc',
  meson_version: '>= 1.9',
  license: 'GPL-3.0-or-later',
)

fs = import('fs')
i18n = import('i18n')
gnome = import('gnome')
pkgconfig = import('pkgconfig')

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-w',
  language: 'c',
)

add_project_arguments(
  '--fatal-warnings',
  '--enable-experimental',
  '--vapidir', meson.project_source_root() / 'vapi',
  '--vapi-comments',
  language: 'vala',
)

accountsservice_dep = dependency('accountsservice')
api_base_dep = dependency('libapi-base-7')
flatpak_dep = dependency('flatpak')
gdm_dep = dependency('gdm', required: get_option('gdm'))
gee_dep = dependency('gee-0.8')
gio_dep = dependency('gio-unix-2.0')
gnome_desktop_dep = dependency('gnome-desktop-4')
ibus_dep = dependency('ibus-1.0', required: get_option('ibus'))
libadwaita_dep = dependency('libadwaita-1', version: '>= 1.7')
libcase_dep = dependency('libcase-0', fallback: ['libcase', 'lib_dep'])
libpeas_dep = dependency('libpeas-2')
libserialize_dep = dependency('libserialize-7', version: '>= 7.9')
network_manager_dep = dependency ('libnm', version: '>= 1.2')
network_manager_gtk4_dep = dependency ('libnma-gtk4', version: '>= 1.0')
polkit_dep = dependency('polkit-gobject-1')
posix_dep = meson.get_compiler('vala').find_library('posix')
xkb_dep = dependency('xkbcommon')

if get_option('with_software_tuner_plugin').enabled()
  tuner_dep = dependency('tuner-1')
endif

libversion = meson.project_version().replace('.rc', '')
version_parts = libversion.split('.')
if version_parts[0] == '0'
  soversion = version_parts[0] + '.' + version_parts[1]
else
  soversion = version_parts[0]
endif
pascal_name = 'ReadySet'
app_id = 'org.altlinux.' + pascal_name

if get_option('nightly')
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
bindir = prefix / get_option('bindir')
datadir = prefix / get_option('datadir')
localedir = prefix / get_option('localedir')
libdir = prefix / get_option('libdir')
sysconfdir = prefix / get_option('sysconfdir')
libexecdir = prefix / get_option('libexecdir')
rulesdir = datadir / 'polkit-1' / 'rules.d'
localstatedir = prefix / get_option('localstatedir')

pkgdata_dir = datadir / meson.project_name()
pkglib_dir = libdir / meson.project_name()

user_pre_hooks_dir = pkgdata_dir / 'initial-setup-pre-hooks' / 'user'
user_post_hooks_dir = pkgdata_dir / 'initial-setup-post-hooks' / 'user'
system_pre_hooks_dir = pkgdata_dir / 'initial-setup-pre-hooks' / 'system'
system_post_hooks_dir = pkgdata_dir / 'initial-setup-post-hooks' / 'system'
installer_pre_hooks = pkgdata_dir / 'installer-pre-hooks' / 'system'
installer_post_hooks = pkgdata_dir / 'installer-post-hooks' / 'system'

steps_plugins_dir = pkglib_dir / 'plugins' / 'steps'
installers_plugins_dir = pkglib_dir / 'plugins' / 'installers'
service_plugins_dir = pkglib_dir / 'plugins' / 'service'

global_conf = configuration_data()
global_conf.set_quoted('NAME', meson.project_name())
global_conf.set_quoted('APP_ID', app_id)
global_conf.set_quoted('APP_ID_DYN', app_id_dyn)
global_conf.set_quoted('G_LOG_DOMAIN', app_id)
global_conf.set_quoted('SYSCONFDIR', sysconfdir)
global_conf.set10('NIGHTLY', get_option('nightly'))
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
global_conf.set_quoted('SERVICE_PLUGINS_DIR', service_plugins_dir)

subdir('vapi')
subdir('data')
subdir('po')
subdir('service')
subdir('lib')
subdir('src')
subdir('plugins')
subdir('tests')

install_emptydir(sysconfdir / meson.project_name())
install_emptydir(localstatedir/ 'lib' / meson.project_name())

# User hooks works only for service user under which executed initial-setup mode
# Needs for phrog, for removing ready-set from first-run gsetting
install_emptydir(user_pre_hooks_dir)
install_emptydir(user_post_hooks_dir)

install_emptydir(system_pre_hooks_dir)
install_emptydir(system_post_hooks_dir)
install_emptydir(installer_pre_hooks)
install_emptydir(installer_post_hooks)

install_emptydir(steps_plugins_dir)
install_emptydir(installers_plugins_dir)
install_emptydir(service_plugins_dir)

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
