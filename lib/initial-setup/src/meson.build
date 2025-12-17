librs_is_name = 'lib' + meson.project_name()
librs_is_gir_name = pascal_name

librs_is_versioned_name = meson.project_name() + '-' + api_version
librs_is_versioned_lib_name = librs_is_name + '-' + api_version
librs_is_versioned_gir_name = librs_is_gir_name + '-' + api_version

librs_is_deps_name = librs_is_versioned_lib_name + '.deps'
librs_is_header_name = librs_is_versioned_lib_name + '.h'
librs_is_vapi_name = librs_is_versioned_lib_name + '.vapi'
librs_is_gir_name = librs_is_versioned_gir_name + '.gir'
librs_is_typelib_name = librs_is_versioned_gir_name + '.typelib'

librs_is_vapi_sources = files(
  
)

librs_is_vala_sources = files(
  'base/base-page-desc.vala',
  'base/base-page.vala',
  'addin.vala',
  'apply-callback.vala',
  'context.vala',
  'utils.vala',
)

librs_is_sources = [
  librs_is_vapi_sources,
  librs_is_vala_sources,
  librs_is_resources,
]

librs_is_c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(librs_is_name),
  '-w',
]

librs_is_deps_pkgs = [
  'gee-0.8',
  'gio-unix-2.0',
  'gtk4',
  'libadwaita-1',
  'libpeas-2',
]

librs_is_dependencies = [
  gee_dep,
  gio_dep,
  gtk_dep,
  libadwaita_dep,
  libpeas_dep,
]

librs = shared_library(
  librs_is_versioned_name,
  librs_is_sources,
  dependencies: librs_is_dependencies,
  vala_header: librs_is_header_name,
  vala_vapi: librs_is_vapi_name,
  vala_gir: librs_is_gir_name,
  version: meson.project_version(),
  install: true,
  install_dir: [ true, true, true, true ],
  c_args: librs_is_c_args,
)

librs_is_dep = declare_dependency(
  link_with: librs,
  include_directories: include_directories('.'),
  dependencies: librs_is_dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (librs_is_deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: librs_is_deps_name,
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
      meson.current_build_dir() / librs_is_gir_name,
    ],
    input: librs,
    output: librs_is_typelib_name,
    depends: librs,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  librs,
  name: librs_is_versioned_lib_name,
  requires: librs_is_dependencies,
  subdirs: [ librs_is_versioned_name ],
  description: 'ReadySet library',
  version: meson.project_version(),
  url: 'https://altlinux.space/alt-gnome/ReadySet',
)
