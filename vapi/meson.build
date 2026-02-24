vapigen = find_program('vapigen', required: true)
if vapigen.found()
  run_command([
    meson.project_source_root() / 'vapi' / 'gdm-vapi-gen',
    meson.project_source_root() / 'vapi',
    '/usr/share'
  ], check: true)
endif
