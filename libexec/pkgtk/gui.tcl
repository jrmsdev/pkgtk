#!/usr/bin/env tclsh8.6

# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package require Tcl 8.6
package require msgcat

namespace import msgcat::mc
if {[info exists ::env(PKGTK_MSGSDIR)]} {
    msgcat::mcload $::env(PKGTK_MSGSDIR)
}

package require pkgtk
pkgtk main
