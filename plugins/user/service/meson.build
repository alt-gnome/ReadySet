plugin_user_service_deps = [
  librss_dep,
]

plugin_user_service_sources = files(
  'plugin.vala',
)

plugin_user_service_pretty_name = 'User root service'
plugin_user_service_name = 'user-root'

configure_file(
  input: 'plugin.in',
  output: plugin_user_service_name + '.plugin',

  configuration: {
    'NAME': plugin_user_service_pretty_name,
    'MODULE': plugin_user_service_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: service_plugins_dir
)

plugin_user_service_c_args = [
  '-DG_LOG_DOMAIN="User"',
]

shared_module(
  plugin_user_service_name,
  plugin_user_service_sources,
  dependencies: plugin_user_service_deps,
  c_args: plugin_user_service_c_args,
  install: true,
  install_dir: service_plugins_dir
)
