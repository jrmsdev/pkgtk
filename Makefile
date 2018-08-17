SH := /bin/sh

PREFIX ?= /usr/local
DESTDIR ?=
TCLSH ?= tclsh8.6
SUDOERS_GROUP ?= wheel

RELEASE != $(SH) -e mk/get-release.sh $(TCLSH)
RELNAME := pkgtk-$(RELEASE)
BUILDDIR := build/$(RELNAME)

INSTALL := install -v -C -h md5
INSTALL_EXE := $(INSTALL) -m 0755
INSTALL_FILE := $(INSTALL) -m 0644

MKDIR := mkdir -vp -m 0755

LIB_SOURCES != ls lib/pkgtk/*.tcl | grep -v pkgIndex
LIB_USERCFG_SRCS != ls lib/pkgtk/usercfg/*.tcl | grep -v pkgIndex

LIB_FILES != for relp in $(LIB_SOURCES); do echo $(BUILDDIR)/$$relp; done
LIB_USERCFG_FILES != for relp in $(LIB_USERCFG_SRCS); do echo $(BUILDDIR)/$$relp; done

BUILD_DEPS := $(LIB_FILES) $(LIB_USERCFG_FILES)
BUILD_DEPS += $(BUILDDIR)/bin/pkgtk
BUILD_DEPS += $(BUILDDIR)/etc/sudoers.d/pkgtk
BUILD_DEPS += $(BUILDDIR)/libexec/pkgtk/gui.tcl
BUILD_DEPS += $(BUILDDIR)/libexec/pkgtk/repocfg-save

.PHONY: all
all: build

.PHONY: pkgindex
pkgindex: lib/pkgtk/pkgIndex.tcl lib/pkgtk/usercfg/pkgIndex.tcl

lib/pkgtk/pkgIndex.tcl: Makefile $(LIB_SOURCES)
	@echo 'pkg_mkIndex lib/pkgtk *.tcl' | $(TCLSH)
	touch lib/pkgtk/pkgIndex.tcl

lib/pkgtk/usercfg/pkgIndex.tcl: Makefile $(LIB_USERCFG_SRCS)
	@echo 'pkg_mkIndex lib/pkgtk/usercfg *.tcl' | $(TCLSH)
	touch lib/pkgtk/usercfg/pkgIndex.tcl

.PHONY: build
build: pkgindex $(BUILD_DEPS) po-msgfmt
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk/msgs
	@$(INSTALL_FILE) po/*.msg $(BUILDDIR)/lib/pkgtk/msgs
	@$(MKDIR) $(BUILDDIR)/share/doc/pkgtk
	@$(INSTALL_FILE) LICENSE README.md $(BUILDDIR)/share/doc/pkgtk
	@test -s TODO && $(INSTALL_FILE) TODO $(BUILDDIR)/share/doc/pkgtk
	git log >$(BUILDDIR)/share/doc/pkgtk/ChangeLog

$(BUILDDIR)/bin/pkgtk: bin/pkgtk
	@$(MKDIR) $(BUILDDIR)/bin
	@$(INSTALL_EXE) bin/pkgtk $(BUILDDIR)/bin/pkgtk

$(BUILDDIR)/libexec/pkgtk/gui.tcl: libexec/pkgtk/gui.tcl
	@$(MKDIR) $(BUILDDIR)/libexec/pkgtk
	@echo '#!/usr/bin/env $(TCLSH)' >$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@tail -n +2 libexec/pkgtk/gui.tcl >>$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@chmod 0755 $(BUILDDIR)/libexec/pkgtk/gui.tcl
	touch $(BUILDDIR)/libexec/pkgtk/gui.tcl

$(BUILDDIR)/libexec/pkgtk/repocfg-save: libexec/pkgtk/repocfg-save
	@$(MKDIR) $(BUILDDIR)/libexec/pkgtk
	@$(INSTALL_EXE) libexec/pkgtk/repocfg-save $(BUILDDIR)/libexec/pkgtk

$(LIB_FILES): $(LIB_SOURCES)
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk
	@$(INSTALL_FILE) lib/pkgtk/*.tcl $(BUILDDIR)/lib/pkgtk

$(LIB_USERCFG_FILES): $(LIB_USERCFG_SRCS)
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk/usercfg
	@$(INSTALL_FILE) lib/pkgtk/usercfg/*.tcl $(BUILDDIR)/lib/pkgtk/usercfg

$(BUILDDIR)/etc/sudoers.d/pkgtk: etc/sudoers.d/pkgtk.in
	@$(MKDIR) $(BUILDDIR)/etc/sudoers.d
	@cat etc/sudoers.d/pkgtk.in | \
		sed 's#%LIBEXEC%#$(PREFIX)/libexec/pkgtk#' | \
		sed 's/%SUDOERS_GROUP%/$(SUDOERS_GROUP)/' >$(BUILDDIR)/etc/sudoers.d/pkgtk
	@touch $(BUILDDIR)/etc/sudoers.d/pkgtk

.PHONY: dist
dist: build
	@$(MKDIR) dist
	@tar -cJf dist/$(RELNAME).txz -C build $(RELNAME)/bin/pkgtk \
					       $(RELNAME)/etc/sudoers.d/pkgtk \
					       $(RELNAME)/lib/pkgtk \
					       $(RELNAME)/libexec/pkgtk \
					       $(RELNAME)/share/doc/pkgtk
	touch dist/$(RELNAME).txz

.PHONY: install
install: build
	@$(MKDIR) $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/libexec/pkgtk \
			$(DESTDIR)$(PREFIX)/lib/pkgtk/usercfg \
			$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs \
			$(DESTDIR)$(PREFIX)/share/doc/pkgtk \
			$(DESTDIR)$(PREFIX)/etc/sudoers.d
	@$(INSTALL_EXE) $(BUILDDIR)/bin/pkgtk \
				$(DESTDIR)$(PREFIX)/bin/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/gui.tcl \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/repocfg-save \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/*.tcl \
				$(DESTDIR)$(PREFIX)/lib/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/usercfg/*.tcl \
				$(DESTDIR)$(PREFIX)/lib/pkgtk/usercfg
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/msgs/*.msg \
				$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs
	@$(INSTALL_FILE) $(BUILDDIR)/share/doc/pkgtk/* \
				$(DESTDIR)$(PREFIX)/share/doc/pkgtk
	@$(INSTALL) -m 0440 $(BUILDDIR)/etc/sudoers.d/pkgtk \
				$(DESTDIR)$(PREFIX)/etc/sudoers.d/pkgtk

.PHONY: uninstall
uninstall:
	@rm -vf $(DESTDIR)$(PREFIX)/bin/pkgtk
	@rm -vf $(DESTDIR)$(PREFIX)/etc/sudoers.d/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/libexec/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/lib/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/share/doc/pkgtk

.PHONY: po-update
po-update:
	@$(MAKE) -C po update

.PHONY: po-msgfmt
po-msgfmt:
	@$(MAKE) -C po msgfmt

.PHONY: po-all
po-all:
	@$(MAKE) -C po all

.PHONY: clean
clean:
	@$(MAKE) -C po clean
	@rm -rvf dist build
