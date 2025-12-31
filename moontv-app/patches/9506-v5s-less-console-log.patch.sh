#!/bin/bash
# Copyright (C) 2025 shmilee

name="$1"
buildir="$2"

# comment some console.log
tsfile="src/app/api/admin/theme/route.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep "console.log('完整配置对象" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log '完整配置对象' in $tsfile"
        sed -i "s|\(console.log('完整配置对象\)|//\1|" "$buildir/$tsfile"
    fi
fi
tsfile="src/app/api/user/my-stats/route.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep "console.log('更新用户统计数据" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log '更新用户统计数据' in $tsfile"
        sed -i "s|\(console.log('更新用户统计数据\)|//\1|" "$buildir/$tsfile"
    fi
    if grep "console.log.*my-stats - 开始处理请求" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log 'my-stats - 开始处理请求' in $tsfile"
        sed -i "s|\(console.log.*my-stats - 开始处理请求\)|//\1|" "$buildir/$tsfile"
    fi
fi
tsfile="src/lib/downstream.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep 'console.log(`\[DEBUG\]' "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log [DEBUG] in $tsfile"
        sed -i 's|console.log(`\[DEBUG\]|//console.log(`\[DEBUG\]|' "$buildir/$tsfile"
    fi
fi
tsfile="src/middleware.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep 'console.log(`\[Middleware.*;$' "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log [Middleware ...] in $tsfile"
        sed -i "s|\(console.log.*Middleware.*requestId.*;$\)|//\1|" "$buildir/$tsfile"
        # 多行
        awk '
            /^\s*console\.log.*\[Middleware.*Auth info from cookie/ {
                in_console=1
            }
            in_console {
                sub(/^  /, "  //")
                if (/: null\);\s*$/) {
                    in_console=0
                }
            }
            {print}
            ' "$buildir/$tsfile" >"$buildir/$tsfile.temp" \
        && mv "$buildir/$tsfile.temp" "$buildir/$tsfile"
    fi
fi
