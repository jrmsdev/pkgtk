SH ?= /bin/sh
TCLSH ?= tclsh8.6

BUILDDIR := build
INSTALL_EXE := install -v -C -h md5 -m 0755
INSTALL_FILE := install -v -C -h md5 -m 0644

USER_HOME != echo ~
TCL_PKGPATH != echo 'puts $$tcl_pkgPath' | $(TCLSH)
LIB_SOURCES != ls lib/pkgtk/*.tcl | grep -v pkgIndex
LIB_FILES != for relp in $(LIB_SOURCES); do echo $(BUILDDIR)/$$relp; done

DESTDIR ?=
PREFIX ?= $(USER_HOME)

RELEASE := 0.1.0

.PHONY: all
all: build

.PHONY: pkgindex
pkgindex: lib/pkgtk/pkgIndex.tcl

lib/pkgtk/pkgIndex.tcl: $(LIB_SOURCES)
	@echo 'pkg_mkIndex lib/pkgtk *.tcl' | $(TCLSH)
	touch lib/pkgtk/pkgIndex.tcl

.PHONY: build
build: pkgindex $(BUILDDIR)/bin/pkgtk $(LIB_FILES)
	@mkdir -vp $(BUILDDIR)/share/doc/pkgtk
	@$(INSTALL_FILE) LICENSE README.md $(BUILDDIR)/share/doc/pkgtk

$(BUILDDIR)/bin/pkgtk: bin/pkgtk
	@mkdir -vp $(BUILDDIR)/bin
	@echo '#!/usr/bin/env $(TCLSH)' >$(BUILDDIR)/bin/pkgtk
	@tail -n +2 bin/pkgtk >>$(BUILDDIR)/bin/pkgtk
	@chmod 0750 $(BUILDDIR)/bin/pkgtk
	touch $(BUILDDIR)/bin/pkgtk

$(LIB_FILES): $(LIB_SOURCES)
	@mkdir -vp $(BUILDDIR)/lib/pkgtk
	@$(INSTALL_FILE) lib/pkgtk/*.tcl $(BUILDDIR)/lib/pkgtk

.PHONY: dist
dist: build
	@rm -rf dist/pkgtk-$(RELEASE)*
	@mkdir -vp dist/pkgtk-$(RELEASE)
	@cp -vr $(BUILDDIR)/* dist/pkgtk-$(RELEASE)
	@tar -cJf dist/pkgtk-$(RELEASE).txz -C dist pkgtk-$(RELEASE)
	touch dist/pkgtk-$(RELEASE).txz

.PHONY: install
install: build
	@mkdir -vp $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/lib/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/bin/pkgtk $(DESTDIR)$(PREFIX)/bin/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/*.tcl $(DESTDIR)$(PREFIX)/lib/pkgtk
	@mkdir -vp $(DESTDIR)$(PREFIX)/share/doc/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/share/doc/pkgtk/* $(DESTDIR)$(PREFIX)/share/doc/pkgtk

.PHONY: uninstall
uninstall:
	@rm -vf $(DESTDIR)$(PREFIX)/bin/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/lib/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/share/doc/pkgtk

.PHONY: clean
clean:
	@rm -rvf $(BUILDDIR)
