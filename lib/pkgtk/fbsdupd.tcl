# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

# support for freebsd-update

package provide fbsdupd 0.0

package require utils
package require style

namespace eval ::fbsdupd {
    namespace export can_run
    namespace ensemble create

    variable version_cur ""
    variable cmd_done 0
    variable cmd_error 0
    variable progressbar {}
    variable cmdout {}
    variable buttons {}
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
        # set PAGER env var as /bin/cat to avoid blocking freebsd-update output
        set ::env(PAGER) /bin/cat
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
    wm title $top [mc "FreeBSD system update"]
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    menu $top.menu
    $top configure -menu $top.menu

    utils menu_additems $top.menu {
        {mc "_Close" command {destroy .fbsdupd}}
    }

    set w .fbsdupd.view
    ttk::frame $w
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 0
    grid rowconfigure $w 1 -weight 1
    grid rowconfigure $w 2 -weight 0
    grid $w -row 0 -column 0 -sticky nwse

    set fbsdupd::buttons $w.btns
    ttk::frame $w.btns
    grid columnconfigure $w.btns 0 -weight 1
    grid columnconfigure $w.btns 1 -weight 0
    grid rowconfigure $w.btns 0 -weight 1
    grid $w.btns -row 0 -column 0 -sticky nwse
    $w.btns configure -padding 1

    ttk::label $w.btns.lbl \
               -text [format [mc "Current version: %s"] $fbsdupd::version_cur]
    grid $w.btns.lbl -row 0 -column 0 -sticky nwse

    ttk::button $w.btns.install -text [mc "Install"] -command {fbsdupd::install}
    grid $w.btns.install -row 0 -column 1 -sticky e
    $w.btns.install configure -state "disabled"

    ttk::frame $w.outf
    grid rowconfigure $w.outf 0 -weight 1
    grid columnconfigure $w.outf 0 -weight 1
    grid columnconfigure $w.outf 1 -weight 0
    grid $w.outf -row 1 -column 0 -sticky nwse

    ttk::scrollbar $w.outf.vsb -orient "vertical" \
                               -command [list $w.outf.cmdout yview]
    grid $w.outf.vsb -row 0 -column 1 -sticky nwse

    set fbsdupd::cmdout $w.outf.cmdout
    text $w.outf.cmdout -yscrollcommand [list $w.outf.vsb set]
    grid $w.outf.cmdout -row 0 -column 0 -sticky nwse
    $w.outf.cmdout configure -state "disabled"
    style cmdout $w.outf.cmdout

    set fbsdupd::progressbar $w.pgb
    ttk::progressbar $w.pgb -orient "horizontal" -mode "determinate" -value 0
    grid $w.pgb -row 2 -column 0 -sticky we
}

#
# run freebsd-update tool and read lines of output
#
proc ::fbsdupd::run {out cmdname args} {
    set pgb $fbsdupd::progressbar
    utils tkbusy_hold .fbsdupd
    $pgb configure -mode "indeterminate"
    $pgb start
    set fbsdupd::cmd_done 0
    set fbsdupd::cmd_error 0
    set cmd [join [list /usr/local/bin/sudo -n /usr/sbin/freebsd-update $cmdname $args] " "]
    $out configure -state "normal"
    $out insert end "freebsd-update $cmdname\n\n"
    set chan [open "|$cmd" "r"]
    chan configure $chan -blocking 0 -buffering line
    fileevent $chan readable [list fbsdupd::readlines $chan $out $cmdname]
    tkwait variable fbsdupd::cmd_done
    $out configure -state "disabled"
    $pgb stop
    $pgb configure -mode "determinate"
    utils tkbusy_forget .fbsdupd
}

#
# read a line of output from background process
#
proc ::fbsdupd::readlines {src out cmd} {
    if {[chan gets $src line] >= 0} {
        $out insert end "$line\n"
        $out see end
    }
    if {[chan eof $src]} {
        chan configure $src -blocking 1
        if {[catch {chan close $src} err]} {
            set fbsdupd::cmd_error 1
            utils show_error "ERROR: freebsd-update $cmd\n\n$err"
            $out insert end "*** ERROR ***\n" {cmderror}
            $out insert end $err {cmderror}
            $out see end
        }
        set fbsdupd::cmd_done 1
    }
}

#
# freebsd-update fetch
#
proc ::fbsdupd::fetch {} {
    fbsdupd::view

    set cmdout $fbsdupd::cmdout
    set btns $fbsdupd::buttons

    $cmdout configure -state "normal"
    $cmdout delete 0.0 end
    $cmdout configure -state "disabled"

    $btns.install configure -state "disabled"

    fbsdupd::run $cmdout "fetch"

    if {$fbsdupd::cmd_error == 0} {
        $btns.install configure -state "enabled"
    }
}

#
# freebsd-update install
#
proc ::fbsdupd::install {} {
    set cmdout $fbsdupd::cmdout
    set btns $fbsdupd::buttons
    $btns.install configure -state "disabled"
    $cmdout configure -state "normal"
    $cmdout delete 0.0 end
    $cmdout configure -state "disabled"
    fbsdupd::run $cmdout "install"
}

#
# ask for the new release version and run upgrade
#
proc ::fbsdupd::release_upgrade {} {
    fbsdupd::view

    set ::fbsdupd_new_release ""

    set top .fbsdupd.release_target
    if {[winfo exists $top]} {
        destroy $top
    }

    toplevel $top
    #~ wm minsize $top 300 200
    wm transient $top .fbsdupd
    wm title $top [mc "FreeBSD release target"]
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid rowconfigure $w 1 -weight 1
    grid columnconfigure $w 0 -weight 0
    grid columnconfigure $w 1 -weight 1
    grid $w -row 0 -column 0 -sticky nwse
    $w configure -padding 1

    ttk::label $w.lbl -text [mc "Release target:"]
    grid $w.lbl -row 0 -column 0 -sticky w

    ttk::entry $w.new_release -textvariable ::fbsdupd_new_release
    grid $w.new_release -row 0 -column 1 -sticky we

    ttk::label $w.exrel -text [format "%s: 11.3 or 11.3-RELEASE" [mc "Example"]]
    grid $w.exrel -row 1 -column 1 -sticky w

    bind $w.new_release <Return> "fbsdupd::newrel_check $top"
    focus $w.new_release

    tkwait window $top

    set ::fbsdupd_new_release [string trim $::fbsdupd_new_release]
    if {$::fbsdupd_new_release != ""} {
        fbsdupd::upgrade $::fbsdupd_new_release
    }
}

#
# check new release target from user input
#
proc ::fbsdupd::newrel_check {top} {
    set ::fbsdupd_new_release [string trim $::fbsdupd_new_release]
    if {$::fbsdupd_new_release != ""} {
        destroy $top
    }
}

#
# freebsd-update upgrade
#
proc ::fbsdupd::upgrade {new_release} {
    set cmdout $fbsdupd::cmdout
    set btns $fbsdupd::buttons

    $cmdout configure -state "normal"
    $cmdout delete 0.0 end
    $cmdout configure -state "disabled"

    $btns.install configure -state "disabled"

    set cfgfile [fbsdupd::config]
    fbsdupd::run $cmdout "upgrade" "-f" $cfgfile "-r" $new_release
    file delete -force -- $cfgfile

    if {$fbsdupd::cmd_error == 0} {
        $btns.install configure -state "enabled"
    }
}

#
# generate a custom freebsd-update.conf file
#   return generated filename
#
proc ::fbsdupd::config {} {
    set fn "NONE"

    set fh [file tempfile fn ".pkgtk.freebsd-update.conf"]
    set src [open /etc/freebsd-update.conf "r"]

    while {[gets $src line] >= 0} {
        set line [string trim $line]
        if {$line == ""} {
            continue
        } elseif {[string match {\#*} $line]} {
            continue
        } else {
            set opt [lindex [split $line " "] 0]
            if {[string tolower $opt] == {strictcomponents}} {
                # will override StrictComponents setting
                # to avoid blocking on confirmation
                continue
            } else {
                puts $fh $line
            }
        }
    }
    close $src

    # override settings
    puts $fh "StrictComponents yes"

    close $fh
    return $fn
}
