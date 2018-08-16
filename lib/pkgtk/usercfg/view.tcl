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

    $cfg add [usercfg::view::style $cfg.style] -text [mc "Style"] -sticky nwse
}

#
# view style configs
#
proc ::usercfg::view::style {w} {
    ttk::frame $w
    grid $w -sticky nwse

    set console $w.console
    ttk::labelframe $console -text [mc "Console"]
    grid $console -row 0 -column 0 -sticky nwse

    if {[usercfg get style console.colored]} {
        ttk::label $w.console.lalala -text "LALALA"
        grid $w.console.lalala -sticky nwse
    } else {
        ttk::label $w.console.lalala -text "LELELE"
        grid $w.console.lalala -sticky nwse
    }

    return $w
}
