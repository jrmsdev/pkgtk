# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide cmdexec 0.0
package require utils

namespace eval ::cmdexec {
    namespace export runbg rquery query stats lslocal lsremote search
    namespace ensemble create

    variable query_format {%n %v (%sh)\n\n%e}
    variable list_format {%o|%n-%v}
}

#
# run command in background and insert lines of output
#
proc ::cmdexec::runbg {out args {dryrun 0}} {
    set cmd "pkg $args"
    set chan [open "|$cmd" "r"]
    while {[gets $chan line] >= 0} {
        $out insert end "$line\n"
        update
    }
    try {
        close $chan
    } trap CHILDSTATUS {results options} {
        set rc [lindex [dict get $options -errorcode] 2]
        if {$dryrun && $rc == 1} {
            return
        } else {
            utils show_error "ERROR: $cmd ($rc)\n$results"
            $out insert end "*** ERROR: return code $rc\n"
            $out insert end $results
            update
        }
    }
}

#
# exec pkg rquery
#
proc ::cmdexec::rquery {args} {
    return [exec pkg rquery $cmdexec::query_format $args]
}

#
# exec pkg query
#
proc ::cmdexec::query {args} {
    return [exec pkg query $cmdexec::query_format $args]
}

#
# exec pkg stats
#
proc ::cmdexec::stats {args} {
    return [exec pkg stats $args]
}

#
# exec pkg to list local (installed) packages
#   only include noauto packages by default
#
proc ::cmdexec::lslocal {{inc "noauto"}} {
    if {$inc == "all"} {
        return [exec pkg query -a $cmdexec::list_format]
    }
    return [exec pkg query -e {%a == 0} $cmdexec::list_format]
}

#
# exec pkg to list remote (available) packages
#
proc ::cmdexec::lsremote {} {
    return [exec pkg rquery -a $cmdexec::list_format]
}

#
# exec pkg search
#
proc ::cmdexec::search {args} {
    return [exec pkg search -q $args]
}
