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
# return the underline index for a menu entry and the name properly formatted
#
proc ::pkgtk::menu_underline_name {orig} {
    set u [string first "_" $orig]
    set n [string replace $orig $u $u ""]
    return [list $u $n]
}

#
# create a cascade menu
#
proc ::pkgtk::menu_cascade {parent name desc items} {
    set w $parent.$name
    menu $w -tearoff 0
    pkgtk::menu_additems $w $items
    set p [pkgtk::menu_underline_name $desc]
    $parent add cascade -label [lindex $p 1] -underline [lindex $p 0] -menu $w
}

#
# add menu items
#
proc ::pkgtk::menu_additems {w items} {
    foreach {child} $items {
        set name [mc [lindex $child 1]]
        set type [lindex $child 2]
        set params $type
        switch -- $type {
            "separator" {
                $w add separator
                continue
            }
            "command" {
                set p [pkgtk::menu_underline_name $name]
                lappend params -label [lindex $p 1] -underline [lindex $p 0]
                lappend params -command [lindex $child 3]
            }
        }
        eval $w add $params
    }
}

#
# main menu
#
proc ::pkgtk::main_menu {} {
    menu .menu
    . configure -menu .menu

    pkgtk::menu_cascade .menu "packages" [mc "_Packages"] {
        {mc "_Installed" command {utils dispatch_view pkglocal::view}}
        {mc "_Upgrade" command {pkgcmd::view_upgrade "all"}}
        {s0 "" separator {}}
        {mc "_Available" command {utils dispatch_view pkgremote::view}}
        {mc "_Search" command {utils dispatch_view pkgsearch::view}}
        {s1 "" separator {}}
        {mc "Auto_remove" command {pkgcmd::view_autoremove}}
        {mc "_Clean cache" command {pkgcmd::view_clean_cache}}
        {s2 "" separator {}}
        {mc "_Quit" command {pkgtk::quit 0}}
    }

    pkgtk::menu_cascade .menu "repos" [mc "_Repositories"] {
        {mc "_Configuration" command {utils dispatch_view pkgrepo::view}}
        {mc "_Update" command {pkgcmd::view_update}}
    }

    pkgtk::menu_additems .menu {
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
