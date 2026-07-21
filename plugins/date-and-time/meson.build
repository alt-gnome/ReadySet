plugin_date_and_time_deps = [
  librs_dep,
]

plugin_date_and_time_sources = files(
  'page.vala',
  'plugin.vala',
  'date-and-time-selector.vala',
  'timezone-list.vala',
  'infinity-carousel.vala',
)

plugin_date_and_time_pretty_name = 'Date and Time'
plugin_date_and_time_name = 'date-and-time'

plugin_date_and_time_c_args = [
  '-DG_LOG_DOMAIN="DateAndTime"',
]

subdir('data')

shared_module(
  plugin_date_and_time_name,
  plugin_date_and_time_resources,
  plugin_date_and_time_sources,
  dependencies: plugin_date_and_time_deps,
  c_args: plugin_date_and_time_c_args,
  install: true,
  install_dir: steps_plugins_dir
)
