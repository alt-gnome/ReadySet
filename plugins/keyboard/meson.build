plugin_keyboard_deps = [
  gnome_desktop_dep,
  gnome_desktop_dep,
  ibus_dep,
  librs_dep,
  polkit_dep,
]

plugin_keyboard_sources = files(
  'ibus-utils.vala',
  'input-chooser.vala',
  'input-row.vala',
  'page.vala',
  'plugin.vala',
  'utils.vala',
)

plugin_keyboard_pretty_name = 'Keyboard'
plugin_keyboard_name = 'keyboard'

subdir('data')

plugin_keyboard_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
  '-w'
]

if get_option('have_ibus')
  rs_app_c_args += ['-DHAVE_IBUS']
endif

shared_module(
  plugin_keyboard_name,
  plugin_keyboard_resources,
  plugin_keyboard_sources,
  dependencies: plugin_keyboard_deps,
  c_args: plugin_keyboard_c_args,
  install: true,
  install_dir: steps_plugins_dir
)
