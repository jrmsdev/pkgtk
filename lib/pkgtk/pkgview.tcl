# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgview 0.0

package require utils
package require pkglocal
package require pkgremote
package require cmdexec

namespace eval ::pkgview {
    # global vars
    variable pkgbuttons_curstate {disabled}
    variable pkg_selected ""
    variable toplevel_child .topchild
}

#
# change state of pkg action buttons
#
proc ::pkgview::pkgbuttons_state {w state} {
    if {$pkgview::pkgbuttons_curstate == $state} {
        return
    }
    set children [winfo children $w]
    set children_len [llength $children]
    for {set i 0} {$i < $children_len} {incr i} {
        set b [lindex $children $i]
        $b configure -state $state
    }
    set pkgview::pkgbuttons_curstate $state
    update
}

#
# enable pkg action buttons
#
proc ::pkgview::pkgbuttons_enable {w} {
    pkgview::pkgbuttons_state $w {enabled}
}

#
# disable pkg action buttons
#
proc ::pkgview::pkgbuttons_disable {w} {
    pkgview::pkgbuttons_state $w {disabled}
}

#
# packages tree view
#
proc ::pkgview::pkgtree_view {w pkgtype pkglist {inc "noauto"}} {
    set paned $w
    ttk::panedwindow $paned -orient "horizontal" -takefocus 0
    grid $paned -sticky nwse

    ttk::frame $w.left -takefocus 0 -padding 1
    grid rowconfigure $w.left 0 -weight 0
    grid rowconfigure $w.left 1 -weight 1
    grid columnconfigure $w.left 0 -weight 1
    grid $w.left -sticky nwse

    set stats $w.left.stats
    ttk::label $stats -takefocus 0
    grid $stats -row 0 -column 0 -sticky nwse

    set pkgtree $w.left.pkgtree
    ttk::treeview $pkgtree -show tree -selectmode browse -takefocus 1
    grid $pkgtree -row 1 -column 0 -sticky nwse

    $paned add $w.left -weight 1

    ttk::frame $w.right -takefocus 0 -padding 1
    grid rowconfigure $w.right 0 -weight 0
    grid rowconfigure $w.right 1 -weight 1
    grid rowconfigure $w.right 2 -weight 0
    grid columnconfigure $w.right 0 -weight 1
    grid $w.right -sticky nwse

    set options $w.right.options
    ttk::frame $options
    grid $options -row 0 -column 0 -sticky nwse

    set pkginfo $w.right.pkginfo
    ttk::label $pkginfo -takefocus 0
    grid $pkginfo -row 1 -column 0 -sticky nwse
    $pkginfo configure -anchor "center" -justify "left"

    set pkgbuttons $w.right.pkgbuttons
    ttk::frame $pkgbuttons -takefocus 0
    grid $pkgbuttons -row 2 -column 0 -sticky n

    $paned add $w.right -weight 9

    utils tkbusy_hold

    # pkg buttons, stats and options
    set llen [llength $pkglist]
    if {$pkgtype == "remote"} {
        pkgremote::buttons $pkgbuttons "reload"
        $stats configure -text [format [mc "Available packages: %d"] $llen]
    } else {
        pkglocal::buttons $pkgbuttons
        $stats configure -text [format [mc "Installed packages: %d"] $llen]
        pkglocal::options $options $inc
    }

    # pkgtree
    set cur_section {}
    set focus_item {}
    for {set i 0} {$i < $llen} {incr i} {
        set line [lindex $pkglist $i]
        set origin [lindex [split $line {|}] 0]
        set pkg_section [lindex [split $origin /] 0]
        set pkg_name [lindex [split $line {|}] 1]
        if {[string equal $cur_section {}]} {
            set focus_item $pkg_section
        }
        if {[string compare $pkg_section $cur_section] != 0} {
            set sid [$pkgtree insert {} end -id $pkg_section -text $pkg_section]
            set cur_section $pkg_section
        }
        set pkgid "pkglocal:$pkg_name"
        if {[string equal "remote" $pkgtype]} {
            set pkgid "pkgremote:$pkg_name"
        }
        $pkgtree insert $cur_section end -id $pkgid -text $pkg_name
    }

    utils tkbusy_forget

    $pkgtree focus $focus_item
    focus $pkgtree
    bind $pkgtree <<TreeviewSelect>> "pkgview::pkgtree_show $pkgtree $pkginfo $pkgbuttons"
}

#
# show package tree info
#
proc ::pkgview::pkgtree_show {pkgtree pkginfo pkgbuttons} {
    set pkgview::pkg_selected "NONE"
    set item [$pkgtree selection]
    if {[string equal {pkglocal:} [string range $item 0 8]]} {
        set pkg [string replace $item 0 8 {}]
        pkgview::pkg_show $pkginfo $pkgbuttons "local" $pkg
    } elseif {[string equal {pkgremote:} [string range $item 0 9]]} {
        set pkg [string replace $item 0 9 {}]
        pkgview::pkg_show $pkginfo $pkgbuttons "remote" $pkg
    } else {
        set slen [llength [$pkgtree children $item]]
        $pkginfo configure \
                 -text [format [mc "Category : %s\nPackages : %d"] $item $slen]
        pkgview::pkgbuttons_disable $pkgbuttons
    }
}

#
# show pkg info
#
proc ::pkgview::pkg_show {pkginfo pkgbuttons pkgtype pkg} {
    if {$pkgtype == "remote"} {
        $pkginfo configure -text [cmdexec rquery $pkg]
    } else {
        $pkginfo configure -text [cmdexec query $pkg]
    }
    set pkgview::pkg_selected $pkg
    pkgview::pkgbuttons_enable $pkgbuttons
}
