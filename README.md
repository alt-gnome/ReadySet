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

- alt-mobile-user (Setup user with administrator password)
- keyboard (Choosing layouts)
- language (Users language)

## Install

### ALT Linux

```sh
sudo apt-get update && apt-get install ready-set
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
- pwquality
- blueprint-compiler

#### Building

```sh
meson setup _build
```

#### Installing

```sh
meson install -C _build
```

#### Uninstalling

```sh
meson uninstall -C _build
```
