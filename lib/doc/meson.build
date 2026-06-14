valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : librs_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = meson.project_name() + '-vala'
custom_target(
  'valadoc',
  command: [ valadoc ] + pkgs +
  [
    librs_sources,
    '--package-name=' + librs_versioned_name,
    '--package-version=' + libversion,
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : librs_sources,
  output: valadoc_vala_dir,
  depends: librs,
)
