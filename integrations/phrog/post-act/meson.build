phrog_pa_deps = [
  librs_dep,
]

phrog_pa_sources = files(
  'plugin.vala',
)

phrog_pa_pretty_name = 'Unset first-run for phrog user'
phrog_pa_name = 'phrog-first-run-unset'

configure_file(
  input: 'plugin.in',
  output: phrog_pa_name + '.plugin',

  configuration: {
    'NAME': phrog_pa_pretty_name,
    'MODULE': phrog_pa_name,
    'VERSION': meson.project_version(),
  },
  install: true,
  install_dir: post_act_plugins_dir
)

shared_module(
  phrog_pa_name,
  phrog_pa_sources,
  dependencies: phrog_pa_deps,
  install: true,
  install_dir: post_act_plugins_dir
)
