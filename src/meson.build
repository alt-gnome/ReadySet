vapi_sources = files(
  'config.vapi',
)

vala_sources = files(
  'pages/base-page.vala',
  'pages/end-page.vala',
  'pages/language-page.vala',
  'pages/test-page.vala',
  'pages/welcome-page.vala',

  'widgets/base-page-desc.vala',
  'widgets/carousel-page-titles.vala',
  'widgets/lang-select-title.vala',
  'widgets/language-row.vala',
  'widgets/languages-box.vala',
  'widgets/nothing-to-show.vala',
  'widgets/step-row.vala',
  'widgets/steps-main-page.vala',
  'widgets/steps-sidebar.vala',

  'about.vala',
  'application.vala',
  'main.vala',
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
  '-DGNOME_DESKTOP_USE_UNSTABLE_API'
]

vala_args = [
  '--gresources', resource_files,
  '--gresourcesdir=data/',
]

executable(
  'ready-set',
  sources,
  include_directories: config_h_dir,
  dependencies: dependencies,
  link_args: ['-lm'],
  c_args: c_args,
  vala_args: vala_args,
  install: true,
)
