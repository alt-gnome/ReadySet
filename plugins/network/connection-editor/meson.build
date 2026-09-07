connection_editor_name = 'connection-editor'
connection_editor_c_name = 'net-' + connection_editor_name
connection_editor_srcdir = 'src'
connection_editor_deps = [
  libadwaita_dep,
  network_manager_dep,
  network_manager_gtk4_dep,
]

subdir(connection_editor_srcdir)

connection_editor_dep = declare_dependency(
  link_whole: libconnection_editor,
  include_directories: connection_editor_srcdir,
)
