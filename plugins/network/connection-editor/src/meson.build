connection_editor_blueprints = files(
  'connection-editor.blp',
  'details-page.blp',
  'security-page.blp',
  '8021x-security-page.blp',
  'bluetooth-page.blp',
  'ethernet-page.blp',
  'ip4-page.blp',
  'ip6-page.blp',
  'vpn-page.blp',
  'wifi-page.blp',
  'wireguard-page.blp',
  'wireguard-peer.blp',
)

connection_editor_sources = files(
  'ce-ip-address-entry.c',
  'ce-netmask-entry.c',
  'ce-page-8021x-security.c',
  'ce-page-bluetooth.c',
  'ce-page-details.c',
  'ce-page-ethernet.c',
  'ce-page-ip4.c',
  'ce-page-ip6.c',
  'ce-page-security.c',
  'ce-page-vpn.c',
  'ce-page-wireguard.c',
  'ce-page-wifi.c',
  'ce-page.c',
  'net-connection-editor.c',
  'vpn-helpers.c',
  'ui-helpers.c',
  'panel-common.c',
)

connection_editor_resources = gnome.compile_resources(
  connection_editor_c_name + '-resources',
  connection_editor_name + '.gresource.xml',
  c_name: connection_editor_c_name.underscorify(),
  dependencies: custom_target(
    input: connection_editor_blueprints,
    output: '.',
    command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTDIR@', '@CURRENT_SOURCE_DIR@', '@INPUT@']
  ),
)

libconnection_editor = static_library(
  connection_editor_name,
  connection_editor_sources,
  connection_editor_resources,
  dependencies: connection_editor_deps,
  include_directories: '..',
)
