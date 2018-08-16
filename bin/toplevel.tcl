#!/usr/bin/env tclsh8.6

package require Tcl
package require Tk
package require msgcat

namespace import msgcat::mc
if {[info exists ::env(PKGTK_MSGSDIR)]} {
    msgcat::mcload $::env(PKGTK_MSGSDIR)
}

wm title . "ugly toplevel child window launcher just for devel!!!!!"

set pkgpath [lindex $::argv 0]
set procname [lindex $::argv 1]

package require $pkgpath

eval [join [list $pkgpath $procname] "::"]

#~ wm title . "ugly toplevel child window launcher just for devel!!!!!"
#~ wm minsize . 800 600
#~ grid rowconfigure . 0 -weight 1
#~ grid columnconfigure . 0 -weight 1
#~ . configure -padx 1 -pady 1

#~ eval [join [list $pkgpath $procname] "::"] .
