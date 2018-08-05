# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide cmdexec 0.0

namespace eval ::cmdexec {
    namespace export rquery query stats lslocal lsremote search
    namespace ensemble create

    variable query_format {%n %v (%sh)\n\n%e}
    variable list_format {%o|%n-%v}
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
