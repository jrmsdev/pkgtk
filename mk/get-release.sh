TCLSH=${1}
export PKGTK_LIBDIR=lib/pkgtk
echo 'source lib/pkgtk/version.tcl; puts [version::release]' | ${TCLSH}
