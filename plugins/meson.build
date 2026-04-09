plugins = [
  'keyboard',
  'language',
  'network',
  'user',
  'welcome'
]

if get_option('is_devel')
  plugins += ['tests']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
