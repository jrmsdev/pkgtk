SH ?= /bin/sh
TCLSH ?= tclsh8.6

BUILDDIR := build
INSTALL_EXE := install -v -C -h md5 -m 0755
INSTALL_FILE := install -v -C -h md5 -m 0644

USER_HOME != echo ~
RELEASE != echo 'source lib/pkgtk/version.tcl; version::release' | $(TCLSH)
LIB_SOURCES != ls lib/pkgtk/*.tcl | grep -v pkgIndex
LIB_FILES != for relp in $(LIB_SOURCES); do echo $(BUILDDIR)/$$relp; done

DESTDIR ?=
PREFIX ?= $(USER_HOME)

.PHONY: all
all: build

.PHONY: pkgindex
pkgindex: lib/pkgtk/pkgIndex.tcl

lib/pkgtk/pkgIndex.tcl: $(LIB_SOURCES)
	@echo 'pkg_mkIndex lib/pkgtk *.tcl' | $(TCLSH)
	touch lib/pkgtk/pkgIndex.tcl

.PHONY: build
build: pkgindex $(BUILDDIR)/bin/pkgtk $(BUILDDIR)/libexec/pkgtk/gui.tcl $(LIB_FILES)
	@mkdir -vp $(BUILDDIR)/share/doc/pkgtk
	@$(INSTALL_FILE) LICENSE README.md $(BUILDDIR)/share/doc/pkgtk

$(BUILDDIR)/bin/pkgtk: bin/pkgtk
	@mkdir -vp $(BUILDDIR)/bin
	@$(INSTALL_EXE) bin/pkgtk $(BUILDDIR)/bin/pkgtk

$(BUILDDIR)/libexec/pkgtk/gui.tcl: libexec/pkgtk/gui.tcl
	@mkdir -vp $(BUILDDIR)/libexec/pkgtk
	@echo '#!/usr/bin/env $(TCLSH)' >$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@tail -n +2 libexec/pkgtk/gui.tcl >>$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@chmod 0755 $(BUILDDIR)/libexec/pkgtk/gui.tcl
	touch $(BUILDDIR)/libexec/pkgtk/gui.tcl

$(LIB_FILES): $(LIB_SOURCES)
	@mkdir -vp $(BUILDDIR)/lib/pkgtk
	@$(INSTALL_FILE) lib/pkgtk/*.tcl $(BUILDDIR)/lib/pkgtk

.PHONY: dist
dist: build
	@rm -rf dist/pkgtk-$(RELEASE)*
	@mkdir -vp dist/pkgtk-$(RELEASE)
	@cp -vr $(BUILDDIR)/* dist/pkgtk-$(RELEASE)
	@tar -cJf dist/pkgtk-$(RELEASE).txz -C dist \
			pkgtk-$(RELEASE)/bin/pkgtk \
			pkgtk-$(RELEASE)/lib/pkgtk \
			pkgtk-$(RELEASE)/libexec/pkgtk \
			pkgtk-$(RELEASE)/share/doc/pkgtk
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
	@rm -rvf dist $(BUILDDIR)
