# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgcmd 0.0

package require utils
package require pkgview

namespace eval ::pkgcmd {
}

#
# run pkg command
#
proc ::pkgcmd::dorun {w cmd args} {
    utils tkbusy_hold $w
    $w.cmdout insert end "pkg $cmd\n\n"
    if {$cmd == "update"} {
        cmdexec::runbg $w.cmdout "$cmd"
    } else {
        if {$args != "NONE"} {
            cmdexec::runbg $w.cmdout "$cmd -y $args"
        } else {
            cmdexec::runbg $w.cmdout "$cmd -y"
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
        cmdexec::runbg $w.cmdout "$cmd -n $args" 1
    } else {
        cmdexec::runbg $w.cmdout "$cmd -n" 1
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
    grid columnconfigure $top 1 -weight 0

    menu $top.menu
    $top configure -menu $top.menu
    if {$dorun} {
        $top.menu add command -label [mc "Close"] -underline 0 \
                              -command {destroy $pkgview::toplevel_child}
    } else {
        $top.menu add command -label [format [mc "Confirm %s"] $cmd] \
                              -underline 0 \
                              -command "pkgcmd::view $cmd $args 1"
        $top.menu add command -label [mc "Cancel"] -underline 2 \
                              -command {destroy $pkgview::toplevel_child}
    }

    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid rowconfigure $w 1 -weight 0
    grid columnconfigure $w 0 -weight 1
    grid $w -sticky nwse

    ttk::scrollbar $top.vsb -orient "vertical" -command [list $w.cmdout yview]
    grid $top.vsb -row 0 -column 1 -sticky nwse

    text $w.cmdout -yscrollcommand [list $top.vsb set]
    grid $w.cmdout -row 0 -column 0 -sticky nwse

    ttk::progressbar $w.pgb -orient "horizontal" -mode "determinate" -value 0
    grid $w.pgb -row 1 -column 0 -sticky we

    if {$dorun} {
        pkgcmd::dorun $w $cmd $args
    } else {
        pkgcmd::dryrun $w $cmd $args
    }

    tkwait window $top
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
# view pkg update command
#
proc ::pkgcmd::view_update {} {
    pkgcmd::view "update" "" 1
}
