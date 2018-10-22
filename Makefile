SH := /bin/sh

PREFIX ?= /usr/local
DESTDIR ?=
TCLSH ?= tclsh8.6

RELEASE != $(SH) -eu mk/get-release.sh $(TCLSH)
RELEASE_BRANCH != $(SH) -eu mk/release-branch.sh
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
BUILD_DEPS += $(BUILDDIR)/libexec/pkgtk/gui.tcl
BUILD_DEPS += $(BUILDDIR)/libexec/pkgtk/repocfg-save
BUILD_DEPS += $(BUILDDIR)/libexec/pkgtk/sudo-askpass
BUILD_DEPS += $(BUILDDIR)/lib/pkgtk/release-branch.txt

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
build: pkgindex $(BUILD_DEPS)
	@$(MKDIR) $(BUILDDIR)/share/doc/pkgtk
	@$(INSTALL_FILE) LICENSE README.md $(BUILDDIR)/share/doc/pkgtk
	@if test -s TODO; then \
		$(INSTALL_FILE) TODO $(BUILDDIR)/share/doc/pkgtk; fi
	@if test -d .git; then \
		git log >$(BUILDDIR)/share/doc/pkgtk/ChangeLog; fi
	@if test "$(RELEASE_BRANCH)" == "NONE"; then \
		rm -vf $(BUILDDIR)/lib/pkgtk/release-branch.txt; fi

### START: BUILD_DEPS

$(BUILDDIR)/bin/pkgtk: bin/pkgtk
	@$(MKDIR) $(BUILDDIR)/bin
	@$(INSTALL_EXE) bin/pkgtk $(BUILDDIR)/bin/pkgtk

$(BUILDDIR)/libexec/pkgtk/gui.tcl: libexec/pkgtk/gui.tcl
	@$(MKDIR) $(BUILDDIR)/libexec/pkgtk
	echo '#!/usr/bin/env $(TCLSH)' >$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@tail -n +2 libexec/pkgtk/gui.tcl >>$(BUILDDIR)/libexec/pkgtk/gui.tcl
	@chmod 0755 $(BUILDDIR)/libexec/pkgtk/gui.tcl

$(BUILDDIR)/libexec/pkgtk/repocfg-save: libexec/pkgtk/repocfg-save
	@$(MKDIR) $(BUILDDIR)/libexec/pkgtk
	@$(INSTALL_EXE) libexec/pkgtk/repocfg-save $(BUILDDIR)/libexec/pkgtk

$(BUILDDIR)/libexec/pkgtk/sudo-askpass: libexec/pkgtk/sudo-askpass
	@$(MKDIR) $(BUILDDIR)/libexec/pkgtk
	echo '#!/usr/bin/env $(TCLSH)' >$(BUILDDIR)/libexec/pkgtk/sudo-askpass
	@tail -n +2 libexec/pkgtk/sudo-askpass >>$(BUILDDIR)/libexec/pkgtk/sudo-askpass
	@chmod 0755 $(BUILDDIR)/libexec/pkgtk/sudo-askpass

$(LIB_FILES): $(LIB_SOURCES)
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk
	@$(INSTALL_FILE) lib/pkgtk/*.tcl $(BUILDDIR)/lib/pkgtk

$(LIB_USERCFG_FILES): $(LIB_USERCFG_SRCS)
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk/usercfg
	@$(INSTALL_FILE) lib/pkgtk/usercfg/*.tcl $(BUILDDIR)/lib/pkgtk/usercfg

$(BUILDDIR)/lib/pkgtk/release-branch.txt: lib/pkgtk/version.tcl
	@if test "$(RELEASE_BRANCH)" != "master"; then \
		echo $(RELEASE_BRANCH) >$(BUILDDIR)/lib/pkgtk/release-branch.txt; \
		echo '$(RELEASE_BRANCH) -> $(BUILDDIR)/lib/pkgtk/release-branch.txt'; \
	fi

### END: BUILD_DEPS

.PHONY: dist
dist: build po-msgfmt
	@$(MKDIR) dist
	@tar -cJf dist/$(RELNAME).txz -C build $(RELNAME)/bin/pkgtk \
					       $(RELNAME)/lib/pkgtk \
					       $(RELNAME)/libexec/pkgtk \
					       $(RELNAME)/share/doc/pkgtk
	touch dist/$(RELNAME).txz

.PHONY: install
install: build po-msgfmt
	@$(MKDIR) $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/libexec/pkgtk \
			$(DESTDIR)$(PREFIX)/lib/pkgtk/usercfg \
			$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs \
			$(DESTDIR)$(PREFIX)/share/doc/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/bin/pkgtk \
				$(DESTDIR)$(PREFIX)/bin/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/gui.tcl \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/repocfg-save \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/sudo-askpass \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/*.tcl \
				$(DESTDIR)$(PREFIX)/lib/pkgtk
	@if test -s $(BUILDDIR)/lib/pkgtk/release-branch.txt; then \
		$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/release-branch.txt \
				$(DESTDIR)$(PREFIX)/lib/pkgtk; fi
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/usercfg/*.tcl \
				$(DESTDIR)$(PREFIX)/lib/pkgtk/usercfg
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/msgs/*.msg \
				$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs
	@$(INSTALL_FILE) $(BUILDDIR)/share/doc/pkgtk/* \
				$(DESTDIR)$(PREFIX)/share/doc/pkgtk

.PHONY: uninstall
uninstall:
	@rm -vf $(DESTDIR)$(PREFIX)/bin/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/libexec/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/lib/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/share/doc/pkgtk

.PHONY: po-update
po-update:
	@$(MAKE) -C po update

.PHONY: po-msgfmt
po-msgfmt:
	@$(MAKE) -C po msgfmt
	@$(MKDIR) $(BUILDDIR)/lib/pkgtk/msgs
	@$(INSTALL_FILE) po/*.msg $(BUILDDIR)/lib/pkgtk/msgs

.PHONY: po-all
po-all:
	@$(MAKE) -C po all

.PHONY: clean
clean:
	@$(MAKE) -C po clean
	@rm -rvf dist build
