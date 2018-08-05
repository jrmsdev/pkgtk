# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide pkgrepo 0.0
package require utils

namespace eval ::pkgrepo {
    namespace export view
    namespace ensemble create

    variable config
    variable dirty
    variable repos_w
    variable w_ids
    variable buttons
    variable strcheck_cur "__NOSET__"
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
# write repo config file
#
proc ::pkgrepo::writefile {repo cfg} {
    set cfgdir "/usr/local/etc/pkg/repos"
    if {! [file exists $cfgdir]} {
        file mkdir $cfgdir
    }
    set fn [format "%s/%s.conf" $cfgdir $repo]
    if {[catch {set fh [open $fn "w"]} err]} {
        utils show_error $err
        return
    } else {
        puts $fh [mc "# created by pkgtk"]
        puts $fh [pkgrepo::dump_settings $repo $cfg]
    }
    if {[catch {close $fh} err]} {
        utils show_error $err
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
    grid rowconfigure $w 2 -weight 0
    grid $w -sticky nwse

    ttk::label $w.dbstats -takefocus 0 -text [exec pkg stats -r]
    grid $w.dbstats -row 0 -column 0 -sticky nw
    $w.dbstats configure -padding {0 0 0 5}

    set repos $w.repos
    ttk::notebook $repos
    grid $repos -row 1 -column 0 -sticky nwse
    set pkgrepo::repos_w $repos

    bind $repos <<NotebookTabChanged>> "pkgrepo::tab_changed $repos"

    set buttons $w.btn
    set pkgrepo::buttons $buttons

    ttk::frame $buttons
    grid $buttons -row 2 -column 0 -sticky nwse

    ttk::button $buttons.save -text [mc "Save"] -state "disabled" \
                              -command {pkgrepo::changes_save}
    grid $buttons.save -row 0 -column 0

    ttk::button $buttons.discard -text [mc "Discard"] -state "disabled" \
                                 -command {pkgrepo::changes_discard}
    grid $buttons.discard -row 0 -column 1

    set pkgrepo::config [pkgrepo::get_config]
    set idx 0
    foreach repo_name [lsort [dict keys $pkgrepo::config]] {
        set repo_data [dict get $pkgrepo::config $repo_name]
        set rid "r$idx"
        $repos add [pkgrepo::show $repos.$rid $repo_name $repo_data] \
                   -text $repo_name -sticky nwse
        dict set pkgrepo::w_ids $repo_name $repos.$rid
        incr idx
    }

    $repos select $repos.r0
    ttk::notebook::enableTraversal $repos
}

#
# manage a tab changed event
#
proc ::pkgrepo::tab_changed {repos} {
    set t [$repos tab current -text]
    set dirty [expr [string last "*" $t] > 1]
    if {$dirty} {
        pkgrepo::buttons_enable
    } else {
        pkgrepo::buttons_disable
    }
}

#
# show repo settings
#   return a ttk frame showing the settings
#
proc ::pkgrepo::show {w name data} {
    set reload 0
    if {[winfo exists $w]} {
        set reload 1
    }
    if {$reload} {
        foreach {child} [winfo children $w] {
            destroy $child
        }
    } else {
        ttk::frame $w -padding {0 5}
        grid columnconfigure $w 0 -weight 0
        grid columnconfigure $w 1 -weight 0
        grid columnconfigure $w 2 -weight 1
        grid $w -sticky nwse
    }

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
        pkgrepo::setting_value $vw $name $opt $valtype $val
        grid $vw -row $optidx -column 2 -sticky nwse
        incr optidx
    }

    return $w
}

#
# create a widget representing a config setting value
#
proc ::pkgrepo::setting_value {w repo opt vtype val} {
    if {$vtype == "bool"} {
        pkgrepo::valtype_bool $w $repo $opt $val
    } else {
        pkgrepo::valtype_str $w $repo $opt $val
    }
}

#
# create a widget for a setting string value
#
proc ::pkgrepo::valtype_str {w repo opt val} {
    ttk::entry $w -takefocus 0
    $w insert end $val
    $w configure -validate "all" \
                 -validatecommand "pkgrepo::str_check $w $repo $opt %V %s"
}

#
# manage an str setting
#
proc ::pkgrepo::str_check {w repo opt cond val} {
    if {$cond == "focusin"} {
        set pkgrepo::strcheck_cur $val
    } elseif {$cond == "focusout" && $val != $pkgrepo::strcheck_cur} {
        pkgrepo::config_set $repo $opt $val
        set pkgrepo::strcheck_cur "__UNSET__"
    }
    return 1
}

#
# create a widget for a setting bool value
#
proc ::pkgrepo::valtype_bool {w repo opt val} {
    ttk::combobox $w -values "yes no" -state "readonly"
    $w set $val
    bind $w <<ComboboxSelected>> "pkgrepo::bool_selected $w $repo $opt"
}

#
# manage a bool setting
#
proc ::pkgrepo::bool_selected {w repo opt} {
    $w selection clear
    set newval [$w get]
    pkgrepo::config_set $repo $opt $newval
}

#
# get a repo config original (read from file) value
#
proc ::pkgrepo::config_origval {repo opt} {
    return [lindex [dict get [dict get $pkgrepo::config $repo] $opt] 1]
}

#
# set a new config value
#
proc ::pkgrepo::config_set {repo opt val} {
    set origval [pkgrepo::config_origval $repo $opt]
    if {$val == $origval} {
        pkgrepo::dirty_unset $repo $opt
    } else {
        pkgrepo::dirty_set $repo $opt $val
    }
}

#
# set a repo config as dirty (changed/updated)
#
proc ::pkgrepo::dirty_set {repo opt val} {
    dict set pkgrepo::dirty $repo $opt $val
    set w [dict get $pkgrepo::w_ids $repo]
    $pkgrepo::repos_w tab $w -text "$repo *"
    pkgrepo::buttons_enable
}

#
# unset a repo config as dirty (restored to orig value)
#
proc ::pkgrepo::dirty_unset {repo opt} {
    if {[info exists pkgrepo::dirty] && [dict exists $pkgrepo::dirty $repo]} {
        dict unset pkgrepo::dirty $repo $opt
        set repolen [dict size [dict get $pkgrepo::dirty $repo]]
        if {[dict size [dict get $pkgrepo::dirty $repo]] == 0} {
            set w [dict get $pkgrepo::w_ids $repo]
            $pkgrepo::repos_w tab $w -text "$repo"
            pkgrepo::buttons_disable
        }
    }
}

#
# enable edit buttons
#
proc ::pkgrepo::buttons_enable {} {
    foreach {btn} [winfo children $pkgrepo::buttons] {
        $btn configure -state "enabled"
    }
}

#
# disable edit buttons
#
proc ::pkgrepo::buttons_disable {} {
    foreach {btn} [winfo children $pkgrepo::buttons] {
        $btn configure -state "disabled"
    }
}

#
# get the repo name from current tab
#
proc ::pkgrepo::curtab_reponame {} {
    set repo [$pkgrepo::repos_w tab current -text]
    set staridx [string first "*" $repo]
    if {$staridx} {
        return [string trim [string replace $repo $staridx $staridx ""]]
    }
    return $repo
}

#
# discard changes
#
proc ::pkgrepo::changes_discard {} {
    set repo [pkgrepo::curtab_reponame]
    foreach {opt} [dict keys [dict get $pkgrepo::dirty $repo]] {
        pkgrepo::dirty_unset $repo $opt
    }
    set w [dict get $pkgrepo::w_ids $repo]
    set data [dict get $pkgrepo::config $repo]
    pkgrepo::show $w $repo $data
}

#
# save changes
#
proc ::pkgrepo::changes_save {} {
    set repo [pkgrepo::curtab_reponame]
    set newcfg [dict get $pkgrepo::dirty $repo]
    set newdata [pkgrepo::config_update $repo $newcfg]
    pkgrepo::writefile $repo $newdata
    foreach {opt} [dict keys $newcfg] {
        pkgrepo::dirty_unset $repo $opt
    }
    set w [dict get $pkgrepo::w_ids $repo]
    pkgrepo::show $w $repo $newdata
}

#
# update repo config
#
proc ::pkgrepo::config_update {repo newcfg} {
    set cfg [dict get $pkgrepo::config $repo]
    foreach {opt val} $newcfg {
        set curval [dict get $cfg $opt]
        set type [lindex $curval 0]
        dict unset pkgrepo::config $repo $opt
        dict set pkgrepo::config $repo $opt [list $type $val]
    }
    return [dict get $pkgrepo::config $repo]
}
