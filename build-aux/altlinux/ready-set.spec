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
BuildRequires: meson
BuildRequires: vala
BuildRequires: pkgconfig(gtk4) >= 4.18
BuildRequires: pkgconfig(libadwaita-1) >= 1.7
BuildRequires: pkgconfig(gnome-desktop-4)
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: pkgconfig(accountsservice)
BuildRequires: pkgconfig(ibus-1.0)
BuildRequires: pkgconfig(pwquality)
BuildRequires: blueprint-compiler

%description
%summary.

%prep
%setup

%build
%meson
%meson_build

%install
%meson_install
%find_lang %name --with-gnome

%check
%meson_test

%files -f %name.lang
%_libexecdir/%name
%_sysconfdir/%name
%doc README.md
