# License Agreement plugin

Displays a license from `license-agreement-file-path` for language from `language` plugin or for `license-agreement-language-fallback`.

## Context variables

| Variable                              | Description                               | Default value |
| ------------------------------------- | ----------------------------------------- | ------------- |
| `license-agreement-file-path`         | Absolute path to license file with `LANG` | -             |
| `license-agreement-language-fallback` | `LANG` if selected language was not found | C             |

## Explanation

`license-agreement-file-path` is an absolute path to license file with `LANG` in.

`LANG` will be replaced with the language that was selected in the `language` plugin.

The search for `LANG` takes into account the territory, encoding and modifier.

If nothing was found, the value from the `license-agreement-language-fallback` will be used as `LANG`.

## Example

Config:

```
[Context]
license-agreement-file-path=/usr/share/alt-notes/license.LANG.html
license-agreement-language-fallback=all
```

Selected language in `language plugin` is `ru_RU.UTF-8`.

Files for `ru`, `ru_RU`, `ru.UTF-8` and `ru_RU.UTF-8` will be searched:

- `/usr/share/alt-notes/license.ru.html`
- `/usr/share/alt-notes/license.ru_RU.html`
- `/usr/share/alt-notes/license.ru.UTF-8.html`
- `/usr/share/alt-notes/license.ru_RU.UTF-8.html`

If no one was found, `/usr/share/alt-notes/license.all.html` will be used.
