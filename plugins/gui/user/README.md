# User plugin

#### Context fields:
###### `user-with-root`
If `true`, root password can be set. Otherwise it will be equal to user password.

###### `no-password-security`
If `true`, password will not be checked via passwdqc/pwquality and any password can be used.

###### `passwd-conf-path`
Path to desired passwdqc config file.
If empty, `/etc/passwdqc.conf` or pwquality default will be used.
