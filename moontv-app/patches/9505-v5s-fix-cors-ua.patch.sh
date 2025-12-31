#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

ts=src/lib/shortdrama.client.ts
if [ -f "$buildir/$ts" ]; then
    con1=$(grep "User-Agent" "$buildir/$ts")
    con2=$(grep "mode: 'cors'" "$buildir/$ts")
    if [ -n "$con1" -a -n "$con2" ]; then
        echo "[I] Fix shortdrama：CORS 的 'Access-Control-Allow-Headers'，不允许使用 'user-agent' in $ts"
        sed -i '/User-Agent/d' "$buildir/$ts"
    fi
fi
