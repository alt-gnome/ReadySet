# Makefile for devel purpose. For release packaging just use meson

ifeq ($(shell id -u), 0)
	SUDO :=
else
	SUDO := sudo
endif

PM := $(shell if command -v apm >/dev/null 2>&1; then echo 'apm s'; elif command -v apt-get >/dev/null 2>&1; then echo apt-get; fi)

ifeq ($(PM),)
$(error Package manager not found)
endif

.PHONY: setup setup-ci install compile test lint lint-fix install-deps coverage

install-deps:
	$(SUDO) $(PM) update || true
	$(SUDO) xargs $(PM) install -y < ./build-aux/altlinux/build-deps || true

setup: install-deps
	rm -rf _build
	meson setup _build --prefix=/usr --auto-features=enabled -Dnightly=true

setup-ci: install-deps
	meson setup --wipe _build --prefix=/usr --auto-features=enabled -Dnightly=true -Dwith_lib_documentation=true -Db_coverage=true

compile:
	meson compile -C _build

install: compile
	meson install -C _build

uninstall:
	$(SUDO) ninja uninstall -C _build

test: compile
	meson test -C _build

coverage: test
	mkdir -p _build/meson-logs/coveragereport
	gcovr _build -x -o _build/meson-logs/coverage.xml
	gcovr _build --html --html-details -o _build/meson-logs/coveragereport/index.html

lint:
	io.elementary.vala-lint -d .
	find ./ -name "*.blp" -print0 | xargs -0 blueprint-compiler format -s 2

lint-fix:
	find ./ -name "*.blp" -print0 | xargs -0 blueprint-compiler format -f -s 2
