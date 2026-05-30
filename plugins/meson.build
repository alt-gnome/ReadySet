plugins = [
  'keyboard',
  'language',
  'user',
  'welcome',
  'license-agreement',
  'date-and-time',
]

if get_option('is_devel')
  plugins += ['tests']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
