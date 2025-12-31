#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

tsx=src/app/play/page.tsx
if grep "<h1 className='text-xl.* truncate'>" "$buildir/$tsx" >/dev/null; then
    echo "[I] Fix mpv button 鼠标悬浮时，被 truncated in $tsx ..."
    sed -i "s|\(<h1 className='text-xl.*\) truncate'>|\1'>|" \
        "$buildir/$tsx"
fi
