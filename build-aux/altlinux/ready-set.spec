%define _unpackaged_files_terminate_build 1
%define app_id org.altlinux.ReadySet
%define _libexecdir %_prefix/libexec

Name: ready-set
Version: @LAST@
Release: alt1

Summary: The utility for configuring the system at the first start
License: GPL-3.0-or-later
Group: Other
Url: https://github.com/alt-gnome/ReadySet
Vcs: https://github.com/alt-gnome/ReadySet.git

Source: %name-%version.tar

Requires: /usr/sbin/chpasswd

BuildRequires(pre): rpm-macros-meson
BuildRequires(pre): rpm-macros-systemd
BuildRequires: meson
BuildRequires: vala
BuildRequires: pkgconfig(gtk4) >= 4.18
BuildRequires: pkgconfig(libadwaita-1) >= 1.7
BuildRequires: pkgconfig(gnome-desktop-4)
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: pkgconfig(accountsservice)
BuildRequires: pkgconfig(ibus-1.0)
BuildRequires: pkgconfig(pwquality)
BuildRequires: pkgconfig(systemd)
BuildRequires: blueprint-compiler

%description
%summary.

%package run
Summary: Run script of ReadySet
Group: Other

Requires: %name = %EVR

%description run
%summary.

Contain root password setup.

%package run-ximper
Summary: Run script of ReadySet for Ximper Linux
Group: Other

Requires: %name = %EVR

%description run-ximper
%summary.

%prep
%setup

%build
%meson -Dusername=_greeter
%meson_build

%install
%meson_install
%find_lang %name --with-gnome

%check
%meson_test

%files -f %name.lang
%_libexecdir/%name
%_iconsdir/hicolor/*/apps/%app_id.svg
%_iconsdir/hicolor/*/apps/%app_id-symbolic.svg
%doc README.md

%files run
%_libexecdir/%name-altlinux-run

%files run-ximper
%_libexecdir/%name-ximper*
%_unitdir/%name-ximper.service
%_unitdir/setup.target
