plugins = [
  'keyboard',
  'language',
  'network',
  'user',
  'welcome'
]

if get_option('is_devel')
  plugins += ['test']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
