plugins = [
  'keyboard',
  'language',
  'user',
  'welcome',
  'license-agreement',
]

if get_option('is_devel')
  plugins += ['tests', 'test-installer']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
