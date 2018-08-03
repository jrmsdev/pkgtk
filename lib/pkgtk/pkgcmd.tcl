# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgcmd 0.0
package require utils

namespace eval ::pkgcmd {
    # global vars
    variable pkgcmd_run 0
    variable pkgcmd_top .pkgcmdview
}

#
# view pkg upgrade command
#
proc ::pkgcmd::view_upgrade {{all "NONE"}} {
    if {$all != "NONE"} {
        pkgcmd::view "upgrade"
    } else {
        set pkg $pkgview::pkg_selected
        pkgcmd::view "upgrade" $pkg
    }
}

#
# view pkg remove command
#   TODO: support adding -R arg
#
proc ::pkgcmd::view_remove {} {
    set pkg $pkgview::pkg_selected
    pkgcmd::view "remove" $pkg
}

#
# view pkg clean cache command
#
proc ::pkgcmd::view_clean_cache {} {
    pkgcmd::view "clean" "-a"
}

#
# view pkg install command
#
proc ::pkgcmd::view_install {} {
    set pkg $pkgview::pkg_selected
    pkgcmd::view "install" $pkg
}

#
# view pkg autoremove command
#
proc ::pkgcmd::view_autoremove {} {
    pkgcmd::view "autoremove"
}

#
# run pkg command
#
proc ::pkgcmd::dorun {w cmd args} {
    utils tkbusy_hold $w
    try {
        $w.cmdout insert end "pkg $cmd\n\n"
        if {$cmd == "update"} {
            $w.cmdout insert end [exec pkg $cmd]
        } else {
            if {$args != "NONE"} {
                $w.cmdout insert end [exec pkg $cmd -y $args]
            } else {
                $w.cmdout insert end [exec pkg $cmd -y]
            }
        }
        $w.cmdout configure -state "disabled"
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
    utils tkbusy_forget $w
}

#
# run pkg command (dry run), whitout applying any changes to the system
#
proc ::pkgcmd::dryrun {w cmd args} {
    utils tkbusy_hold $w
    try {
        $w.cmdout insert end "pkg $cmd (dry run)\n\n"
        if {$args != "NONE"} {
            $w.cmdout insert end [exec pkg $cmd -n $args]
        } else {
            $w.cmdout insert end [exec pkg $cmd -n]
        }
    } trap CHILDSTATUS {results options} {
        set rc [lindex [dict get $options -errorcode] 2]
        if {$rc > 1} {
            utils show_error $results
        } else {
            $w.cmdout insert end $results
        }
    }
    $w.cmdout configure -state "disabled"
    utils tkbusy_forget $w
}

#
# pkg command view
#
proc ::pkgcmd::view {cmd {args "NONE"} {dorun 0}} {
    set pkgcmd::pkgcmd_run 0
    set top $pkgcmd::pkgcmd_top
    if {[winfo exists $top]} {
        destroy $top
    }
    toplevel $top
    wm transient $top .
    wm title $top "pkg $cmd"
    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid rowconfigure $w 1 -weight 9
    grid columnconfigure $w 0 -weight 1
    grid $w -sticky nwse
    ttk::frame $w.btn
    grid $w.btn -row 0 -column 0 -sticky nwse
    if {$dorun} {
        ttk::button $w.btn.close -text "Close" \
                                 -command {destroy $pkgcmd::pkgcmd_top}
        grid $w.btn.close -row 0 -column 0 -sticky w
    } else {
        ttk::button $w.btn.run -text "Confirm $cmd" \
                               -command {set pkgcmd::pkgcmd_run 1}
        grid $w.btn.run -row 0 -column 0 -sticky w
        ttk::button $w.btn.cancel -text "Cancel" \
                                  -command {destroy $pkgcmd::pkgcmd_top}
        grid $w.btn.cancel -row 0 -column 1 -sticky w
    }
    text $w.cmdout
    grid $w.cmdout -row 1 -column 0 -sticky nwse
    if {$dorun} {
        pkgcmd::dorun $w $cmd $args
    } else {
        pkgcmd::dryrun $w $cmd $args
        vwait pkgcmd::pkgcmd_run
        if {$pkgcmd::pkgcmd_run} {
            pkgcmd::view $cmd $args 1
        }
    }
}

#
# view pkg update command
#
proc ::pkgcmd::view_update {} {
    pkgcmd::view "update" "" 1
}
