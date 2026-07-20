vapigen = find_program('vapigen', required: true)
if vapigen.found()
  run_command([
    meson.project_source_root() / 'vapi' / 'gdm-vapi-gen',
    meson.project_source_root() / 'vapi',
    '/usr/share'
  ], check: true)
endif

full_version = find_program('valac').version()
version_parts = full_version.split('.')
vala_version = version_parts[0] + '.' + version_parts[1]

run_command([
  meson.project_source_root() / 'vapi' / 'gtk4-vapi-fix',
  meson.project_source_root() / 'vapi',
  '/usr/share' / 'vala-' + vala_version / 'vapi',
], check: true)
