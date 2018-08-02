TCLSH ?= tclsh8.6
LIB_SOURCES != ls lib/pkgtk/*.tcl | grep -v pkgIndex

.PHONY: all
all: pkgindex

.PHONY: pkgindex
pkgindex: lib/pkgtk/pkgIndex.tcl

lib/pkgtk/pkgIndex.tcl: $(LIB_SOURCES)
	@echo 'pkg_mkIndex -verbose lib/pkgtk *.tcl' | $(TCLSH)
