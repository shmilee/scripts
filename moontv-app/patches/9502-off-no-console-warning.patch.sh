#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

if [ -f "$buildir/.eslintrc.js" ]; then
    if grep "'no-console': 'warn'" "$buildir/.eslintrc.js" >/dev/null; then
        echo "[I] Ignore no-console Warning in .eslintrc.js ..."
        sed -i "s|'no-console': 'warn'|'no-console': 'off'|" "$buildir/.eslintrc.js"
    fi
fi
