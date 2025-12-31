#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

# ref:
# https://stackoverflow.com/questions/76491865/failing-filter-drop-shadow-on-transition-using-safari

for tsx in src/components/{VideoCard.tsx,ShortDramaCard.tsx}; do
    if grep "hover:drop-shadow-2xl" "$buildir/$tsx" >/dev/null; then
        echo "[I] Fix VideoCard 鼠标悬浮时，元素消失 in $tsx ..."
        sed -i "s|hover:drop-shadow-2xl|hover:shadow-2xl|" "$buildir/$tsx"
    fi
done
