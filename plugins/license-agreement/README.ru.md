# Плагин лицензионного соглашения

Показывает лицензионное соглашение, загруженное из пути
`license-agreement.file-path`.

## Настройки

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `license-agreement.file-path` | Абсолютный путь к файлу лицензии с заполнителем `LANG` | — |
| `license-agreement.language-fallback` | Язык, используемый, если вариант для выбранной локали не найден | `C` |
| `license-agreement.installer` | При `true` страница не показывается при initial setup: сохраняется хэш лицензии, а в сеансе пользователя она будет показана, только если текст изменился | `false` |

## Как выбирается файл

`LANG` в пути заменяется языком, выбранным плагином `language`. Поиск учитывает
территорию, кодировку и модификатор. Если подходящий файл не найден, вместо
`LANG` используется `license-agreement.language-fallback`.

Файл для fallback-языка должен существовать и быть непустым: по нему
вычисляется хэш принятого соглашения.

## Пример

```ini
[Context]
license-agreement.file-path=/usr/share/alt-notes/license.LANG.html
license-agreement.language-fallback=all
```

Если в плагине языка выбрано `ru_RU.UTF-8`, будут последовательно проверены:

- `/usr/share/alt-notes/license.ru.html`
- `/usr/share/alt-notes/license.ru_RU.html`
- `/usr/share/alt-notes/license.ru.UTF-8.html`
- `/usr/share/alt-notes/license.ru_RU.UTF-8.html`

При отсутствии этих файлов используется `/usr/share/alt-notes/license.all.html`.
