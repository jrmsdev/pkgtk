package provide pkgrepo 0.0

namespace eval ::pkgrepo {
}

#
# return a list of available configuration files
#
proc ::pkgrepo::lsconf {} {
    set conf_files {}
    lappend conf_files [glob "/etc/pkg/*.conf"]
    lappend conf_files [glob "/usr/local/etc/pkg/repos/*.conf"]
    return $conf_files
}

#
# read configuration file
#   returns a dict with repo settings
#
proc ::pkgrepo::readconf {reposVar fn} {
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
                #~ puts "'$k' -> '$v' ($vtype)"
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
        pkgrepo::readconf repos $fn
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

set repos [pkgrepo::get_config]
foreach repo_name [dict keys $repos] {
    set rdata [dict get $repos $repo_name]
    puts [pkgrepo::dump_settings $repo_name $rdata]
}
