set -eu
test -d ./screenshots

for fpath in $(ls ./screenshots/*.png); do
    fname=$(basename ${fpath} .png)
    echo "## ${fname}"
    echo "![${fname}](${fpath})"
    echo ""
done
