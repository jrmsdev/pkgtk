# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide version 0.0

namespace eval ::version {
    variable VERSION 0.6
    variable RELEASE 180816
}

#
# print release info to stdout (used from Makefile)
#
proc ::version::release {} {
    set v $version::VERSION
    if {$version::RELEASE > 0} {
        set v "$v.$version::RELEASE"
    }
    puts $v
}
