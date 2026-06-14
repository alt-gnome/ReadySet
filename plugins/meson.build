plugins = [
  'keyboard',
  'language',
  'user',
  'welcome',
  'license-agreement',
]

if get_option('nightly')
  plugins += ['tests', 'test-installer']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
