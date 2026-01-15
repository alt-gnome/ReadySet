<div align="center">

  <img
    src="data/icons/hicolor/scalable/apps/org.altlinux.ReadySet.svg"
    height="128"
  />

  <h1>
    Ready, Set, Go!
  </h1>
  
  <div align="center"><h4>A utility for configuring the system at the first startup</h4></div>

</div>

## All possible steps for now:

App using steps. Curently available steps:

- user-passwdqc
- user-pwquality
- keyboard (Choosing layouts)
- language (Users language)

## Configuration

The Ready Set is fully configurable. You can transfer the desired behavior either through options on the command line or through a configuration file (command line options overwrite fields in the configuration file).

Priority of configuration files (When a file is found, the following are not reading, so fields from other files cannot be combined):
1) The file specified via the `--conf-file` option
2) /etc/ready-set/config
4) /usr/share/ready-set/config

Example for configuration can be found file [here](example/example.conf).

Context configuration options can be found in plugins README.

## Testing

For test purpose you should use `--idle` option.

## Install

### ALT Linux

```sh
sudo apt-get update
sudo apt-get install ready-set
```

## Building from sources

#### Dependencies

- meson
- vala
- gtk4
- libadwaita-1
- gnome-desktop-4
- gee-0.8
- accountsservice
- ibus-1.0
- pwquality/passwdqc
- blueprint-compiler

#### Building

```sh
meson setup _build -Dis_devel=true
```

#### Installing

```sh
ninja install -C _build
```

#### Uninstalling

```sh
ninja uninstall -C _build
```

#### Mentions

- Roman Alifanov <ximper@etersoft.ru>
- David Sultaniiazov <x1z53@altlinux.org>

- Icon author, Viktoria Zubacheva <gingercat@alt-gnome.ru>
- Design autoh, Nina Petrova <1704.nina.petrova@gmail.com>

- [GNOME Initial Setup](https://gitlab.gnome.org/GNOME/gnome-initial-setup), where did a lot of logic come from
