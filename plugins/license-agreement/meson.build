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

plugin_license_agreement_c_args = [
  '-DG_LOG_DOMAIN="LicenseAgreement"',
]

subdir('data')

shared_module(
  plugin_license_agreement_name,
  plugin_license_agreement_resources,
  plugin_license_agreement_sources,
  dependencies: plugin_license_agreement_deps,
  c_args: plugin_license_agreement_c_args,
  install: true,
  install_dir: steps_plugins_dir
)
