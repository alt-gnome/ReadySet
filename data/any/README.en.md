# ReadySet integration for any display manager

This directory contains files for the `any` DM integration, which allows ReadySet to run as an initial-setup wizard before the display manager starts, without requiring built-in support from the DM itself.

## Configuring the compositor

The file `/usr/libexec/ready-set-wm` is **not shipped** by this package. The vendor must provide it. It must be an executable that accepts the path to the ReadySet application as its arguments and runs it inside a a compositor.

Example for `cage`:

```sh
#!/bin/sh
exec cage -- "$@"
```

Example for `weston`:

```sh
#!/bin/sh
dbus_command=""
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  dbus_command=dbus-run-session
fi

exec $dbus_command weston --shell=kiosk-shell.so -- "$@"
```
