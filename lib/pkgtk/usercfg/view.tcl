# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide usercfg::view 0.0

namespace eval ::usercfg::view {
    variable cfg
}

#
# main view
#
proc ::usercfg::view::main {top} {
    set w $top.view
    ttk::frame $w
    grid rowconfigure $w 0 -weight 1
    grid columnconfigure $w 0 -weight 1
    grid $w -row 0 -column 0 -sticky nwse

    set cfg $w.cfg
    set usercfg::view::cfg $cfg

    ttk::notebook $cfg
    grid $cfg -row 0 -column 0 -sticky nwse

    foreach {section} [usercfg::config_sections] {
        usercfg::show_section $cfg $section
    }
}

#
# show config section
#
proc ::usercfg::show_section {cfg section {reload "none"}} {
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

    set g_idx 0
    foreach {group} [usercfg::config_groups $s_name] {
        set g_name [lindex $group 0]
        set g_show_name [lindex $group 1]
        #~ set g_show_desc [lindex $group 2]
        set g $s.$g_name
        if {! $doreload} {
            grid rowconfigure $s $g_idx -weight 1
            ttk::labelframe $g -text [mc $g_show_name]
            grid $g -row $g_idx -column 0 -sticky nwse
            grid columnconfigure $g 0 -weight 1
        }
        usercfg::show_group $g $s_name $group $doreload
        incr g_idx
    }

    if {! $doreload} {
        $cfg add $s -text [mc $s_show_name] -sticky nwse
    }
}

#
# show config section group
#
proc ::usercfg::show_group {g s_name group doreload} {
    #~ puts "show_group: $s_name '$group' $doreload"
    set g_name [lindex $group 0]
    set o_idx 0
    foreach {opt} [usercfg::config_options $s_name $g_name] {
        set o_name [lindex $opt 0]
        set o $g.$o_name
        if {! $doreload} {
            grid rowconfigure $g $o_idx -weight 1
            ttk::frame $o
            grid $o -row $o_idx -column 0 -sticky nwse
        }
        usercfg::show_option $o $s_name $g_name $opt $doreload
        incr o_idx
    }
}

#
# show config section group option
#
proc ::usercfg::show_option {o s_name g_name opt doreload} {
    #~ puts "show_option: $o $s_name $g_name '$opt' $doreload"
    set o_name [lindex $opt 0]
    set o_type [lindex $opt 1]
    #~ set o_defval [lindex $opt 2]
    set o_label [lindex $opt 3]

    set section $s_name
    set opt $g_name.$o_name

    if {$doreload} {
        destroy $o.val
    } else {
        grid rowconfigure $o 0 -weight 1
        grid columnconfigure $o 0 -weight 0
        grid columnconfigure $o 1 -weight 0

        ttk::label $o.lbl -text $o_label
        grid $o.lbl -row 0 -column 0 -sticky w
    }

    if {$o_type == "bool"} {
        set val [usercfg get_bool $section $opt]
        usercfg::show_bool $o.val $section $opt $val
    } elseif {$o_type == "color"} {
        set val [usercfg get $section $opt]
        usercfg::show_color $o.val $section $opt $val
    } else {
        set val [usercfg get $section $opt]
        ttk::label $o.val -text $val
    }
    grid $o.val -row 0 -column 1 -sticky w
}

#
# show bool option
#
proc ::usercfg::show_bool {w section opt curval} {
    ttk::combobox $w -values [list yes no] -state "readonly"
    $w set no
    if {$curval} {
        $w set yes
    }
    bind $w <<ComboboxSelected>> [list usercfg::save_bool $w $section $opt $curval]
}

#
# save bool option
#
proc ::usercfg::save_bool {w section opt curval} {
    $w selection clear
    set newval [expr [$w get] ? 1 : 0]
    if {$newval != $curval} {
        usercfg::save $section $opt [expr $newval ? "yes" : "no"]
    }
}

#
# show color option
#
proc ::usercfg::show_color {w section opt curval} {
    button $w -background $curval -foreground $curval \
        -activebackground $curval -activeforeground $curval \
        -command [list usercfg::save_color $section $opt $curval]
}

#
# save color option
#
proc ::usercfg::save_color {section opt curval} {
    set newval [tk_chooseColor -initialcolor $curval -title "pkgtk color"]
    if {$newval != "" && $newval != $curval} {
        usercfg::save $section $opt $newval
    }
}
