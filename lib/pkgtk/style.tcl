# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide style 0.0

package require usercfg

namespace eval ::style {
    namespace export cmdout
    namespace ensemble create
}

#
# set style for a text widget used to show cmd output (console like)
#
proc ::style::cmdout {w} {
    set colored [usercfg get_bool style console.colored]
    if {$colored} {
        set bg [usercfg get style console.background]
        set fg [usercfg get style console.foreground]
        set errfg [usercfg get style console.error_fg]
        set font [usercfg get style console.font]
        $w configure -background $bg -foreground $fg -font $font
        $w tag configure {cmderror} -foreground $errfg
    }
}
