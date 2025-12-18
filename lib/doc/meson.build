valadoc = find_program('valadoc')

pkgs = []
foreach deps_pkg : librs_deps_pkgs
  pkgs += '--pkg=' + deps_pkg
endforeach

valadoc_vala_dir = librs_versioned_name + '-vala'
custom_target(
  'valadoc',
  command: [ valadoc ] + pkgs +
  [
    librs_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + librs_versioned_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],
  build_by_default: true,
  input : librs_sources,
  output: valadoc_vala_dir,
  depends: librs,
)

custom_target(
  'cdocs',
  command: [ valadoc ] + pkgs +
  [
    librs_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + librs_versioned_name,
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / librs_versioned_name,
    '--doclet-arg=lib/' + librs_header_name,
    '--doclet=gtkdoc',
  ],
  build_by_default: true,
  output: librs_versioned_name,
  depends: librs,
)
