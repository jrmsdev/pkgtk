# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide usercfg::view 0.0

namespace eval ::usercfg::view {
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
    ttk::notebook $cfg
    grid $cfg -row 0 -column 0 -sticky nwse

    foreach {section} [usercfg::sections_list] {
        usercfg::show_section $cfg $section
    }
}

#
# show config section
#
proc ::usercfg::show_section {cfg section} {
    set s_name [lindex $section 0]
    set s_show_name [lindex $section 1]
    #~ set s_show_desc [lindex $section 2]

    set s $cfg.$s_name
    ttk::frame $s
    grid $s -sticky nwse

    set g_idx 0
    foreach {group} [usercfg::section_groups $s_name] {
        set g_name [lindex $group 0]
        set g_show_name [lindex $group 1]
        #~ set g_show_desc [lindex $group 2]
        set g $s.$g_name
        ttk::labelframe $g -text [mc $g_show_name]
        grid $g -row $g_idx -column 0 -sticky nwse
        usercfg::show_group $g $s_name $group
        incr g_idx
    }

    $cfg add $s -text [mc $s_show_name] -sticky nwse
}

#
# show config section group
#
proc ::usercfg::show_group {g s_name group} {
    set g_name [lindex $group 0]
    set o_idx 0
    foreach {opt} [usercfg::section_options $s_name $g_name] {
        set o_name [lindex $opt 0]
        set o $g.$o_name
        ttk::frame $o
        grid $o -row $o_idx -column 0 -sticky nwse
        usercfg::show_option $o $opt
        incr o_idx
    }
}

#
# show config section group option
#
proc ::usercfg::show_option {o opt} {
    set o_name [lindex $opt 0]
    #~ set o_type [lindex $opt 1]
    #~ set o_defval [lindex $opt 2]
    #~ set o_show_desc [lindex $opt 3]
}
