TCLSH ?= tclsh8.6

.PHONY: all
all: pkgindex

.PHONY: pkgindex
pkgindex:
	@echo 'pkg_mkIndex -direct -verbose lib/pkgtk init.tcl' | $(TCLSH)
