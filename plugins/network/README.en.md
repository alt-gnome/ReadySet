# Network plugin

Configures Ethernet, Wi-Fi, and modem connections through NetworkManager and
sets the system hostname when changes are applied.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `network.simple` | Show the step only when NetworkManager does not report full connectivity | `false` |
| `network.required` | Require an active network connection before continuing | `false` |

## Stored context variables

| Variable | Description |
| -------- | ----------- |
| `network.hostname` | System hostname |
