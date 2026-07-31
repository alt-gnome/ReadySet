valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : librss_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = meson.project_name() + '-vala'
custom_target(
  'valadoc',
  command: [ valadoc ] + pkgs +
  [
    librss_sources,
    '--package-name=' + librss_versioned_name,
    '--package-version=' + libversion,
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : librss_sources,
  output: valadoc_vala_dir,
  depends: librss,
)
