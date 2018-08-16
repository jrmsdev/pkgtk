# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgtk 0.0
package require Tk 8.6

package require utils
package require pkglocal
package require pkgremote
package require pkgsearch
package require pkgview
package require pkgcmd
package require pkgrepo
package require img
package require version
package require fbsdupd
package require usercfg

namespace eval ::pkgtk {
    namespace export main
    namespace ensemble create
}

#
# view about info
#
proc ::pkgtk::view_about {} {
    set top $pkgview::toplevel_child
    if {[winfo exists $top]} {
        destroy $top
    }
    toplevel $top
    wm transient $top .
    wm title $top [mc "About pkgtk"]
    ttk::label $top.info
    grid $top.info -sticky nwse
    set txt [format "pkgtk v%s\n\n" $version::VERSION]
    set txt [format "%s%s\n" $txt [mc "FreeBSD package manager"]]
    set txt [format "%s(r%s)\n\n" $txt $version::RELEASE]
    set txt [format "%shttps://gitlab.com/jrmsdev/pkgtk\n\n" $txt]
    set txt [format "%s%s\n" $txt [mc "Released under BSD license (see LICENSE file)"]]
    set txt [format "%sCopyright (c) 2018 Jeremías Casteglione <jrmsdev@gmail.com>" $txt]
    $top.info configure -justify "center" -padding {10} \
                        -font "monospace 10 bold" -text $txt
    tkwait window $top
}

#
# main menu
#
proc ::pkgtk::main_menu {} {
    menu .menu
    . configure -menu .menu

    utils menu_cascade .menu "packages" [mc "_Packages"] {
        {mc "_Installed" command {utils dispatch_view pkglocal::view}}
        {mc "_Upgrade" command {pkgcmd::view_upgrade "noreload" "all"}}
        {s0 "" separator {}}
        {mc "_Available" command {utils dispatch_view pkgremote::view}}
        {mc "_Search" command {utils dispatch_view pkgsearch::view}}
        {s1 "" separator {}}
        {mc "Auto_remove" command {pkgcmd::view_autoremove}}
        {mc "_Clean cache" command {pkgcmd::view_clean_cache}}
        {s2 "" separator {}}
        {mc "_Quit" command {pkgtk::quit 0}}
    }

    utils menu_cascade .menu "repos" [mc "_Repositories"] {
        {mc "_Configuration" command {utils dispatch_view pkgrepo::view}}
        {mc "_Update" command {pkgcmd::view_update}}
    }

    if {[fbsdupd can_run]} {
        utils menu_additems .menu {
            {mc "_System" command {fbsdupd::view}}
        }
    }

    utils menu_additems .menu {
        {mc "Pre_ferences" command {usercfg view}}
        {mc "_About" command {pkgtk::view_about}}
    }
}

#
# exit main loop
#
proc ::pkgtk::quit {rc} {
    if {[winfo exists $pkgview::toplevel_child]} {
        destroy $pkgview::toplevel_child
    }
    if {[winfo exists .fbsdupd]} {
        destroy .fbsdupd
    }
    destroy .
    exit $rc
}

#
# main
#
proc ::pkgtk::main {} {
    wm title . [mc "FreeBSD package manager"]
    wm minsize . 800 600
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 0 -weight 1
    . configure -padx 1 -pady 1
    img create_icon .
    pkgtk::main_menu
    utils dispatch_view pkglocal::view
}
