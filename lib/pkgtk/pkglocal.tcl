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
proc ::pkglocal::view {w} {
    pkgview::pkgtree_view $w "local" [pkglocal::list]
}

#
# pkg list local (installed) packages
#
proc ::pkglocal::list {} {
    try {
        return [lsort [split [cmdexec lslocal]]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}
