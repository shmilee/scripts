#!/bin/bash

url="${1}"
out="${2:-./output.mp4}"

if [ -z "$url" ]; then
    echo "usage: $0 <url>"
else
    wget -c "$url"
    index=$(basename "$url")
    xmap=$(sed -n '/#EXT-X-MAP:URI=/p' "$index" | sed 's|.*URI="\(.*\)"|\1|')
    dir=$(dirname "$url")
    names=($(sed '/^#/d' "$index"))
    echo "index: $index"
    echo "xmap: $xmap"
    echo "dir: $dir"
    echo "names(${#names[@]}): ${names[@]}"
    echo -e "\nStart ...\n"
    wget -c "$dir/$xmap"
    for seg in ${names[@]}; do
        wget -c "$dir/$seg"
    done
    cat $xmap ${names[@]} > $out
fi
