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
  '--define=FOR_APPLICATION',
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
