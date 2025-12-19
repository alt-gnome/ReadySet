subdir('data')

password_check_backend = get_option('password_check_backend')
if password_check_backend == 'both'
  password_check_backend = ['pwquality', 'passwdqc']
else
  password_check_backend = [password_check_backend]
endif

foreach pwcheck_backend : password_check_backend
  plugin_user_deps = [
    accountsservice_desktop_dep,
    gnome_desktop_dep,
    librs_dep,
    posix_dep,
    dependency(pwcheck_backend)
  ]

  plugin_user_sources = files(
    'context-row.vala',
    'margin-label.vala',
    'page.vala',
    'password-strength.vala',
    'plugin.vala',
    'utils.vala',
    pwcheck_backend + '-utils.vala',
  )

  plugin_user_pretty_name = 'User with ' + pwcheck_backend + ' password check'
  plugin_user_name = 'user-' + pwcheck_backend

  configure_file(
    input: 'data/plugin.in',
    output: plugin_user_name + '.plugin',

    configuration: {
      'NAME': plugin_user_pretty_name,
      'MODULE': plugin_user_name,
      'VERSION': meson.project_version(),
    },
    install: true,
    install_dir: libdir / meson.project_name() / 'plugins'
  )

  plugin_user_c_args = [
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    '-w'
  ]

  plugin_user_vala_args = [
    '--vapidir', meson.current_source_dir() / 'vapi',
  ]

  shared_module(
    plugin_user_name,
    plugin_user_resources,
    plugin_user_sources,
    dependencies: plugin_user_deps,
    c_args: plugin_user_c_args,
    vala_args: plugin_user_vala_args,
    install: true,
    install_dir: libdir / meson.project_name() / 'plugins'
  )
endforeach
