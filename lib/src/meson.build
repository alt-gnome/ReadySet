librs_name = 'lib' + meson.project_name()
librs_gir_name = pascal_name

librs_versioned_name = meson.project_name() + '-' + api_version
librs_versioned_lib_name = librs_name + '-' + api_version
librs_versioned_gir_name = librs_gir_name + '-' + api_version

librs_deps_name = librs_versioned_lib_name + '.deps'
librs_header_name = librs_versioned_lib_name + '.h'
librs_vapi_name = librs_versioned_lib_name + '.vapi'
librs_gir_name = librs_versioned_gir_name + '.gir'
librs_typelib_name = librs_versioned_gir_name + '.typelib'

librs_vapi_sources = files(
  
)

librs_vala_sources = files(
  'base/base-page-desc.vala',
  'base/base-page.vala',
  'addin.vala',
  'apply-callback.vala',
  'context.vala',
  'utils.vala',
)

librs_sources = [
  librs_vapi_sources,
  librs_vala_sources,
]

librs_sources_with_resources = librs_sources + [librs_resources]

librs_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(librs_name),
  '-w',
]

rs_app_vala_args = [
  '--vapidir', meson.project_source_root() / 'vapi',
]

librs_dependencies = [
  gee_dep,
  gio_dep,
  gtk_dep,
  libadwaita_dep,
  libpeas_dep,
]

librs_deps_pkgs = []
foreach dep : librs_dependencies
  librs_deps_pkgs += [dep.name()]
endforeach

librs = shared_library(
  librs_versioned_name,
  librs_sources_with_resources,
  dependencies: librs_dependencies,
  vala_header: librs_header_name,
  vala_vapi: librs_vapi_name,
  vala_gir: librs_gir_name,
  version: meson.project_version(),
  install: true,
  install_dir: [ true, true, true, true ],
  c_args: librs_c_args,
  vala_args: rs_app_vala_args,
)

librs_dep = declare_dependency(
  link_with: librs,
  include_directories: include_directories('.'),
  dependencies: librs_dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (librs_deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: librs_deps_name,
  configuration: deps_conf,
  install: true,
  install_dir: get_option('datadir') / 'vala' / 'vapi',
)

if get_option('with_lib_introspection')
  g_ir_compiler = find_program('g-ir-compiler')
  custom_target(
    'typelib',
    command: [
      g_ir_compiler,
      '--shared-library', '@PLAINNAME@',
      '--output', '@OUTPUT@',
      '--includedir', gee_dep.get_variable('datadir') / 'gir-1.0',
      meson.current_build_dir() / librs_gir_name,
    ],
    input: librs,
    output: librs_typelib_name,
    depends: librs,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  librs,
  name: librs_versioned_lib_name,
  requires: librs_dependencies,
  subdirs: [ librs_versioned_name ],
  description: 'ReadySet library',
  version: meson.project_version(),
  url: 'https://altlinux.space/alt-gnome/ReadySet',
)
