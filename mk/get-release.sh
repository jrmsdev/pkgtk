TCLSH=${1}
r=`echo 'source lib/pkgtk/version.tcl; puts [version::release]' | ${TCLSH}`
b=`git branch -l | grep -E '^\* ' | cut -d ' ' -f 2`
if test "${b}" != "master"; then
    r="${r}+${b}"
fi
echo ${r}
