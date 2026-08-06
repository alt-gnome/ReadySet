# User plugin

Create a user account and optionally set the root password.

If AccountsService creates a `systemd-homed` user, the user password is set via `org.freedesktop.home1.Manager.ChangePasswordHome` instead of AccountsService.

The plugin is built in two variants with different password quality backends: `user-pwquality` and `user-passwdqc`. The exact variant is controlled by the `password_check_backend` build option.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `user.with-root` | Enable the root password page | — |
| `user.enforce-password-quality` | Prevent proceeding if the password is weak | — |
| `user.passwd-conf-path` | Path to the password quality library configuration | — |
| `user.avatar-directories` | Directories to search for avatar files. The `org.gnome.desktop.interface` `avatar-directories` setting is also used | — |

## Stored context variables

| Variable | Description |
| -------- | ----------- |
| `user.avatar-file` | Path to the selected avatar file |
| `user.username` | User login name |
| `user.fullname` | User full name |
| `user.password` | User password |
| `user.root-password` | Root password |
