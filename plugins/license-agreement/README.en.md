# License Agreement plugin

Displays a license agreement loaded from `license-agreement.file-path`.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `license-agreement.file-path` | Absolute path to a license file containing the `LANG` placeholder | — |
| `license-agreement.language-fallback` | Fallback language used when the selected locale is not found | `C` |
| `license-agreement.installer` | If true, on `initial-setup` we only save hash and recheck it on `existing-user` | — |

## Explanation

`LANG` in the file path is replaced with the language selected by the `language` plugin. The search takes into account the territory, encoding and modifier.

If no matching file is found, `license-agreement.language-fallback` is used as `LANG`.

NOTE: Path with fallback **MUST** be present.

## Example

```
[Context]
license-agreement.file-path=/usr/share/alt-notes/license.LANG.html
license-agreement.language-fallback=all
```

Selected language in the `language` plugin: `ru_RU.UTF-8`.

The following files are searched:

- `/usr/share/alt-notes/license.ru.html`
- `/usr/share/alt-notes/license.ru_RU.html`
- `/usr/share/alt-notes/license.ru.UTF-8.html`
- `/usr/share/alt-notes/license.ru_RU.UTF-8.html`

If none are found, `/usr/share/alt-notes/license.all.html` is used.
