b=`git branch -l | grep -E '^\* ' | cut -d ' ' -f 2`
if test "${b}" != "master"; then
    echo ${b}
fi
