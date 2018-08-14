SH := /bin/sh
USER_HOME != echo ~

PREFIX ?= $(USER_HOME)
DESTDIR ?=
TCLSH ?= tclsh8.6
SUDOERS_GROUP ?= wheel

RELEASE != $(SH) -e mk/get-release.sh $(TCLSH)
RELNAME := pkgtk-$(RELEASE)
BUILDDIR := build/$(RELNAME)
INSTALL_EXE := install -v -C -h md5 -m 0755
INSTALL_FILE := install -v -C -h md5 -m 0644
INSTALL_ROFILE := install -v -C -h md5 -m 0440

LIB_SOURCES != ls lib/pkgtk/*.tcl | grep -v pkgIndex
LIB_FILES != for relp in $(LIB_SOURCES); do echo $(BUILDDIR)/$$relp; done
BUILD_DEPS := $(BUILDDIR)/bin/pkgtk $(BUILDDIR)/libexec/pkgtk/gui.tcl $(LIB_FILES)

PO_TEMPLATE := po/pkgtk.pot
PO_SOURCES := libexec/pkgtk/gui.tcl $(LIB_SOURCES)
PO_FILES != ls po/*.po 2>/dev/null || true
MSG_RELNAMES != for pofile in $(PO_FILES); do echo po/`basename $$pofile .po`; done

.PHONY: all
all: build

.PHONY: pkgindex
pkgindex: lib/pkgtk/pkgIndex.tcl

lib/pkgtk/pkgIndex.tcl: $(LIB_SOURCES)
	@echo 'pkg_mkIndex lib/pkgtk *.tcl' | $(TCLSH)
	touch lib/pkgtk/pkgIndex.tcl

.PHONY: build
build: pkgindex po-msgfmt $(BUILD_DEPS) $(BUILDDIR)/etc/sudoers.d/pkgtk
	@mkdir -vp $(BUILDDIR)/share/doc/pkgtk
	@$(INSTALL_FILE) LICENSE README.md $(BUILDDIR)/share/doc/pkgtk
	@mkdir -vp $(BUILDDIR)/lib/pkgtk/msgs
	@$(INSTALL_FILE) po/*.msg $(BUILDDIR)/lib/pkgtk/msgs

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

$(BUILDDIR)/etc/sudoers.d/pkgtk: etc/sudoers.d/pkgtk
	@mkdir -vp $(BUILDDIR)/etc/sudoers.d
	@cat etc/sudoers.d/pkgtk | \
		sed 's/%wheel/%$(SUDOERS_GROUP)/' >$(BUILDDIR)/etc/sudoers.d/pkgtk
	@touch $(BUILDDIR)/etc/sudoers.d/pkgtk

.PHONY: dist
dist: build
	@mkdir -vp dist
	@tar -cJf dist/$(RELNAME).txz -C build $(RELNAME)/bin/pkgtk \
					       $(RELNAME)/lib/pkgtk \
					       $(RELNAME)/libexec/pkgtk \
					       $(RELNAME)/share/doc/pkgtk \
					       $(RELNAME)/etc/sudoers.d/pkgtk
	touch dist/$(RELNAME).txz

.PHONY: install
install: build
	@mkdir -vp $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/libexec/pkgtk \
			$(DESTDIR)$(PREFIX)/lib/pkgtk \
			$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs \
			$(DESTDIR)$(PREFIX)/share/doc/pkgtk \
			$(DESTDIR)$(PREFIX)/etc/sudoers.d
	@$(INSTALL_EXE) $(BUILDDIR)/bin/pkgtk \
				$(DESTDIR)$(PREFIX)/bin/pkgtk
	@$(INSTALL_EXE) $(BUILDDIR)/libexec/pkgtk/gui.tcl \
				$(DESTDIR)$(PREFIX)/libexec/pkgtk/gui.tcl
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/*.tcl \
				$(DESTDIR)$(PREFIX)/lib/pkgtk
	@$(INSTALL_FILE) $(BUILDDIR)/lib/pkgtk/msgs/*.msg \
				$(DESTDIR)$(PREFIX)/lib/pkgtk/msgs
	@$(INSTALL_FILE) $(BUILDDIR)/share/doc/pkgtk/* \
				$(DESTDIR)$(PREFIX)/share/doc/pkgtk
	@$(INSTALL_ROFILE) $(BUILDDIR)/etc/sudoers.d/pkgtk \
				$(DESTDIR)$(PREFIX)/etc/sudoers.d/pkgtk

.PHONY: uninstall
uninstall:
	@rm -vf $(DESTDIR)$(PREFIX)/bin/pkgtk
	@rm -vf $(DESTDIR)$(PREFIX)/etc/sudoers.d/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/libexec/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/lib/pkgtk
	@rm -vrf $(DESTDIR)$(PREFIX)/share/doc/pkgtk

$(PO_TEMPLATE): $(PO_SOURCES)
	xgettext -d pkgtk -o $(PO_TEMPLATE) -LTcl -kmc -F $(PO_SOURCES)

.PHONY: po-update
po-update: $(PO_TEMPLATE)
	@for pofile in $(PO_FILES); do echo -n "msgmerge $$pofile"; \
			msgmerge --backup off -U $$pofile $(PO_TEMPLATE); done

.PHONY: po-msgfmt
po-msgfmt:
	@for reln in $(MSG_RELNAMES); do \
		rm -f $${reln}.msg; \
		touch $${reln}.msg; \
		echo -n "msgfmt $${reln}.po... "; \
		msgfmt --statistics --tcl $${reln}.msg -l $$(basename $$reln) -d po $${reln}.po; \
	done

.PHONY: po-all
po-all: po-update po-msgfmt

.PHONY: clean
clean:
	@rm -rvf dist build
	@rm -vf $(PO_TEMPLATE) po/*.msg
