# Software plugin

Enable third-party software repositories.

Source definitions are loaded from the plugin data directory (usually `/usr/share/ready-set/software/sources.d`) from `*.yml` (or `*.yaml`) files. The plugin is hidden if no valid sources are found.

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
