# Makefile for devel purpose. For release packaging just use meson

ifeq ($(shell id -u), 0)
	SUDO :=
else
	SUDO := sudo
endif

.PHONY: setup setup-ci install compile test lint lint-fix install-deps

install-deps:
	$(SUDO) xargs apm s install -y < ./build-aux/altlinux/build-deps || true

setup: install-deps
	meson setup --wipe _build -Dnightly=true --prefix=/usr

setup-ci: install-deps
	meson setup --wipe _build -Dnightly=true --prefix=/usr -Dwith_lib_documentation=true

compile:
	meson compile -C _build

install: compile
	meson install -C _build

test:
	meson test -C _build

lint:
	io.elementary.vala-lint -d .
	find ./ -name "*.blp" -print0 | xargs -0 blueprint-compiler format -s 2

lint-fix:
	find ./ -name "*.blp" -print0 | xargs -0 blueprint-compiler format -f -s 2
