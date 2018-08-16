# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide usercfg 0.0

package require utils
package require usercfg::view

namespace eval ::usercfg {
    namespace export view getall get get_bool
    namespace ensemble create

    # hold config data
    variable db
    variable filename ""

    # define configuration
    variable CONFIG {
        {name "style" mc "Style" mc "Style settings" {
            {name "console" mc "Console" mc "Format commands output" {
                {name "colored" type "bool" defval 1 mc "Colored text?"}
                {name "background" type "color" defval "black" mc ""}
                {name "foreground" type "color" defval "white" mc ""}
            }}
        }}
    }
}

#
# list sections from defined config
#
proc ::usercfg::config_sections {} {
    set l {}
    foreach {s} $usercfg::CONFIG {
        set name [lindex $s 1]
        set show_name [lindex $s 3]
        set show_desc [lindex $s 5]
        lappend l [list $name $show_name $show_desc]
    }
    return $l
}

#
# return section groups of options from defined configuration
#
proc ::usercfg::config_groups {section} {
    set rtrn {}
    foreach {s} $usercfg::CONFIG {
        set sn [lindex $s 1]
        if {$sn == $section} {
            foreach {g} [lindex $s 6] {
                set g_name [lindex $g 1]
                set g_show_name [lindex $g 3]
                set g_show_desc [lindex $g 5]
                lappend rtrn [list $g_name $g_show_name $g_show_desc]
            }
        }
    }
    return $rtrn
}

#
# return options of a section group from defined configuration
#
proc ::usercfg::config_options {section group} {
    set rtrn {}
    foreach {s} $usercfg::CONFIG {
        set sn [lindex $s 1]
        if {$sn == $section} {
            foreach {g} [lindex $s 6] {
                set g_name [lindex $g 1]
                if {$g_name == $group} {
                    foreach {opt} [lindex $g 6] {
                        set o_name [lindex $opt 1]
                        set o_type [lindex $opt 3]
                        set o_defval [lindex $opt 5]
                        set o_show_desc [lindex $opt 7]
                        lappend rtrn [list $o_name $o_type $o_defval $o_show_desc]
                    }
                }
            }
        }
    }
    return $rtrn
}

#
# set default settings
#
proc ::usercfg::set_defaults {} {
    foreach {s} [usercfg::config_sections] {
        set section [lindex $s 0]
        foreach {g} [usercfg::config_groups $section] {
            set group [lindex $g 0]
            foreach {o} [usercfg::config_options $section $group] {
                set opt [lindex $o 0]
                set opt_defval [lindex $o 2]
                set db_key [format "%s.%s.%s" $section $group $opt]
                dict set usercfg::db $db_key $opt_defval
            }
        }
    }
}

#
# return a dict with options->value pairs
# for options that match optprefix from a config section
#
proc ::usercfg::getall {section {optprefix ""}} {
    set rtrn {}
    set p $section
    if {$optprefix != ""} {
        set p [format "%s.%s" $p $optprefix]
        set plen [string length $p]
        foreach {opt} [lsort [dict keys $usercfg::db]] {
            set optlen [string length $opt]
            if {$optlen >= $plen} {
                set opt_p [string range $opt 0 [expr $plen - 1]]
                if {$opt_p == $p} {
                    dict set rtrn $opt [dict get $usercfg::db $opt]
                }
            }
        }
    }
    return $rtrn
}

#
# return the value from a config section option
#
proc ::usercfg::get {section optname {defval ""}} {
    set opt [format "%s.%s" $section $optname]
    if {[dict exists $usercfg::db $opt]} {
        return [dict get $usercfg::db $opt]
    }
    return $defval
}

#
# return a config section option as a boolean value
#
proc ::usercfg::get_bool {section optname {defval 0}} {
    set val [usercfg::get $section $optname "__NONE__"]
    if {$val != "__NONE__" && [string is boolean $val]} {
        return [expr $val ? 1 : 0]
    }
    return $defval
}

#
# user config main view (toplevel window)
#
proc ::usercfg::view {} {
    set usercfg::filename [file join $::env(HOME) .config pkgtk.cfg]

    if {[usercfg::load] != 0} {
        return
    }

    set top .usercfg

    toplevel $top
    #~ wm minsize $top 400 300
    wm transient $top .
    wm title $top [mc "pkgtk preferences"]
    grid rowconfigure $top 0 -weight 1
    grid columnconfigure $top 0 -weight 1

    usercfg::view::main $top

    tkwait window $top
}

#
# load configuration, read it from user file if exists
#   save it in usercfg::db as a dict with key val pair (not a nested dict)
#   return 1 if any error, otherwise 0
#
proc ::usercfg::load {} {
    usercfg::set_defaults
    if {[file exists $usercfg::filename] && [file isfile $usercfg::filename]} {
        if {[catch {usercfg::readfile $usercfg::filename} err]} {
            utils show_error $err
            return 1
        }
    }
    return 0
}

#
# read a configuration file and save settings in global db
#
proc ::usercfg::readfile {fn} {
    set validkeys [lsort [dict keys $usercfg::db]]
    set fh [open $fn "r"]
    while {[gets $fh line] >= 0} {
        set line [string trim $line]
        set opt [string trim [lindex [split $line ":"] 0]]
        if {$opt == ""} {
            continue
        }
        if {[string first "#" $opt 0] == 0} {
            continue
        }
        if {$opt in $validkeys} {
            set val [string tolower [string trim [lindex [split $line ":"] 1]]]
            dict set usercfg::db $opt "$val"
        } else {
            puts stderr "pkgtk ignore invalid config option: $opt"
        }
    }
    close $fh
}

#
# save config option
#
proc ::usercfg::save {section opt val} {
    set line [format "%s.%s: %s" $section $opt $val]
    if {[catch {usercfg::writefile $usercfg::filename $section.$opt $val} err]} {
        utils show_error $err
    }
}

#
# write configuration file
#
proc ::usercfg::writefile {fn opt val} {
    #~ puts "usercfg writefile: $fn '$line'"
    file mkdir [file dirname $fn]
    set opt_done 0
    set tmpfn "/NONE"
    set wfh [file tempfile tmpfn ".pkgtk.user.cfg"]
    puts $wfh "# pkgtk config file - DO NOT EDIT HERE"
    set fh [open $fn r]
    while {[gets $fh src] >= 0} {
        set src [string trim $src]
        if {$src == ""} {
            continue
        }
        if {[string first "#" $src 0] == 0} {
            continue
        }
        set dst $src
        set src_opt [string trim [lindex [split $src ":"] 0]]
        if {$src_opt == $opt} {
            set dst [format "%s: %s" $opt $val]
            set opt_done 1
        }
        puts $wfh $dst
    }
    close $fh
    if {!$opt_done} {
        puts $wfh [format "%s: %s" $opt $val]
    }
    close $wfh
    file rename -force $tmpfn $fn
}
