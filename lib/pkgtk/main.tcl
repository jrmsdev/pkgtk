# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgtk 0.0
package require Tk 8.6
package require utils
package require pkgview
package require pkgcmd

namespace eval ::pkgtk {
    namespace export main
    namespace ensemble create

    variable VERSION 0.0
    variable RELEASE 180802
}

#
# view about info
#
proc ::pkgtk::view_about {} {
    #~ global VERSION RELEASE
    set top .about
    if {[winfo exists $top]} {
        destroy $top
    }
    toplevel $top
    wm transient $top .
    wm title $top "about pkgtk"
    ttk::label $top.info
    grid $top.info -sticky nwse
    $top.info configure -justify "center" -padding {10 0} \
-font "monospace 10 bold" -text "
pkgtk v$pkgtk::VERSION

FreeBSD package manager
(r$pkgtk::RELEASE)

https://gitlab.com/jrmsdev/pkgtk

Released under BSD license (see LICENSE file)
Copyright (c) 2018 Jeremías Casteglione <jrmsdev@gmail.com>
"
}

#
# main menu
#
proc ::pkgtk::main_menu {} {
    menu .menu
    . configure -menu .menu

    menu .menu.packages -tearoff 0
    .menu add cascade -label "Packages" -underline 0 -menu .menu.packages
    .menu.packages add command -label "Installed" -underline 0 \
                        -command {utils dispatch_view pkgview::view_pkglocal}
    .menu.packages add command -label "Upgrade" -underline 0 \
                               -command {pkgcmd::view_upgrade "all"}
    .menu.packages add separator
    .menu.packages add command -label "Available" -underline 0 \
                        -command {utils dispatch_view pkgview::view_pkgremote}
    .menu.packages add command -label "Search" -underline 0 \
                        -command {utils dispatch_view pkgview::view_pkgsearch}
    .menu.packages add separator
    .menu.packages add command -label "Autoremove" -underline 4 \
                               -command {pkgcmd::view_autoremove}
    .menu.packages add command -label "Clean cache" -underline 0 \
                               -command {pkgcmd::view_clean_cache}
    .menu.packages add separator
    .menu.packages add command -label "Quit" -underline 0 \
                               -command {pkgtk::quit 0}

    .menu add command -label "About" -underline 0 -command {pkgtk::view_about}
}

#
# exit main loop
#
proc ::pkgtk::quit {rc} {
    destroy .
    exit $rc
}

#
# main
#
proc ::pkgtk::main {} {
    wm title . "FreeBSD package manager"
    wm minsize . 800 600
    grid rowconfigure . 0 -weight 1
    grid columnconfigure . 0 -weight 1
    . configure -padx 1 -pady 1
    pkgtk::main_menu
    utils dispatch_view pkgview::view_pkglocal
}
