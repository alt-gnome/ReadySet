# Keyboard plugin

Configures GNOME input sources and applies the resulting X11 keyboard layout
through `org.freedesktop.locale1`.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `keyboard.preview-bin` | Binary name for the xkb layout preview | `tecla` |

## Stored context variables

| Variable | Description |
| -------- | ----------- |
| `keyboard.input-sources` | Selected keyboard input sources |
| `keyboard.additinal-layout-grp` | Additional layout-switch method (the key name is intentionally spelled as implemented) |
