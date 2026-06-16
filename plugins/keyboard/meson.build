wayland_client_dep = dependency('wayland-client')

plugin_keyboard_deps = [
  gnome_desktop_dep,
  gnome_desktop_dep,
  librs_dep,
  libserialize_dep,
  polkit_dep,
  wayland_client_dep,
  xkb_dep,
]

if ibus_dep.found()
  plugin_keyboard_deps += ibus_dep
endif

plugin_keyboard_sources = files(
  'enums.vala',
  'hw-tracker.vala',
  'ibus-utils.vala',
  'input-chooser.vala',
  'input-info.vala',
  'input-row.vala',
  'input-sources.vala',
  'layout-switch-button.vala',
  'page.vala',
  'plugin.vala',
  'preview-dialog.vala',
  'stevia-layout-data.vala',
  'utils.vala',
)

plugin_keyboard_c_sources = files(
  'protocol/phoc-device-state-unstable-v1-protocol.c',
)

plugin_keyboard_pretty_name = 'Keyboard'
plugin_keyboard_name = 'keyboard'

subdir('data')

plugin_keyboard_c_args = [
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
  '-DG_LOG_DOMAIN="Keyboard"',
  '-I' + meson.current_source_dir() / 'protocol',
]

plugin_keyboard_vala_args = [
  '--vapidir', meson.current_source_dir() / 'vapi',
  '--pkg', 'phoc-device-state',
]

if ibus_dep.found()
  plugin_keyboard_vala_args += ['-D', 'HAVE_IBUS']
endif

shared_module(
  plugin_keyboard_name,
  plugin_keyboard_resources,
  plugin_keyboard_sources,
  plugin_keyboard_c_sources,
  vala_args: plugin_keyboard_vala_args,
  dependencies: plugin_keyboard_deps,
  c_args: plugin_keyboard_c_args,
  install: true,
  install_dir: steps_plugins_dir,
)
