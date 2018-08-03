# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgrepo 0.0

namespace eval ::pkgrepo {
    namespace export view
    namespace ensemble create
}

#
# return a list of available configuration files
#
proc ::pkgrepo::lsconf {} {
    return [glob "/etc/pkg/*.conf" "/usr/local/etc/pkg/repos/*.conf"]
}

#
# read configuration file
#   returns a dict with repo settings
#
proc ::pkgrepo::readfile {reposVar fn} {
    upvar 1 $reposVar repos

    set fh [open $fn "r"]
    set data [read $fh]
    close $fh

    set inrepo 0
    foreach line [split $data "\n"] {
        set line [string trim $line]
        if {[string first "#" $line] == 0} {
            continue
        }
        if {[string last ": \{" $line] > 0} {
            set repo_name [lindex [split $line ":"] 0]
            set inrepo 1
            continue
        }
        if {$inrepo} {
            if {$line == "\}"} {
                set inrepo 0
                continue
            }
            if {[string first ":" $line] > 0} {
                set k [string trim [lindex [split $line ":"] 0]]
                set v [string trim [join [lrange [split $line ":"] 1 end] ":"]]
                set vlen [string length $v]
                if {[expr [string last "," $v] == {$vlen - 1}]} {
                    set lastidx [expr $vlen - 2]
                    set v [string range $v 0 end-1]
                }
                set vtype "str"
                if {[string is boolean $v]} {
                    set vtype "bool"
                } else {
                    set v [string replace $v 0 0 ""]
                    set v [string replace $v end end ""]
                }
                dict set repos $repo_name $k [list $vtype $v]
            }
        }
    }
}

#
# get repos config
#   return a dict of dicts with repo settings
#
proc ::pkgrepo::get_config {} {
    set repos {}
    foreach fn [pkgrepo::lsconf] {
        pkgrepo::readfile repos $fn
    }
    return $repos
}

#
# dump repo settings
#   return a valid (yaml?) string to save in a config file
#
proc ::pkgrepo::dump_settings {repo_name rdata} {
    set s "$repo_name: \{\n"
    foreach k [dict keys $rdata] {
        set v [dict get $rdata $k]
        if {$k == "enabled"} {
            # enabled setting will be managed later
            continue
        }
        set vtype [lindex $v 0]
        set v [lindex $v 1]
        if {$vtype == "str"} {
            set s "$s  $k: \"$v\",\n"
        } else {
            set s "$s  $k: $v,\n"
        }
    }
    # use enabled setting to finish the dict
    # also to be sure it is always present
    if {[dict exists $rdata "enabled"]} {
        set v [lindex [dict get $rdata "enabled"] 1]
        set s "$s  enabled: $v\n"
    } else {
        set s "$s  enabled: no\n"
    }
    set s "$s\}\n"
    return $s
}

#
# view repos settings
#
proc ::pkgrepo::view {w} {
    ttk::frame $w
    grid columnconfigure $w 0 -weight 1
    grid rowconfigure $w 0 -weight 0
    grid rowconfigure $w 1 -weight 1
    grid $w -sticky nwse

    ttk::label $w.dbstats -takefocus 0 -text [exec pkg stats -r]
    grid $w.dbstats -row 0 -column 0 -sticky nw

    set repos $w.repos
    ttk::notebook $repos
    grid $repos -row 1 -column 0 -sticky nwse

    set repos_config [pkgrepo::get_config]
    set idx 0
    foreach repo_name [lsort [dict keys $repos_config]] {
        set repo_data [dict get $repos_config $repo_name]
        set rid "r$idx"
        $repos add [pkgrepo::show $repos.$rid $repo_name $repo_data] \
                   -text $repo_name -sticky nwse
        incr idx
    }

    $repos select $repos.r0
    ttk::notebook::enableTraversal $repos
}

#
# show repo settings
#   return a ttk frame showing the settings
#
proc ::pkgrepo::show {w name data} {
    ttk::frame $w -padding {0 5}
    grid columnconfigure $w 0 -weight 0
    grid columnconfigure $w 1 -weight 0
    grid columnconfigure $w 2 -weight 1
    grid $w -sticky nwse

    set optidx 0
    foreach opt [lsort [dict keys $data]] {
        set valtype [lindex [dict get $data $opt] 0]
        set val [lindex [dict get $data $opt] 1]
        set ow $w.opt$optidx
        ttk::label $ow -text $opt
        grid $ow -row $optidx -column 0 -sticky nw
        set sep $w.sep$optidx
        ttk::label $sep -text ":"
        grid $sep -row $optidx -column 1 -sticky nw
        set vw $w.val$optidx
        pkgrepo::setting_value $vw $valtype $val
        grid $vw -row $optidx -column 2 -sticky nwse
        incr optidx
    }

    return $w
}

#
# create a widget representing a config setting value
#
proc ::pkgrepo::setting_value {w vtype val} {
    if {$vtype == "bool"} {
        pkgrepo::valtype_bool $w $val
    } else {
        pkgrepo::valtype_str $w $val
    }
}

#
# create a widget for a setting string value
#
proc ::pkgrepo::valtype_str {w val} {
    ttk::entry $w -takefocus 0
    $w insert end $val
    $w configure -state "read"
}

#
# create a widget for a setting bool value
#
proc ::pkgrepo::valtype_bool {w val} {
    #~ ttk::combobox $w -values "yes no" -state "read"
    #~ $w set $val
    ttk::entry $w -takefocus 0
    $w insert end $val
    $w configure -state "read"
}
