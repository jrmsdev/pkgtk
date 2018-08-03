# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgremote 0.0
package require utils
package require pkgview
package require pkgcmd

namespace eval ::pkgremote {
}

#
# available pkg action buttons
#
proc ::pkgremote::buttons {w} {
    ttk::button $w.install -text {Install} -state {disabled} \
                           -command {pkgcmd::view_install}
    grid $w.install -row 0 -column 0 -sticky w
}

#
# view remote (available) packages
#
proc ::pkgremote::view {w} {
    pkgview::pkgtree_view $w "Available" [pkgremote::list]
}

#
# pkg list remote (available) packages
#
proc ::pkgremote::list {} {
    try {
        return [split [exec pkg rquery -a {%o|%n-%v} | sort]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}
