# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgcmd 0.0
package require utils
package require pkgview

namespace eval ::pkgcmd {
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
# run command in background and insert lines of output
#
proc ::pkgcmd::runbg {out cmd {dryrun 0}} {
    set chan [open "|$cmd" "r"]
    while {[gets $chan line] >= 0} {
        $out insert end "$line\n"
        update
    }
    try {
        close $chan
    } trap CHILDSTATUS {results options} {
        set rc [lindex [dict get $options -errorcode] 2]
        if {$dryrun && $rc == 1} {
            return
        } else {
            utils show_error "ERROR: $cmd ($rc)\n$results"
            $out insert end "*** ERROR: return code $rc\n"
            $out insert end $results
            update
        }
    }
}

#
# run pkg command
#
proc ::pkgcmd::dorun {w cmd args} {
    utils tkbusy_hold $w
    $w.cmdout insert end "pkg $cmd\n\n"
    if {$cmd == "update"} {
        pkgcmd::runbg $w.cmdout "pkg $cmd"
    } else {
        if {$args != "NONE"} {
            pkgcmd::runbg $w.cmdout "pkg $cmd -y $args"
        } else {
            pkgcmd::runbg $w.cmdout "pkg $cmd -y"
        }
    }
    $w.cmdout configure -state "disabled"
    utils tkbusy_forget $w
}

#
# run pkg command (dry run), whitout applying any changes to the system
#
proc ::pkgcmd::dryrun {w cmd args} {
    utils tkbusy_hold $w
    $w.cmdout insert end "pkg $cmd (dry run)\n\n"
    if {$args != "NONE"} {
        pkgcmd::runbg $w.cmdout "pkg $cmd -n $args" 1
    } else {
        pkgcmd::runbg $w.cmdout "pkg $cmd -n" 1
    }
    $w.cmdout configure -state "disabled"
    utils tkbusy_forget $w
}

#
# pkg command view
#
proc ::pkgcmd::view {cmd {args "NONE"} {dorun 0}} {
    set top $pkgview::toplevel_child
    if {[winfo exists $top]} {
        destroy $top
    }
    toplevel $top
    wm transient $top .
    wm title $top "pkg $cmd"
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1
    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 0
    grid rowconfigure $w 1 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w -sticky nwse
    ttk::frame $w.btn
    grid $w.btn -row 0 -column 0 -sticky nwse
    if {$dorun} {
        ttk::button $w.btn.close -text [mc "Close"] \
                                 -command {destroy $pkgview::toplevel_child}
        grid $w.btn.close -row 0 -column 0 -sticky w
    } else {
        ttk::button $w.btn.run -text [format [mc "Confirm %s"] $cmd] \
                               -command "pkgcmd::view $cmd $args 1"
        grid $w.btn.run -row 0 -column 0 -sticky w
        ttk::button $w.btn.cancel -text [mc "Cancel"] \
                                  -command {destroy $pkgview::toplevel_child}
        grid $w.btn.cancel -row 0 -column 1 -sticky w
    }
    text $w.cmdout
    grid $w.cmdout -row 1 -column 0 -sticky nwse
    if {$dorun} {
        pkgcmd::dorun $w $cmd $args
    } else {
        pkgcmd::dryrun $w $cmd $args
    }
    tkwait window $top
}

#
# view pkg update command
#
proc ::pkgcmd::view_update {} {
    pkgcmd::view "update" "" 1
}
