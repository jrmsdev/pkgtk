# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgsearch 0.0

package require utils
package require pkgremote
package require pkgview
package require cmdexec

namespace eval ::pkgsearch {
}

#
# view search packages
#
proc ::pkgsearch::view {w} {
    ttk::frame $w
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 0
    grid rowconfigure $w 1 -weight 1
    grid $w -sticky nwse

    set search $w.search
    ttk::frame $search
    grid rowconfigure $search 0 -weight 1
    grid columnconfigure $search 0 -weight 0
    grid columnconfigure $search 1 -weight 1
    grid $search -sticky nwse

    ttk::label $search.lbl -takefocus 0 -text [mc "Search:"]
    grid $search.lbl -row 0 -column 0 -sticky w

    set query $search.query
    ttk::entry $query
    grid $query -row 0 -column 1 -sticky we

    set paned $w.paned
    ttk::panedwindow $w.paned -orient "horizontal" -takefocus 0
    grid $paned -sticky nwse

    set pkglist $paned.pkglist
    listbox $pkglist
    grid $pkglist -sticky nwse

    $paned add $pkglist -weight 2

    ttk::frame $paned.right
    grid columnconfigure $paned.right 0 -weight 1
    grid rowconfigure $paned.right 0 -weight 1
    grid rowconfigure $paned.right 1 -weight 0
    grid $paned.right -sticky nwse

    set pkgbuttons $paned.right.pkgbuttons
    ttk::frame $pkgbuttons -takefocus 0
    grid $pkgbuttons -row 1 -column 0

    set pkginfo $paned.right.pkginfo
    ttk::label $pkginfo -takefocus 0
    grid $pkginfo -row 0 -column 0
    $pkginfo configure -anchor "center" -justify "left"

    $paned add $paned.right -weight 8

    bind $query <Return> "pkgsearch::run $pkglist $pkginfo $pkgbuttons $query"
    bind $pkglist <<ListboxSelect>> "pkgsearch::show $pkglist $pkginfo $pkgbuttons"

    focus $query
    pkgremote::buttons $pkgbuttons
}

#
# show package info from search
#
proc ::pkgsearch::show {plist pinfo pbtn} {
    set pkgidx [$plist curselection]
    if {$pkgidx >= 0} {
        set pkg [$plist get $pkgidx]
        pkgview::pkg_show $pinfo $pbtn "remote" $pkg
    }
}

#
# pkg search
#
proc ::pkgsearch::run {pkglist pinfo pbtn query} {
    utils tkbusy_hold
    $pkglist delete 0 "end"
    pkgview::pkgbuttons_disable $pbtn
    $pinfo configure -text ""
    set q [$query get]
    if {$q != ""} {
        try {
            foreach line [split [cmdexec search $q] "\n"] {
                $pkglist insert "end" "$line"
            }
            focus $pkglist
        } trap CHILDSTATUS {results options} {
            set rc [lindex [dict get $options -errorcode] 2]
            pkgview::pkgbuttons_disable $pbtn
            $pinfo configure -text ""
            if {$rc == 70} {
                # rc 70 means no results matched
                $pkglist delete 0 "end"
                $query selection range 0 "end"
                focus $query
            } else {
                # so anything else is an error
                utils show_error $results
            }
        }
    }
    utils tkbusy_forget
}
