TCLSH=${1}
export PKGTK_LIBDIR=lib/pkgtk
v=`echo 'source lib/pkgtk/version.tcl; puts [version::release]' | ${TCLSH}`
b=`sh -eu mk/release-branch.sh`
if test "${b}" != "master"; then
    echo "${v}+${b}"
else
    echo ${v}
fi
