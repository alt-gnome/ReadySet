<div align="center">

  <img
    src="data/icons/hicolor/scalable/apps/org.altlinux.ReadySet.svg"
    height="128"
  />

  <h1>
    Ready, Set, Go!
  </h1>

  <div align="center"><h4>A utility for configuring the system at the first startup</h4></div>

</div>

## Available steps

The application is built from step plugins. Currently available step plugins are:

- [date-and-time](plugins/date-and-time/README.en.md)
- [keyboard](plugins/keyboard/README.en.md)
- [language](plugins/language/README.en.md)
- [license-agreement](plugins/license-agreement/README.en.md)
- [software](plugins/software/README.en.md)
- [user](plugins/user/README.en.md) — built as `user-passwdqc` (default) and/or `user-pwquality`, depending on the `password_check_backend` build option
- [welcome](plugins/welcome/README.en.md)

Installer plugins are loaded separately via the `--installer` option. Their steps are referenced with the `installer.` prefix (e.g. `installer.example-step`).

## Application modes

Ready Set automatically detects the mode it runs in:

- `installer` — when an installer plugin is specified with `--installer`.
- `initial-setup` — when running as the `ready-set` or `gnome-initial-setup` user.
- `existing-user` — when running under a regular user account.

The mode can be forced with `--force-mode` in `nightly=true` builds.

## Configuration

Ready Set is fully configurable. Desired behavior can be passed either through command-line options or through a configuration file (command-line options override values from the configuration file).

Configuration file priority (only the first found file is used; fields from other files are not merged):

1. The file specified via the `--conf-file` option
2. `/etc/ready-set/config`
3. `/usr/share/ready-set/config`

An example configuration file can be found [here](example/example.conf).

Context configuration options for individual plugins can be found in their README files.

### Options

#### `context`
Cumulative option in `VAR=VALUE` format. Can be passed multiple times.

#### `can-close`
Make the window closable even in non-nightly builds. In `nightly=true` builds the window is always closable. `false` by default.

#### `fullscreen`
Run the window in fullscreen.

#### `installer`
Specify the installer plugin module name.

#### `sandbox`
Run without applying changes to the system.

#### `detailed`
Show step indicators and a sidebar with steps. The simple view is used by default.

#### `steps`
Comma-separated list of step plugin module names. E.g: `language,keyboard,user-passwdqc`.

#### `resizable`
Allow window resizing. `false` by default.

#### `width`
Initial window width. `1000` by default.

#### `height`
Initial window height. `800` by default.

#### `force-layout`
Force the window layout: `big`, `small`, `vertical`, `horizontal`. Auto by default.

#### `force-mode`
Force the application mode: `installer`, `initial-setup`, `existing-user`. Can be used only in `nightly=true` builds. Auto by default.

#### `apply-only`
Apply the configuration and exit without launching the GUI. Cannot be used in `existing-user` mode.

#### `version`
Print version information and exit.

#### `conf-file`
Path to the application configuration file.

## Commands

In addition to the standard launch, Ready Set supports:

- `generate-bash-completion` — output a bash completion script.

## Translating

You can help with translations via [ALT Gnome Translate](https://translate.alt-gnome.ru/projects/ready-set/#languages)

<a href="https://translate.alt-gnome.ru/engage/ready-set/">
<img src="https://translate.alt-gnome.ru/widget/ready-set/ready-set/horizontal-red.svg" alt="Translation progress" />
</a>

## Testing

For testing purposes you should use the `--sandbox` option.

## Building from sources

This project uses the Meson build system. All available build options can be found [here](meson.options).

```sh
meson setup _build
meson compile -C _build
```

## Credits

- Vladimir Romanov <rirusha@altlinux.org> — developer
- Viktoria Zubacheva <gingercat@alt-gnome.ru> — icon/design
- Nina Petrova <1704.nina.petrova@gmail.com> — design

- [GNOME Initial Setup](https://gitlab.gnome.org/GNOME/gnome-initial-setup), the source of a lot of the logic
