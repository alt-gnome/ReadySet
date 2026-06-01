plugins = [
  'keyboard',
  'language',
  'license-agreement',
  'network',
  'user',
  'welcome',
]

if get_option('is_devel')
  plugins += ['tests', 'test-installer']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
