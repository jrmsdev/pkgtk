# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

# support for freebsd-update

package provide fbsdupd 0.0

namespace eval ::fbsdupd {
    namespace export can_run
    namespace ensemble create
}

#
# check if the underlying OS release can be managed using freebsd-update tool
#
proc ::fbsdupd::can_run {} {
    return 0
}

#
# main (toplevel) view
#
proc ::fbsdupd::view {} {
    set top .fbsdupd
    if {[winfo exists $top]} {
        destroy $top
    }

    toplevel $top
    wm transient $top .
    wm title $top "freebsd-update"
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    menu $top.menu
    $top configure -menu $top.menu
}
