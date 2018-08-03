# Copyright (c) Jeremías Casteglione <jrmsdev@gmail.com>.
# See LICENSE file.

package provide img 0.0

namespace eval ::img {
    namespace export create_icon
    namespace ensemble create
}

#
# create icon
#
proc ::img::create_icon {top} {
    image create photo pkgtkicon -width 16 -height 16

    pkgtkicon put #c00000 -to 0 12 3 15

    pkgtkicon put #0000c0 -to 4 12 7 15
    pkgtkicon put #0000c0 -to 0 8 3 11

    pkgtkicon put #00c000 -to 8 12 11 15
    pkgtkicon put #00c000 -to 4 8 7 11
    pkgtkicon put #00c000 -to 0 4 3 7

    pkgtkicon put #c00000 -to 0 0 3 3
    pkgtkicon put #c00000 -to 4 4 7 7
    pkgtkicon put #c00000 -to 8 8 11 11
    pkgtkicon put #c00000 -to 12 12 15 15

    pkgtkicon put #00c000 -to 4 0 7 3
    pkgtkicon put #00c000 -to 8 4 11 7
    pkgtkicon put #00c000 -to 12 8 15 11

    pkgtkicon put #0000c0 -to 8 0 11 3
    pkgtkicon put #0000c0 -to 12 4 15 7

    pkgtkicon put #c00000 -to 12 0 15 3

    image create photo pkgtkicon32 -width 32 -height 32
    pkgtkicon32 copy pkgtkicon -zoom 2 2

    wm iconphoto $top -default pkgtkicon pkgtkicon32
}
