# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgcmd 0.0

package require utils
package require style
package require cmdexec
package require pkgview

namespace eval ::pkgcmd {
}

#
# run pkg command
#
proc ::pkgcmd::dorun {out cmd args} {
    $out insert end "pkg $cmd\n\n"
    if {$cmd == "update"} {
        cmdexec::runbg $out "$cmd"
    } else {
        if {$args != "NONE"} {
            cmdexec::runbg $out "$cmd -y $args"
        } else {
            cmdexec::runbg $out "$cmd -y"
        }
    }
    $out configure -state "disabled"
}

#
# run pkg command (dry run), whitout applying any changes to the system
#
proc ::pkgcmd::dryrun {out cmd args} {
    $out insert end "pkg $cmd (dry run)\n\n"
    if {$args != "NONE"} {
        cmdexec::runbg $out "$cmd -n $args" 1
    } else {
        cmdexec::runbg $out "$cmd -n" 1
    }
    $out configure -state "disabled"
}

#
# check if the last command failed
#
proc ::pkgcmd::failed {} {
    return $cmdexec::failed
}

#
# pkg command view
#
proc ::pkgcmd::view {cmd {args "NONE"} {dorun 0} {autoclose "NONE"}} {
    set top $pkgview::toplevel_child
    if {[winfo exists $top]} {
        destroy $top
    }

    toplevel $top
    wm minsize $top 600 400
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
    set cmdout $w.outf.cmdout

    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid rowconfigure $w 1 -weight 0
    grid columnconfigure $w 0 -weight 1
    grid $w -sticky nwse

    ttk::frame $w.outf
    grid rowconfigure $w.outf 0 -weight 1
    grid columnconfigure $w.outf 0 -weight 1
    grid columnconfigure $w.outf 1 -weight 0
    grid $w.outf -row 0 -column 0 -sticky nwse

    ttk::scrollbar $w.outf.vsb -orient "vertical" -command [list $cmdout yview]
    grid $w.outf.vsb -row 0 -column 1 -sticky nwse

    text $cmdout -yscrollcommand [list $w.outf.vsb set]
    grid $cmdout -row 0 -column 0 -sticky nwse
    style cmdout $cmdout

    ttk::progressbar $w.pgb -orient "horizontal" -mode "determinate" -value 0
    grid $w.pgb -row 1 -column 0 -sticky we
    set cmdexec::progressbar $w.pgb

    utils tkbusy_hold $w
    if {$dorun} {
        pkgcmd::dorun $cmdout $cmd $args
    } else {
        pkgcmd::dryrun $cmdout $cmd $args
    }
    utils tkbusy_forget $w

    if {$autoclose == "autoclose"} {
        if {[pkgcmd::failed]} {
            tkwait window $top
        } else {
            after 1500
            destroy $top
        }
    } else {
        tkwait window $top
    }
}

#
# view pkg upgrade command
#
proc ::pkgcmd::view_upgrade {{reload "NONE"} {all "NONE"}} {
    if {$all != "NONE"} {
        pkgcmd::view "upgrade"
    } else {
        set pkg $pkgview::pkg_selected
        pkgcmd::view "upgrade" $pkg
    }
    if {$reload == "reload"} {
        utils dispatch_view pkglocal::view
    }
}

#
# view pkg remove command
#   TODO: support adding -R arg
#
proc ::pkgcmd::view_remove {{reload "none"}} {
    set pkg $pkgview::pkg_selected
    pkgcmd::view "remove" $pkg
    if {$reload == "reload"} {
        utils dispatch_view pkglocal::view
    }
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
proc ::pkgcmd::view_install {{reload "none"}} {
    set pkg $pkgview::pkg_selected
    pkgcmd::view "install" $pkg
    if {$reload == "reload"} {
        utils dispatch_view pkgremote::view
    }
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
proc ::pkgcmd::view_update {{autoclose "noauto"}} {
    pkgcmd::view "update" "" 1 $autoclose
}
