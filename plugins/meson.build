plugins = [
  'keyboard',
  'language',
  'user',
  'welcome',
  'license-agreement',
]

if get_option('is_devel')
  plugins += ['tests']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
