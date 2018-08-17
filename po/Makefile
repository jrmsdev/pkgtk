LIB_SOURCES != ls ../lib/pkgtk/*.tcl | grep -v pkgIndex
LIB_USERCFG_SRCS != ls ../lib/pkgtk/usercfg/*.tcl | grep -v pkgIndex

PO_TEMPLATE := pkgtk.pot
PO_SOURCES := ../libexec/pkgtk/gui.tcl $(LIB_SOURCES) $(LIB_USERCFG_SRCS)
PO_FILES != ls *.po 2>/dev/null || true
MSG_RELNAMES != for pof in $(PO_FILES); do echo `basename $$pof .po`; done

.PHONY: all
all: update msgfmt

$(PO_TEMPLATE): $(PO_SOURCES)
	xgettext -d pkgtk -o $(PO_TEMPLATE) -LTcl -kmc -F $(PO_SOURCES)

.PHONY: update
update: $(PO_TEMPLATE)
	@for pof in $(PO_FILES); do \
		echo -n "msgmerge $$pof"; \
		msgmerge --backup off -U $$pof $(PO_TEMPLATE); \
	done

.PHONY: msgfmt
msgfmt:
	@for reln in $(MSG_RELNAMES); do \
		rm -f $${reln}.msg; \
		touch $${reln}.msg; \
		echo -n "msgfmt $${reln}.po... "; \
		msgfmt --statistics --tcl $${reln}.msg -d . \
				-l $$(basename $$reln) $${reln}.po; \
	done

.PHONY: clean
clean:
	@rm -vf $(PO_TEMPLATE) *.msg
