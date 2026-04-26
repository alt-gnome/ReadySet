plugin_license_agreement_deps = [
  librs_dep,
]

plugin_license_agreement_sources = files(
  'page.vala',
  'plugin.vala',
  'utils.vala',
)

plugin_license_agreement_pretty_name = 'License Agreement'
plugin_license_agreement_name = 'license-agreement'

subdir('data')

shared_module(
  plugin_license_agreement_name,
  plugin_license_agreement_resources,
  plugin_license_agreement_sources,
  dependencies: plugin_license_agreement_deps,
  install: true,
  install_dir: steps_plugins_dir
)
