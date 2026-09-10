# Плагин пользователя

Создаёт учётную запись пользователя и при необходимости задаёт пароль root.
Если AccountsService создаёт пользователя `systemd-homed`, пароль пользователя
устанавливается через `org.freedesktop.home1.Manager.ChangePasswordHome`, а не
через AccountsService.

Плагин собирается в вариантах с разными проверками качества пароля:
`user-pwquality` и `user-passwdqc`. Точный вариант определяет опция сборки
`password_check_backend`.

## Настройки

| Переменная | Описание | По умолчанию |
| --- | --- | --- |
| `user.with-root` | Включить страницу пароля root | `false` |
| `user.enforce-password-quality` | Не разрешать продолжение при слабом пароле | `false` |
| `user.passwd-conf-path` | Путь к конфигурации библиотеки проверки качества пароля | — |
| `user.avatar-directories` | Каталоги поиска аватаров. Если аватары не найдены, используется настройка `org.gnome.desktop.interface` `avatar-directories` | — |

## Сохраняемые значения контекста

| Переменная | Описание |
| --- | --- |
| `user.avatar-file` | Путь к выбранному файлу аватара |
| `user.username` | Логин пользователя |
| `user.fullname` | Полное имя пользователя |
| `user.password` | Пароль пользователя |
| `user.password-hash` | Хэш `user.password` для пользователей AccountsService |
| `user.root-password` | Пароль root |
| `user.root-password-hash` | Хэш `user.root-password` |

При изменении `user.password` и `user.root-password` автоматически создаются
соответствующие хэши. Для учётных записей `systemd-homed` применяется открытый
пароль пользователя через `org.freedesktop.home1`.
