gis_pa_deps = [
  gdm_dep,
  librs_dep,
]

gis_pa_sources = files(
  'plugin.vala',
)

gis_pa_pretty_name = 'GDM post-act for login to user'
gis_pa_name = 'gdm-login'

configure_file(
  input: 'plugin.in',
  output: gis_pa_name + '.plugin',

  configuration: {
    'NAME': gis_pa_pretty_name,
    'MODULE': gis_pa_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: post_act_plugins_dir
)

shared_module(
  gis_pa_name,
  gis_pa_sources,
  dependencies: gis_pa_deps,
  install: true,
  install_dir: post_act_plugins_dir
)
