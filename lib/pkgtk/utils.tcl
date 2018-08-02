# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide utils 0.0

namespace eval ::utils {
    namespace export dispatch_view show_error tkbusy_hold tkbusy_forget
    namespace ensemble create
}

#
# dispatch view
#
proc ::utils::dispatch_view {name} {
    set w .view
    if [winfo exists $w] {
        destroy $w
    }
    $name $w
}

#
# show error message
#
proc ::utils::show_error {msg} {
    tk_messageBox -parent . -title "pkgtk error" -message "$msg" \
                  -type "ok" -icon "error"
}

#
# tk busy hold
#
proc ::utils::tkbusy_hold {{w .}} {
    tk busy hold $w
    tk busy configure $w -cursor watch
    update
}

#
# tk busy forget
#
proc ::utils::tkbusy_forget {{w .}} {
    tk busy forget $w
    update
}
