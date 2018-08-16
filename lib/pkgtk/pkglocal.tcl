# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkglocal 0.0

package require utils
package require pkgview
package require pkgcmd
package require cmdexec

namespace eval ::pkglocal {
}

#
# installed pkg action buttons
#
proc ::pkglocal::buttons {w} {
    ttk::button $w.remove -text [mc "Remove"] -state "disabled" \
                          -command {pkgcmd::view_remove "reload"}
    grid $w.remove -row 0 -column 0
    ttk::button $w.upgrade -text [mc "Upgrade"] -state "disabled" \
                          -command {pkgcmd::view_upgrade "reload"}
    grid $w.upgrade -row 0 -column 1
}

#
# view local (installed) packages
#
proc ::pkglocal::view {w {inc "noauto"}} {
    pkgview::pkgtree_view $w "local" [pkglocal::list $inc]
}

#
# pkg list local (installed) packages
#
proc ::pkglocal::list {inc} {
    try {
        return [lsort [split [cmdexec lslocal $inc]]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}

#
# show pkg local view options
#
proc ::pkglocal::options {parent inc} {
    grid rowconfigure $parent 0 -weight 1
    grid columnconfigure $parent 0 -weight 0
    grid columnconfigure $parent 1 -weight 1

    ttk::label $parent.inc_lbl -text [mc "Include:"]
    grid $parent.inc_lbl -row 0 -column 0 -sticky w

    ttk::label $parent.inc -text $inc
    grid $parent.inc -row 0 -column 1 -sticky w
}
