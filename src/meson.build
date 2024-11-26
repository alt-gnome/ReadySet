vapi_sources = files(
  'config.vapi',
)

vala_sources = files(
  'pages/base-page.vala',
  'pages/language-page.vala',
  'pages/welcome-page.vala',

  'widgets/language-row.vala',
  'widgets/languages-box.vala',
  'widgets/nothing-to-show.vala',

  'about.vala',
  'application.vala',
  'main.vala',
  'utils.vala',
  'window.vala',
)

sources = [
  vala_sources,
  vapi_sources,
  resources,
]

executable(
  'ready-set',
  sources,
  include_directories: config_h_dir,
  dependencies: dependencies,
  install: true,
)
