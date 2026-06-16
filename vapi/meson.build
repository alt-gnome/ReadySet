vapigen = find_program('vapigen', required: true)
if vapigen.found() and gdm_dep.found()
  run_command([
    meson.project_source_root() / 'vapi' / 'gdm-vapi-gen',
    meson.project_source_root() / 'vapi',
    # Force use system
    '/usr/share'
  ], check: true)
endif

if vapigen.found() and pms_dep.found()
  run_command([
    meson.project_source_root() / 'vapi' / 'pms-vapi-gen',
    meson.project_source_root() / 'vapi',
    # Force use system
    '/usr/share'
  ], check: true)
endif
