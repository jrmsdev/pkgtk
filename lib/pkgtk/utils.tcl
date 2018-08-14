# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide utils 0.0

namespace eval ::utils {
    namespace export dispatch_view show_error tkbusy_hold tkbusy_forget sudo
    namespace export menu_underline_name menu_cascade menu_additems
    namespace ensemble create

    variable libexec_dir $::env(PKGTK_LIBEXEC)
}

#
# dispatch view
#
proc ::utils::dispatch_view {name} {
    set w .view
    if [winfo exists $w] {
        destroy $w
    }
    $name $w
}

#
# show error message
#
proc ::utils::show_error {msg} {
    tk_messageBox -parent . -title "pkgtk error" -message "$msg" \
                  -type "ok" -icon "error"
}

#
# tk busy hold
#
proc ::utils::tkbusy_hold {{w .}} {
    tk busy hold $w
    tk busy configure $w -cursor watch
    update
}

#
# tk busy forget
#
proc ::utils::tkbusy_forget {{w .}} {
    tk busy forget $w
    update
}

#
# return the underline index for a menu entry and the name properly formatted
#
proc ::utils::menu_underline_name {orig} {
    set u [string first "_" $orig]
    set n [string replace $orig $u $u ""]
    return [list $u $n]
}

#
# create a cascade menu
#
proc ::utils::menu_cascade {parent name desc items} {
    set w $parent.$name
    menu $w -tearoff 0
    utils::menu_additems $w $items
    set p [utils::menu_underline_name $desc]
    $parent add cascade -label [lindex $p 1] -underline [lindex $p 0] -menu $w
}

#
# add menu items
#
proc ::utils::menu_additems {w items} {
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
                set p [utils::menu_underline_name $name]
                lappend params -label [lindex $p 1] -underline [lindex $p 0]
                lappend params -command [lindex $child 3]
            }
        }
        eval $w add $params
    }
}

#
# run helper from libexec directory via sudo
#
proc ::utils::sudo {name args} {
    set cmd [list /usr/local/bin/sudo -n [file join $utils::libexec_dir $name]]
    foreach {a} $args {
        lappend cmd $a
    }
    if {[catch {exec {*}$cmd} err]} {
        utils::show_error $err
        return 1
    }
    return 0
}
