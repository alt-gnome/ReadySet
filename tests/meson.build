subdir('plugins/test-common')
subdir('plugins/test-installer')
subdir('plugins/test-pageless')

test_plugin_manager_conf = configuration_data()
test_plugin_manager_conf.set_quoted('STEPS_PLUGINS_DIR', meson.current_build_dir() / 'plugins' / 'test-common')
test_plugin_manager_conf.set_quoted('INSTALLERS_PLUGINS_DIR', meson.current_build_dir() / 'plugins' / 'test-installer')

configure_file(output: 'test-config.h', configuration: test_plugin_manager_conf)
test_plugin_manager_config_h_dir = include_directories('.')

test('plugin-manager',
  executable('test-plugin-manager',
    sources: [
      files(
        'test-plugin-manager.vala',
        'test-config.vapi',
      ) + plugin_manager_sources,
      librs_sources_with_resources,
    ],
    include_directories: [
      test_plugin_manager_config_h_dir,
      '..' / 'lib' / 'src',
    ],
    c_args: [
      '-DG_LOG_DOMAIN="TestPluginManager"',
    ],
    vala_args: [
      '--vapidir', meson.project_source_root() / 'vapi',
      '--pkg', 'linux',
    ],
    dependencies: [
      gee_dep,
      gio_dep,
      libadwaita_dep,
      libpeas_dep,
      libserialize_dep,
    ],
  )
)

test('service-copy-to-user',
  executable('service-copy-to-user',
    sources: [
      'service-copy-to-user.vala',
      service_sources / 'copy-to-user.vala',
    ],
    dependencies: [
      gio_dep,
      posix_dep,
    ],
  )
)

test_context_sources = files(
  'test-context.vala',
)

test_context_c_args = [
  '-DGETTEXT_PACKAGE="ready-set"',
]

test_context_vala_args = [
  '--vapidir', meson.project_source_root() / 'vapi',
  '--vapidir', meson.project_source_root() / 'lib' / 'src',
]

test('context',
  executable('test-context',
    sources: [
      test_context_sources,
      librs_sources_with_resources,
    ],
    include_directories: include_directories('../lib/src'),
    c_args: test_context_c_args,
    vala_args: test_context_vala_args,
    dependencies: librs_dependencies,
  )
)

test('service-env-exec',
  executable('service-env-exec',
    sources: [
      'test-service-env-exec.vala',
      service_sources / 'hooks.vala',
      rs_internal_vapi_sources,
    ],
    include_directories: rs_internal_config_h_dir,
    dependencies: [
      gio_dep,
      polkit_dep,
      posix_dep,
    ],
  )
)

test('service-hooks',
  executable('service-hooks',
    sources: [
      'test-service-hooks.vala',
      service_sources / 'hooks.vala',
      rs_internal_vapi_sources,
    ],
    include_directories: rs_internal_config_h_dir,
    dependencies: [
      gio_dep,
      polkit_dep,
      posix_dep,
    ],
  )
)
