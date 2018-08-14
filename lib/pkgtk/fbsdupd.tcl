# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

# support for freebsd-update

package provide fbsdupd 0.0

package require utils

namespace eval ::fbsdupd {
    namespace export can_run
    namespace ensemble create

    variable version_cur ""
    variable cmd_done 0
}

#
# check if the underlying OS release can be managed using freebsd-update tool
#
proc ::fbsdupd::can_run {} {
    try {
        set version_cur [string trim [exec /bin/freebsd-version -r]]
    } trap CHILDSTATUS {results options} {
        set rc [lindex [dict get $options -errorcode] 2]
        puts "ERROR: freebsd-version - rc=$rc"
        puts "ERROR: $results"
        return 0
    }
    if {[string match {*-RELEASE*} $version_cur]} {
        set fbsdupd::version_cur $version_cur
        puts "freebsd-version: $fbsdupd::version_cur"
        return 1
    }
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
    wm minsize $top 600 400
    wm transient $top .
    wm title $top "freebsd-update"
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    menu $top.menu
    $top configure -menu $top.menu

    utils menu_additems $top.menu {
        {mc "Chec_k" command {fbsdupd::fetch}}
        {mc "_Close" command {destroy .fbsdupd}}
    }

    fbsdupd::fetch 0
}

#
# run freebsd-update tool and read lines of output
#
proc ::fbsdupd::run {out cmdname args} {
    set fbsdupd::cmd_done 0
    set cmd [join [list /usr/sbin/freebsd-update $cmdname $args] " "]
    $out insert end "freebsd-update $cmdname\n\n"
    set chan [open "|$cmd" "r"]
    chan configure $chan -blocking 0 -buffering line
    fileevent $chan readable [list fbsdupd::readlines $chan $out $cmdname]
    tkwait variable fbsdupd::cmd_done
}

#
# read a line of output from background process
#
proc ::fbsdupd::readlines {src out cmd} {
    if {[chan gets $src line] >= 0} {
        $out insert end "$line\n"
    }
    if {[chan eof $src]} {
        try {
            chan configure $src -blocking 1
            chan close $src
        } trap CHILDSTATUS {results options} {
            set rc [lindex [dict get $options -errorcode] 2]
            utils show_error "ERROR: freebsd-update $cmd ($rc)\n$results"
            $out insert end "*** ERROR: return code $rc\n"
            $out insert end $results
        } finally {
            set fbsdupd::cmd_done 1
        }
    }
}

#
# freebsd-update fetch
#
proc ::fbsdupd::fetch {{check 1}} {
    set w .fbsdupd.view

    if {[winfo exists $w]} {
        destroy $w.cmdout
    } else {
        ttk::frame $w
        grid columnconfigure $w 0 -weight 1
        grid rowconfigure $w 0 -weight 0
        grid rowconfigure $w 1 -weight 1
        grid $w -row 0 -column 0 -sticky nwse

        ttk::label $w.info -text [format [mc "Current version: %s"] $fbsdupd::version_cur]
        grid $w.info -row 0 -column 0 -sticky nwse
        $w.info configure -padding {1 5}
    }

    text $w.cmdout
    grid $w.cmdout -row 1 -column 0 -sticky nwse

    if {$check} {
        fbsdupd::run $w.cmdout "fetch"
    }
}
