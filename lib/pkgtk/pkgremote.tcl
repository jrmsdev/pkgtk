# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgremote 0.0

package require utils
package require pkgview
package require pkgcmd
package require cmdexec
package require usercfg

namespace eval ::pkgremote {
}

#
# available pkg action buttons
#
proc ::pkgremote::buttons {w {reload "none"}} {
    ttk::button $w.install -text [mc "Install"] -state {disabled} \
                           -command "pkgcmd::view_install $reload"
    grid $w.install -row 0 -column 0 -sticky w
}

#
# view remote (available) packages
#
proc ::pkgremote::view {w} {
    pkgview::pkgtree_view $w "remote" [pkgremote::list]
}

#
# pkg list remote (available) packages
#
proc ::pkgremote::list {} {
    set excl [usercfg get_bool pkg remote.exclude_installed]
    try {
        return [lsort [split [cmdexec lsremote $excl]]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}

#
# show pkg remote view options
#
proc ::pkgremote::options {parent} {
    grid rowconfigure $parent 0 -weight 1
    grid columnconfigure $parent 0 -weight 0
    grid columnconfigure $parent 1 -weight 1

    ttk::label $parent.excl_lbl -text [mc "Exclude installed:"]
    grid $parent.excl_lbl -row 0 -column 0 -sticky w

    set curval [usercfg get pkg remote.exclude_installed]
    usercfg editor $parent.excl pkg remote.exclude_installed $curval
    grid $parent.excl -row 0 -column 1 -sticky w
}
