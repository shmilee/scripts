#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

# ref: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Access-Control-Allow-Headers
# 浏览器console显示: 不支持指定 UA

ts=src/lib/shortdrama.client.ts
if [ -f "$buildir/$ts" ]; then
    con1=$(grep "User-Agent" "$buildir/$ts")
    con2="true" #con2=$(grep "mode: 'cors'" "$buildir/$ts") # 新版未指定 cors
    if [ -n "$con1" -a -n "$con2" ]; then
        echo "[I] Fix shortdrama：CORS 的 'Access-Control-Allow-Headers'，不允许使用 'user-agent' in $ts"
        sed -i '/User-Agent/d' "$buildir/$ts"
    fi
fi
