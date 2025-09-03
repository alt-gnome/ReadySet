# If you want to suggest changes, please send PR on
# https://altlinux.space/alt-gnome/ReadySet to altlinux branch 

%define _unpackaged_files_terminate_build 1

%define app_id org.altlinux.ReadySet
%define _libexecdir %_prefix/libexec

%define alt_mobile_override 50_%app_id.ALT-Mobile
%define alt_mobile_pwquality_conf 50_%app_id.ALT-Mobile.conf

Name: ready-set
Version: 0.2.8
Release: alt1

Summary: The utility for configuring the system at the first start
License: GPL-3.0-or-later
Group: Other
Url: https://altlinux.space/alt-gnome/ReadySet
Vcs: https://altlinux.space/alt-gnome/ReadySet.git

Source: %name-%version.tar
Source11: %name-first-run
Source12: %alt_mobile_override
Source13: %alt_mobile_pwquality_conf

Requires: /usr/sbin/chpasswd
Requires: accountsservice

BuildRequires(pre): rpm-macros-meson
BuildRequires(pre): rpm-macros-systemd
BuildRequires: blueprint-compiler
BuildRequires: meson
BuildRequires: pkgconfig(accountsservice)
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: pkgconfig(gnome-desktop-4)
BuildRequires: pkgconfig(gtk4) >= 4.18
BuildRequires: pkgconfig(ibus-1.0)
BuildRequires: pkgconfig(libadwaita-1) >= 1.7
BuildRequires: pkgconfig(polkit-gobject-1)
BuildRequires: pkgconfig(pwquality)
BuildRequires: pkgconfig(systemd)
BuildRequires: vala

%description
%summary.

%package alt-mobile-first-run
Summary: Run script of ReadySet
Group: Other

Requires: phrog
Requires: %name = %EVR

%description alt-mobile-first-run
%summary.

Contain executable for ALT Mobile (For phrog)

%prep
%setup

%build
%meson -Dusername=_greeter
%meson_build

%install
%meson_install
install -Dpm755 %SOURCE11 %buildroot%_libexecdir/%name-first-run
install -Dpm644 %SOURCE12 %buildroot%_sysconfdir/dconf/db/local.d/%alt_mobile_override
install -Dpm644 %SOURCE13 %buildroot%_sysconfdir/security/pwquality.conf.d/%alt_mobile_pwquality_conf
%find_lang %name

%check
%meson_test

%files -f %name.lang
%_libexecdir/%name
%_libexecdir/%name-set-root-password
%_datadir/polkit-1/rules.d/%app_id.rules
%_iconsdir/hicolor/*/apps/%app_id.svg
%_iconsdir/hicolor/*/apps/%app_id-symbolic.svg
%doc README.md

%files alt-mobile-first-run
%_libexecdir/%name-first-run
%_sysconfdir/dconf/db/local.d/%alt_mobile_override
%_sysconfdir/security/pwquality.conf.d/%alt_mobile_pwquality_conf

%changelog
* Tue Sep 04 2025 Vladimir Vaskov <rirusha@altlinux.org> 0.2.8-alt1
- Initial build.
