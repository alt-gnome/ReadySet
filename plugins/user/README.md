# User plugin

#### Context fields:
###### `user-with-root`
If `true`, root password can be set. Otherwise it will not be set.

###### `user-no-password-security`
If `true`, password will not be checked via passwdqc/pwquality and any password can be used.

###### `user-passwd-conf-path`
Path to desired passwdqc config file.
If empty, `/etc/passwdqc.conf` or pwquality default will be used.

###### `user-avatar-directories`
Paths to directories with avatar files.
Override system dirs and gsettings.
