plugin_privacy_deps = [
  librs_dep,
]

plugin_privacy_vapi_sources = files(

)

plugin_privacy_vala_sources = files(
  'page.vala',
  'plugin.vala',
)

plugin_privacy_sources = [
  plugin_privacy_vapi_sources,
  plugin_privacy_vala_sources,
]

plugin_privacy_pretty_name = 'Privacy'
plugin_privacy_name = 'privacy'

plugin_privacy_c_args = [
  '-DG_LOG_DOMAIN="Privacy"',
]

subdir('data')

shared_module(
  plugin_privacy_name,
  plugin_privacy_resources,
  plugin_privacy_sources,
  dependencies: plugin_privacy_deps,
  c_args: plugin_privacy_c_args,
  install: true,
  install_dir: steps_plugins_dir
)
