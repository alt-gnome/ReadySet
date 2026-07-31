librss_name = 'lib' + meson.project_name() + '-service'
librss_gir_name = pascal_name + 'Service'

librss_versioned_name = meson.project_name() + '-service' + '-' + soversion
librss_versioned_lib_name = librss_name + '-' + soversion
librss_versioned_gir_name = librss_gir_name + '-' + soversion

librss_deps_name = librss_versioned_lib_name + '.deps'
librss_header_name = librss_versioned_lib_name + '.h'
librss_vapi_name = librss_versioned_lib_name + '.vapi'
librss_gir_name = librss_versioned_gir_name + '.gir'
librss_typelib_name = librss_versioned_gir_name + '.typelib'

librss_sources = files(
  'addin.vala',
  'plugin.vala',
)

librss_c_args = [
  '-DG_LOG_DOMAIN="libready-set-service"',
]

librss_dependencies = [
  gio_dep,
  libpeas_dep,
]

librss_deps_pkgs = []
foreach dep : librss_dependencies
  librss_deps_pkgs += [dep.name()]
endforeach

librss = library(
  librss_versioned_name,
  librss_sources,
  soversion: soversion,
  dependencies: librss_dependencies,
  vala_header: librss_header_name,
  vala_vapi: librss_vapi_name,
  vala_gir: librss_gir_name,
  version: libversion,
  install: true,
  install_dir: [true, true, true, true],
  # install_vala_header: true,
  # install_vala_vapi: true,
  # install_vala_gir: true,
  c_args: librss_c_args,
)

librss_dep = declare_dependency(
  link_with: librss,
  include_directories: include_directories('.'),
  dependencies: librss_dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (librss_deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: librss_deps_name,
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
      meson.current_build_dir() / librss_gir_name,
    ],
    input: librss,
    output: librss_typelib_name,
    depends: librss,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  librss,
  name: librss_versioned_lib_name,
  requires: librss_dependencies,
  subdirs: [ librss_versioned_name ],
  description: 'ReadySet Service library',
  variables: [
    'pkglib_dir=' + pkglib_dir.replace(libdir, '${libdir}'),
    'plugins_dir=' + service_plugins_dir.replace(pkglib_dir, '${pkglib_dir}'),
  ],
  version: libversion,
  url: 'https://altlinux.space/alt-gnome/ReadySet',
)
