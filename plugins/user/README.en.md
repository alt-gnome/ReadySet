# User plugin

Bunch of pages for creating user or collection user information.

Present in two variants with two different backends: `pwquality` and `passwdqc`. Plugins named accordingly `user-pwquality` and `user-passwdqc`.

## Settings Context variables

| Variable                              | Description                                                                                               | Default value |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------- |
| `user.with-root`                      | Set password for root or not. Needs build option `user_with_set_root`                                     | -             |
| `user.enforce-password-quality`       | Don't let user go next if password is weak                                                                | -             |
| `user.passwd-conf-path`               | Config for password lib                                                                                   | -             |
| `user.avatar-directories`             | Directory where avatar file located. `org.gnome.desktop.interface` `avatar-directories` will also be used | -             |

## Storage Context variables

| Variable             |
| -------------------- |
| `user.avatar-file`   |
| `user.username`      |
| `user.fullname`      |
| `user.password`      |
| `user.root-password` |
