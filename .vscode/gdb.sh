#!/bin/sh

flatpak build --with-appdir --allow=devel --bind-mount=/run/user/1000/doc=/run/user/1000/doc/by-app/space.rirusha.ReadySet-Devel --share=network --share=ipc --socket=fallback-x11 --socket=wayland --device=dri --socket=pulseaudio .flatpak/repo gdb "$@"