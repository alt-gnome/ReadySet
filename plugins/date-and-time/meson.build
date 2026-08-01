plugin_date_and_time_deps = [
  librs_dep,
  gnome_desktop_dep,
  libcase_dep,
]

plugin_date_and_time_vapi_sources = files(
  'config.vapi',
)

plugin_date_and_time_vala_sources = files(
  'page.vala',
  'plugin.vala',
  'utils.vala',
  'date-selector.vala',
  'time-selector.vala',
  'timezone-list.vala',
  'timezone-list-row.vala',
  'infinity-carousel.vala',
  'carousel-selector.vala',
)

plugin_date_and_time_sources = [
  plugin_date_and_time_vapi_sources,
  plugin_date_and_time_vala_sources,
]

plugin_date_and_time_pretty_name = 'Date & Time'
plugin_date_and_time_name = 'date-and-time'

plugin_date_and_time_c_args = [
  '-DG_LOG_DOMAIN="DateAndTime"',
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
]

plugin_date_and_time_link_args = [
  '-lm',
]

subdir('data')

configure_file(output: 'config.h', configuration: global_conf)

shared_module(
  plugin_date_and_time_name,
  plugin_date_and_time_resources,
  plugin_date_and_time_sources,
  dependencies: plugin_date_and_time_deps,
  c_args: plugin_date_and_time_c_args,
  link_args: plugin_date_and_time_link_args,
  install: true,
  install_dir: steps_plugins_dir
)
