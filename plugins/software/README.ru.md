# Плагин программного обеспечения

Включает сторонние источники программного обеспечения. Определения источников
загружаются из файлов `*.yml` и `*.yaml` в каталоге данных плагина (обычно
`/usr/share/ready-set/software/sources.d`). Если корректных источников нет,
плагин скрывается. Он выполняется после шага `user`.

## Настройки

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `software.single-button` | Показывать одну кнопку включения/выключения вместо переключателей источников | `false` |

## Сохраняемые значения контекста

| Переменная | Описание |
| --- | --- |
| `software.enabled-sources` | Список идентификаторов выбранных источников |

## Типы источников

- `flatpak` — добавить удалённый репозиторий Flatpak;
- `stplr` — добавить репозиторий Stapler;
- `alt-repo` — добавить apt-репозиторий ALT Linux;
- `custom` — выполнить произвольную команду shell.

Для `flatpak` и `stplr` секция `body` содержит `url` и `remote-name`. Для
`alt-repo` она содержит `repos` — список строк источников apt. Для `custom`
нужен `cmd-apply`; `cmd-check` определяет его текущее состояние, а `cmd-undo`
используется необязательной интеграцией с Tuner. У источника доступны метаданные
`group`, `gettext-domain` и `non-free`; у группы — `gettext-domain`, `required`
и `priority`.

## Пример

Полный пример находится в [example/sources.yml](example/sources.yml).

```yaml
groups:
  - id: flathub
    name: Flathub
    description: Популярный репозиторий приложений Flatpak
    gettext-domain: ready-set
    required: true
    priority: 1

sources:
  - id: flathub
    type: flatpak
    group: flathub
    name: Flathub
    description: Популярный репозиторий приложений Flatpak
    gettext-domain: ready-set
    body:
      url: https://flathub.org/repo/flathub.flatpakrepo
      remote-name: flathub
```

## Плагин Tuner

При сборке с `-Dwith_software_tuner_plugin=enabled` эта функциональность также
собирается как плагин Tuner `ready-set-software` для приложения
[Tuner](https://altlinux.space/alt-gnome/tuner).
