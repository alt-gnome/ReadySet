# На старт, Внимание, Марш! (Ready, Set, Go!)

Утилита для настройки системы при первом запуске

## Установка

### Из репозитория

```sh
su - -c "apt-get update && apt-get install ready-set"
```

### Сборка из исходников

#### Зависимости

```sh
su - -c "apt-get update && apt-get install meson vala 'pkgconfig(gtk4) pkgconfig(libadwaita-1) pkgconfig(gnome-desktop-4) pkgconfig(gee-0.8) pkgconfig(accountsservice) pkgconfig(ibus-1.0) pkgconfig(pwquality) pkgconfig(blueprint-compiler)'"
```

#### Сборка

```sh
meson setup _build
```

#### Установка

```sh
meson install -C _build
```

#### Удаление

```sh
meson uninstall -C _build
```
