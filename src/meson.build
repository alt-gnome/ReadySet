vapi_sources = files(
  'config.vapi',
)

vala_sources = files(
  'pages/alt-mobile-user/context-row.vala',
  'pages/alt-mobile-user/margin-label.vala',
  'pages/alt-mobile-user/password-strength.vala',
  'pages/alt-mobile-user/alt-mobile-user-page.vala',
  'pages/alt-mobile-user/utils.vala',

  'pages/base/base-page.vala',
  'pages/base/base-page-desc.vala',

  'pages/end/end-page.vala',

  'pages/keyboard/ibus-utils.vala',
  'pages/keyboard/input-chooser.vala',
  'pages/keyboard/input-row.vala',
  'pages/keyboard/keyboard-page.vala',

  'pages/language/lang-select-title.vala',
  'pages/language/language-page.vala',
  'pages/language/language-row.vala',
  'pages/language/languages-box.vala',
  'pages/language/locale-data.vala',

  'pages/test/test-page.vala',

  'pages/welcome/welcome-page.vala',

  'widgets/nothing-to-show.vala',
  'widgets/pages-indicator.vala',
  'widgets/positioned-stack.vala',
  'widgets/step-row.vala',
  'widgets/steps-main-page.vala',
  'widgets/steps-sidebar.vala',

  'about.vala',
  'application.vala',
  'main.vala',
  'result.vala',
  'utils.vala',
  'window-content.vala',
  'window.vala',
)

sources = [
  vala_sources,
  vapi_sources,
  resources,
]

c_args = [
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-DGNOME_DESKTOP_USE_UNSTABLE_API',
  '-w'
]

vala_args = [
  '--gresources', resource_files,
  '--gresourcesdir=data/',
  '--vapidir', meson.current_source_dir() / '..' / 'vapi',
]

if get_option('have_ibus')
  c_args += ['-DHAVE_IBUS']
endif

executable(
  'ready-set',
  sources,
  include_directories: config_h_dir,
  dependencies: dependencies,
  link_args: ['-lm'],
  c_args: c_args,
  vala_args: vala_args,
  install: true,
  install_dir: get_option('prefix') / get_option('libexecdir')
)
