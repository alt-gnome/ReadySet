plugins = [
  'keyboard',
  'language',
  'user',
  'welcome'
]

if get_option('with_test_pages')
  plugins += ['test']
endif

foreach plugin : plugins
  subdir(plugin)
endforeach
