# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide usercfg::view 0.0

namespace eval ::usercfg::view {
    variable cfg
}

#
# main view
#
proc ::usercfg::view::main {top section opt} {
    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w -row 0 -column 0 -sticky nwse

    set cfg $w.cfg
    set usercfg::view::cfg $cfg

    ttk::notebook $cfg
    grid $cfg -row 0 -column 0 -sticky nwse

    if {$section == "ALL"} {
        foreach {s} [usercfg::config_sections] {
            usercfg::show_section $cfg $s
        }
    } else {
        foreach {s} [usercfg::config_sections] {
            set sn [lindex $s 0]
            if {$sn == $section} {
                usercfg::show_section $cfg $s "noreload" $opt
                break
            }
        }
    }
}

#
# show config section
#
proc ::usercfg::show_section {cfg section {reload "none"} {showopt "none"}} {
    #~ puts "show_section: $section $reload"
    set doreload 0
    if {$reload == "reload"} {
        set doreload 1
    }

    set s_name [lindex $section 0]
    set s_show_name [lindex $section 1]
    #~ set s_show_desc [lindex $section 2]

    set s $cfg.$s_name
    if {! $doreload} {
        ttk::frame $s
        grid $s -sticky nwse
        grid columnconfigure $s 0 -weight 1
    }

    set showopt_group "ALL"
    if {$showopt != "none"} {
        set showopt_group [lindex [split $showopt "."] 0]
    }

    set g_idx 0
    foreach {group} [usercfg::config_groups $s_name] {
        set g_name [lindex $group 0]
        if {$showopt_group != "ALL" && $showopt_group != $g_name} {
            continue
        }
        set g_show_name [lindex $group 1]
        #~ set g_show_desc [lindex $group 2]
        set g $s.$g_name
        if {! $doreload} {
            grid rowconfigure $s $g_idx -weight 1

            ttk::labelframe $g -text [mc $g_show_name] -padding 0
            grid $g -row $g_idx -column 0 -sticky nwse
            grid columnconfigure $g 0 -weight 0
            grid columnconfigure $g 1 -weight 1

            ttk::frame $g.labels -padding 0
            grid columnconfigure $g.labels 0 -weight 1
            grid $g.labels -row 0 -column 0 -sticky nwse

            ttk::frame $g.values -padding 0
            grid columnconfigure $g.values 0 -weight 1
            grid $g.values -row 0 -column 1 -sticky nwse
        }
        usercfg::show_group $g $s_name $group $doreload $showopt
        if {$showopt_group != "ALL"} {
            break
        }
        incr g_idx
    }

    if {! $doreload} {
        $cfg add $s -text [mc $s_show_name] -sticky nwse
    }
}

#
# show config section group
#
proc ::usercfg::show_group {g s_name group doreload showopt} {
    set g_name [lindex $group 0]
    #~ puts "show_group: $s_name $g_name $doreload '$showopt'"
    set o_idx 0
    foreach {opt} [usercfg::config_options $s_name $g_name] {
        set o_name [lindex $opt 0]
        set olbl $g.labels.$o_name
        set oval $g.values.$o_name
        if {! $doreload} {
            grid rowconfigure $g.labels $o_idx -weight 1
            ttk::frame $olbl -padding 0
            grid $olbl -row $o_idx -column 0 -sticky nwse

            grid rowconfigure $g.values $o_idx -weight 1
            ttk::frame $oval -padding 0
            grid $oval -row $o_idx -column 0 -sticky nwse
        }
        if {$showopt == "none"} {
            usercfg::show_option $olbl.data $oval.data $s_name $g_name \
                                 $opt $doreload $showopt
        } elseif {$showopt == [format "%s.%s" $g_name $o_name]} {
            usercfg::show_option $olbl.data $oval.data $s_name $g_name \
                                 $opt $doreload $showopt
            break
        }
        incr o_idx
    }
}

#
# show config section group option
#
proc ::usercfg::show_option {olbl oval s_name g_name opt_data doreload showopt} {
    set o_name [lindex $opt_data 0]
    #~ puts "show_option: $s_name $g_name $o_name $doreload"
    set o_type [lindex $opt_data 1]
    #~ set o_defval [lindex $opt 2]
    set o_label [lindex $opt_data 3]
    set o_args [lindex $opt_data 4]

    set section $s_name
    set opt $g_name.$o_name

    if {$doreload} {
        destroy $oval
    } else {
        ttk::label $olbl -text $o_label -padding 0
        grid $olbl -row 0 -column 0 -sticky nwse
    }

    if {$o_type == "bool"} {
        set val [usercfg get_bool $section $opt]
        usercfg::show_bool $oval $section $showopt $opt $val

    } elseif {$o_type == "color"} {
        set val [usercfg get $section $opt]
        usercfg::show_color $oval $section $showopt $opt $val

    } elseif {$o_type == "str"} {
        set val [usercfg get $section $opt]
        usercfg::show_str $oval $section $showopt $opt $val

    } elseif {$o_type == "cbox"} {
        set val [usercfg get $section $opt]
        usercfg::show_cbox $oval $section $showopt $opt $val $o_args

    } else {
        set val [usercfg get $section $opt]
        ttk::label $oval -text $val -foreground red

    }
    grid $oval -row 0 -column 0 -sticky nwse
}

#
# show bool option
#
proc ::usercfg::show_bool {w section showopt opt curval} {
    ttk::combobox $w -values [list yes no] -state "readonly"
    $w set no
    if {$curval} {
        $w set yes
    }
    bind $w <<ComboboxSelected>> [list usercfg::save_bool $w $section $showopt $opt $curval]
}

#
# save bool option
#
proc ::usercfg::save_bool {w section showopt opt curval} {
    $w selection clear
    set newval [expr [$w get] ? 1 : 0]
    if {$newval != $curval} {
        usercfg::save $section $showopt $opt [expr $newval ? "yes" : "no"]
    }
}

#
# show color option
#
proc ::usercfg::show_color {w section showopt opt curval} {
    button $w -background $curval -foreground $curval \
        -activebackground $curval -activeforeground $curval \
        -command [list usercfg::save_color $section $showopt $opt $curval]
}

#
# save color option
#
proc ::usercfg::save_color {section showopt opt curval} {
    set newval [tk_chooseColor -initialcolor $curval -title "pkgtk color"]
    if {$newval != "" && $newval != $curval} {
        usercfg::save $section $showopt $opt $newval
    }
}

#
# show str option
#
proc ::usercfg::show_str {w section showopt opt curval} {
    ttk::entry $w
    $w insert end $curval
    bind $w <Return> [list usercfg::save_str $w $section $showopt $opt $curval]
}

#
# save str option
#
proc ::usercfg::save_str {w section showopt opt curval} {
    set newval [string trim [$w get]]
    if {$newval != "" && $newval != $curval} {
        usercfg::save $section $showopt $opt $newval
    }
}

#
# show cbox option
#
proc ::usercfg::show_cbox {w section showopt opt curval cbvals} {
    ttk::combobox $w -values $cbvals -state "readonly"
    $w set $curval
    bind $w <<ComboboxSelected>> [list usercfg::save_cbox $w $section $showopt $opt $curval]
}

#
# save cbox option
#
proc ::usercfg::save_cbox {w section showopt opt curval} {
    $w selection clear
    set newval [$w get]
    if {$newval != $curval} {
        usercfg::save $section $showopt $opt $newval
    }
}
