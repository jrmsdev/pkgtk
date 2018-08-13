# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide cmdexec 0.0
package require utils

namespace eval ::cmdexec {
    namespace export runbg rquery query stats lslocal lsremote search
    namespace ensemble create

    variable pkg_rootdir ""
    variable query_format {%n %v (%sh)\n\n%e}
    variable list_format {%o|%n-%v}
    variable bgdone 0

    if {[info exists ::env(PKGTK_ROOTDIR)]} {
        set pkg_rootdir $::env(PKGTK_ROOTDIR)
    }
}

#
# generate the proper command line to call pkg
#   return a list
#
proc ::cmdexec::getcmd {args} {
    set cmd [list pkg]
    if {$cmdexec::pkg_rootdir != ""} {
        lappend cmd "-r" $cmdexec::pkg_rootdir
    }
    foreach {a} $args {
        lappend cmd $a
    }
    return $cmd
}

#
# read a line of output from running background command/process
#
proc ::cmdexec::bgread {out dryrun chan} {
    if {[gets $chan line] >= 0} {
        $out insert end "$line\n"
        #~ update
    }
    if {[eof $chan]} {
        puts "bgread: eof"
        try {
            puts "bgread: close"
            close $chan
        } trap CHILDSTATUS {results options} {
            set rc [lindex [dict get $options -errorcode] 2]
            set fatalerror [expr $dryrun && $rc == 1]
            puts "bgread rc: $rc"
            puts "bgread fatalerror: $fatalerror"
            if {$fatalerror} {
                utils show_error "ERROR: $cmd ($rc)\n$results"
                $out insert end "*** ERROR: return code $rc\n"
                $out insert end $results
                #~ update
            }
        } finally {
            puts "bgread: done!"
            set cmdexec::bgdone 1
        }
    }
}

#
# run command in background and insert lines of output
#
proc ::cmdexec::runbg {out args {dryrun 0}} {
    set cmdexec::bgdone 0
    set cmd [join [cmdexec::getcmd $args] " "]
    set chan [open "|$cmd" "r"]
    fconfigure $chan -blocking 0 -buffering line
    fileevent $chan readable [list cmdexec::bgread $out $dryrun $chan]
    tkwait variable cmdexec::bgdone
}

#
# exec pkg rquery
#
proc ::cmdexec::rquery {args} {
    set cmd [cmdexec::getcmd rquery $cmdexec::query_format $args]
    return [exec {*}$cmd]
}

#
# exec pkg query
#
proc ::cmdexec::query {args} {
    set cmd [cmdexec::getcmd query $cmdexec::query_format $args]
    return [exec {*}$cmd]
}

#
# exec pkg stats
#
proc ::cmdexec::stats {args} {
    set cmd [cmdexec::getcmd stats $args]
    return [exec {*}$cmd]
}

#
# exec pkg to list local (installed) packages
#   only include noauto packages by default
#
proc ::cmdexec::lslocal {{inc "noauto"}} {
    if {$inc == "all"} {
        set cmd [cmdexec::getcmd query -a $cmdexec::list_format]
    } else {
        set cmd [cmdexec::getcmd query -e {%a == 0} $cmdexec::list_format]
    }
    return [exec {*}$cmd]
}

#
# exec pkg to list remote (available) packages
#
proc ::cmdexec::lsremote {} {
    set cmd [cmdexec::getcmd rquery -a $cmdexec::list_format]
    return [exec {*}$cmd]
}

#
# exec pkg search
#
proc ::cmdexec::search {args} {
    set cmd [cmdexec::getcmd search -q $args]
    return [exec {*}$cmd]
}
