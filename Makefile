TCLSH ?= tclsh8.6

.PHONY: all
all: pkgindex

.PHONY: pkgindex
pkgindex:
	@echo '** lib/pkgtk'
	@echo 'pkg_mkIndex -direct -verbose lib/pkgtk *.tcl' | $(TCLSH)
