# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide version 0.0

namespace eval ::version {
    variable VERSION 0.8
    variable RELEASE 0
}

#
# print release info to stdout (used from Makefile)
#
proc ::version::release {} {
    set v $version::VERSION
    if {$version::RELEASE > 0} {
        set v "$v.$version::RELEASE"
    }
    set release_branch_fn [file join $::env(PKGTK_LIBDIR) "release-branch.txt"]
    if {[file isfile $release_branch_fn]} {
        set fh [open $release_branch_fn]
        set b "NOBRANCH"
        if {[gets $fh b] < 1} {
            set b "ERRBRANCH"
        }
        close $fh
        set v "$v+$b"
    }
    return $v
}
