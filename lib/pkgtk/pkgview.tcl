# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgview 0.0
package require utils
package require pkgcmd

namespace eval ::pkgview {
    # global vars
    variable pkgbuttons_curstate {disabled}
    variable pkg_selected ""
    variable pkgsearch_run 0
}

#
# installed pkg action buttons
#
proc ::pkgview::pkglocal_buttons {w} {
    ttk::button $w.remove -text "Remove" -state "disabled" \
                          -command {pkgcmd::view_remove}
    grid $w.remove -row 0 -column 0 -sticky w
    ttk::button $w.upgrade -text "Upgrade" -state "disabled" \
                          -command {pkgcmd::view_upgrade}
    grid $w.upgrade -row 0 -column 1 -sticky w
}

#
# available pkg action buttons
#
proc ::pkgview::pkgremote_buttons {w} {
    ttk::button $w.install -text {Install} -state {disabled} \
                           -command {pkgcmd::view_install}
    grid $w.install -row 0 -column 0 -sticky w
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
# view search packages
#
proc ::pkgview::view_pkgsearch {w} {
    set pkgview::pkgsearch_run 0

    ttk::frame $w
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 0
    grid rowconfigure $w 1 -weight 1
    grid $w -sticky nwse

    set search $w.search
    ttk::frame $search
    grid rowconfigure $search 0 -weight 1
    grid columnconfigure $search 0 -weight 0
    grid columnconfigure $search 1 -weight 1
    grid $search -sticky nwse

    ttk::label $search.lbl -takefocus 0 -text "Search:"
    grid $search.lbl -row 0 -column 0 -sticky w

    set query $search.query
    ttk::entry $query
    grid $query -row 0 -column 1 -sticky we

    set paned $w.paned
    ttk::panedwindow $w.paned -orient "horizontal" -takefocus 0
    grid $paned -sticky nwse

    set pkglist $paned.pkglist
    listbox $pkglist
    grid $pkglist -sticky nwse

    $paned add $pkglist -weight 2

    ttk::frame $paned.right
    grid $paned.right -sticky nwse

    set pkgbuttons $paned.right.pkgbuttons
    ttk::frame $pkgbuttons -takefocus 0
    grid $pkgbuttons -row 0 -column 0 -sticky n

    set pkginfo $paned.right.pkginfo
    ttk::label $pkginfo -takefocus 0
    grid $pkginfo -row 1 -column 0 -sticky n
    $pkginfo configure -anchor "center" -justify "left"

    $paned add $paned.right -weight 8

    bind $query <Return> {set pkgview::pkgsearch_run 1}
    bind $pkglist <<ListboxSelect>> "pkgview::pkgsearch_show $pkglist $pkginfo $pkgbuttons"

    focus $query
    pkgview::pkgremote_buttons $pkgbuttons
    pkgview::pkg_search $pkglist $pkginfo $pkgbuttons $query
}

#
# show package info from search
#
proc ::pkgview::pkgsearch_show {plist pinfo pbtn} {
    set pkgidx [$plist curselection]
    if {$pkgidx >= 0} {
        set pkg [$plist get $pkgidx]
        pkgview::pkg_show $pinfo $pbtn "remote" $pkg
    }
}

#
# pkg search
#
proc ::pkgview::pkg_search {pkglist pinfo pbtn query} {
    vwait pkgview::pkgsearch_run
    if {$pkgview::pkgsearch_run} {
        utils tkbusy_hold
        $pkglist delete 0 "end"
        set q [$query get]
        if {$q != ""} {
            try {
                foreach line [split [exec pkg search -q $q] "\n"] {
                    $pkglist insert "end" "$line"
                }
                focus $pkglist
            } trap CHILDSTATUS {results options} {
                set rc [lindex [dict get $options -errorcode] 2]
                pkgview::pkgbuttons_disable $pbtn
                $pinfo configure -text ""
                if {$rc == 70} {
                    $query selection range 0 "end"
                    focus $query
                } else {
                    # rc 70 means no results matched
                    # so anything else is an error
                    utils show_error $results
                }
            }
        }
        utils tkbusy_forget
        set pkgview::pkgsearch_run 0
        pkgview::pkg_search $pkglist $pinfo $pbtn $query
    }
}

#
# packages tree view
#
proc ::pkgview::pkgtree_view {w pkgtype pkglist} {
    set paned $w
    ttk::panedwindow $paned -orient "horizontal" -takefocus 0
    grid $paned -sticky nwse

    ttk::frame $w.left -takefocus 0
    grid rowconfigure $w.left 0 -weight 1
    grid rowconfigure $w.left 1 -weight 9
    grid columnconfigure $w.left 0 -weight 1
    grid $w.left -sticky nwse

    set stats $w.left.stats
    ttk::label $stats -takefocus 0
    grid $stats -row 0 -column 0 -sticky w

    set pkgtree $w.left.pkgtree
    ttk::treeview $pkgtree -show tree -selectmode browse -takefocus 1
    grid $pkgtree -row 1 -column 0 -sticky nwse

    $paned add $w.left -weight 1

    ttk::frame $w.right -takefocus 0
    grid rowconfigure $w.right 0 -weight 1
    grid rowconfigure $w.right 1 -weight 9
    grid columnconfigure $w.right 0 -weight 1
    grid $w.right -sticky nwse

    set pkgbuttons $w.right.pkgbuttons
    ttk::frame $pkgbuttons -takefocus 0
    grid $pkgbuttons -row 0 -column 0 -sticky n

    set pkginfo $w.right.pkginfo
    ttk::label $pkginfo -takefocus 0
    grid $pkginfo -row 1 -column 0 -sticky n
    $pkginfo configure -anchor "center" -justify "left"

    $paned add $w.right -weight 9

    utils tkbusy_hold
    if {[string equal "Available" $pkgtype]} {
        pkgview::pkgremote_buttons $pkgbuttons
    } else {
        pkgview::pkglocal_buttons $pkgbuttons
    }

    set llen [llength $pkglist]
    $stats configure -text "$pkgtype packages: $llen"

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
        if {[string equal "Available" $pkgtype]} {
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
        $pkginfo configure -text "Category : $item\nPackages : $slen"
        pkgview::pkgbuttons_disable $pkgbuttons
    }
}

#
# show pkg info
#
proc ::pkgview::pkg_show {pkginfo pkgbuttons pkgtype pkg} {
    set query_format {%n %v (%sh)\n\n%e}
    if {$pkgtype == "remote"} {
        $pkginfo configure -text [exec pkg rquery $query_format $pkg]
    } else {
        $pkginfo configure -text [exec pkg query $query_format $pkg]
    }
    set pkgview::pkg_selected $pkg
    pkgview::pkgbuttons_enable $pkgbuttons
}

#
# view local (installed) packages
#
proc ::pkgview::view_pkglocal {w} {
    pkgview::pkgtree_view $w "Installed" [pkgview::pkglist_local]
}

#
# view remote (available) packages
#
proc ::pkgview::view_pkgremote {w} {
    pkgview::pkgtree_view $w "Available" [pkgview::pkglist_remote]
}

#
# pkg list local (installed) packages
#
proc ::pkgview::pkglist_local {} {
    try {
        return [split [exec pkg query -e {%a == 0} {%o|%n-%v} | sort -u]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}

#
# pkg list remote (available) packages
#
proc ::pkgview::pkglist_remote {} {
    try {
        return [split [exec pkg rquery -a {%o|%n-%v} | sort]]
    } trap CHILDSTATUS {results options} {
        utils show_error $results
    }
}
