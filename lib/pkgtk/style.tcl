# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide style 0.0

namespace eval ::style {
    namespace export cmdout
    namespace ensemble create
}

#
# set style for a text widget used to show cmd output (console like)
#
proc ::style::cmdout {w} {
    $w configure -background "black" -foreground "white" -font "monospace 10"
    $w tag configure {cmderror} -foreground "red"
}
