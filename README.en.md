<div align="center">

  <img
    src="data/icons/app/scalable.svg"
    height="128"
  />

  <h1>
    Ready, Set, Go!
  </h1>

  <div align="center"><h4>A utility for configuring the system at the first startup</h4></div>

</div>

Ready Set is a modular GTK application for configuring a system during
installation, first startup, or an existing user's session.

## Available steps

The application is built from step plugins. Currently available step plugins are:

- [date-and-time](plugins/date-and-time/README.en.md)
- [keyboard](plugins/keyboard/README.en.md)
- [language](plugins/language/README.en.md)
- [license-agreement](plugins/license-agreement/README.en.md)
- [network](plugins/network/README.en.md)
- [privacy](plugins/privacy/README.en.md)
- [software](plugins/software/README.en.md)
- [user](plugins/user/README.en.md) — built as `user-passwdqc` (default) and/or `user-pwquality`, depending on the `password_check_backend` build option

If the first selected step does not implement the `Welcome` interface, Ready Set
shows its built-in welcome page first.

Installer plugins are loaded separately via the `--installer` option. Their steps are referenced with the `installer.` prefix (e.g. `installer.example-step`).

## Application modes

Ready Set automatically detects the mode it runs in:

- `installer` — when an installer plugin is specified with `--installer`.
- `initial-setup` — when running as the `ready-set` or `gnome-initial-setup` user.
- `existing-user` — when running under a regular user account.

The mode can be forced with `--force-mode` in `nightly=true` builds.

## Configuration

Ready Set is configured through command-line options and a key file. Command-line
options override the configuration file. Application options belong to the
`[Application]` group; plugin context values belong to `[Context]`. Values passed
through `--context` and values loaded from `[Context]` are locked, so the UI
cannot overwrite centrally supplied values.

Configuration priority (only the first found way is used; fields from other ways are not applied):

1. The file specified via the `--conf-file` option
2. Local config: `/etc/ready-set/config` and `/etc/ready-set/config.d/` (sorted alphabetically)
3. Vendor config: `/usr/share/ready-set/config` and `/usr/share/ready-set/config.d/` (sorted alphabetically)

When a config file is loaded (not via the `--conf-file` option), files from its
`config.d` directory are loaded as well and merged into it. Values from
`config.d` files override the main config; values from later files override
earlier ones.

An example configuration file can be found [here](example/example.conf).

Context configuration options for individual plugins can be found in their README files.

### Options

#### `apply-only`
Run apply from config without running GUI. Cannot be used in `existing-user` mode.

#### `can-close`
Make window closable always. In `nightly=true` builds the window is always closable. `false` by default.

#### `conf-file`
App config file.

#### `context`
Context values in `KEY=VALUE` form. This cumulative option can be supplied more
than once. String lists use commas, for example
`--context keyboard.input-sources=xkb::us,xkb::ru`.

#### `force-layout`
Set layout for window: `big`, `small`, `vertical`. Auto by default.

#### `force-mode`
Force run with mode: `installer`, `initial-setup`, `existing-user`. Can be used only in `nightly=true` builds. Auto by default.

#### `fullscreen`
Run window in fullscreen.

#### `height`
Height of a window. `800` by default.

#### `installer`
Specify installer plugin.

#### `resizable`
Window can be resized or not. `false` by default.

#### `sandbox`
Sandbox run without doing anything in system.

#### `steps`
Comma-separated list of step plugin module names, for example
`language,keyboard,user-passwdqc`.

#### `version`
Print version information and exit.

#### `width`
Width of a window. `1000` by default.

## Commands

In addition to the standard launch, Ready Set supports:

- `generate-bash-completion` — output a bash completion script.
- `nothing-to-do` — write `0` to standard error when no setup work is needed,
  or `1` otherwise.

## Translating

You can help with translations via [ALT Gnome Translate](https://translate.alt-gnome.ru/projects/ready-set/#languages)

<a href="https://translate.alt-gnome.ru/engage/ready-set/">
<img src="https://translate.alt-gnome.ru/widget/ready-set/ready-set/horizontal-red.svg" alt="Translation progress" />
</a>

## Testing

Use `--sandbox` to exercise the workflow without changing system settings if plugins supports it. Run
the project test suite from a configured build directory with
`meson test -C _build`.

## Building from sources

This project uses the Meson build system. All available build options can be found [here](meson.options).

```sh
meson setup _build
meson compile -C _build
```

## Credits

- Vladimir Romanov <rirusha@altlinux.org> — maintainer
- Valery Zabrovsky <brow@altlinux.org> — `network` plugin maintainer
- David Sultaniiazov <x1z53@alt-gnome.ru> — `license-agreement` and `date-and-time` plugins maintainer
- Viktoria Zubacheva <gingercat@alt-gnome.ru> — icons/design
- Nina Petrova <1704.nina.petrova@gmail.com> — design
- [GNOME Control Center](plugins/network/connection-editor/README.en.md)
- [GNOME Initial Setup](https://gitlab.gnome.org/GNOME/gnome-initial-setup), the source of a lot of the logic
