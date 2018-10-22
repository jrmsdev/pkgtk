if test -d .git; then
    git branch -l | grep -E '^\* ' | cut -d ' ' -f 2
else
    echo 'NONE'
fi
