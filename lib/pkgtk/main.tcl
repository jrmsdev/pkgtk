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
    $top.info configure -justify "center" -padding {10 0} \
-font "monospace 10 bold" -text "
pkgtk v$version::VERSION

FreeBSD package manager
(r$version::RELEASE)

https://gitlab.com/jrmsdev/pkgtk

Released under BSD license (see LICENSE file)
Copyright (c) 2018 Jeremías Casteglione <jrmsdev@gmail.com>
"
    tkwait window $top
}

#
# main menu
#
proc ::pkgtk::main_menu {} {
    menu .menu
    . configure -menu .menu

    menu .menu.packages -tearoff 0
    .menu add cascade -label [mc "Packages"] -underline 0 -menu .menu.packages

    .menu.packages add command -label [mc "Installed"] -underline 0 \
                               -command {utils dispatch_view pkglocal::view}
    .menu.packages add command -label [mc "Upgrade"] -underline 0 \
                               -command {pkgcmd::view_upgrade "all"}
    .menu.packages add separator
    .menu.packages add command -label [mc "Available"] -underline 0 \
                        -command {utils dispatch_view pkgremote::view}
    .menu.packages add command -label [mc "Search"] -underline 0 \
                               -command {utils dispatch_view pkgsearch::view}
    .menu.packages add separator
    .menu.packages add command -label [mc "Autoremove"] -underline 4 \
                               -command {pkgcmd::view_autoremove}
    .menu.packages add command -label [mc "Clean cache"] -underline 0 \
                               -command {pkgcmd::view_clean_cache}
    .menu.packages add separator
    .menu.packages add command -label [mc "Quit"] -underline 0 \
                               -command {pkgtk::quit 0}

    menu .menu.repos -tearoff 0
    .menu add cascade -label [mc "Repositories"] -underline 0 -menu .menu.repos
    .menu.repos add command -label [mc "Configuration"] -underline 0 \
                            -command {utils dispatch_view pkgrepo::view}
    .menu.repos add command -label [mc "Update"] -underline 0 \
                            -command {pkgcmd::view_update}

    .menu add command -label [mc "About"] -underline 0 -command {pkgtk::view_about}
}

#
# exit main loop
#
proc ::pkgtk::quit {rc} {
    if {[winfo exists $pkgview::toplevel_child]} {
        destroy $pkgview::toplevel_child
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
