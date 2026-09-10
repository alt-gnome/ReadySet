# Software plugin

Enable third-party software repositories.

Source definitions are loaded from `*.yml` and `*.yaml` files in the plugin data
directory (usually `/usr/share/ready-set/software/sources.d`). The plugin is
hidden when no valid sources are found. It runs after the `user` step.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `software.single-button` | Show a single enable/disable button instead of per-source toggles | `false` |

## Stored context variables

| Variable | Description |
| -------- | ----------- |
| `software.enabled-sources` | List of selected source IDs |

## Source types

Supported source types:

- `flatpak` — add a Flatpak remote
- `stplr` — add a Stapler repository
- `alt-repo` — add an ALT Linux apt repository
- `custom` — run a custom shell command

For `flatpak` and `stplr`, `body` contains `url` and `remote-name`. For
`alt-repo`, it contains `repos`, a list of apt source lines. For `custom`, it
contains `cmd-apply`; `cmd-check` determines its current state, and `cmd-undo`
is used by the optional Tuner integration. Source metadata can include `group`,
`gettext-domain`, and `non-free`; group metadata can include `gettext-domain`,
`required`, and `priority`.

## Example

See [example/sources.yml](example/sources.yml) for a full sample.

```yaml
groups:
  - id: flathub
    name: Flathub
    description: Most popular flatpak application repository
    gettext-domain: ready-set
    required: true
    priority: 1

sources:
  - id: flathub
    type: flatpak
    group: flathub
    name: Flathub
    description: Most popular flatpak application repository
    gettext-domain: ready-set
    body:
      url: https://flathub.org/repo/flathub.flatpakrepo
      remote-name: flathub
```

## Tuner plugin

When built with `-Dwith_software_tuner_plugin=enabled`, the software
functionality is also built as the `ready-set-software` Tuner plugin for use
with [Tuner](https://altlinux.space/alt-gnome/tuner).
