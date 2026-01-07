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
tsfile="src/app/api/ai-recommend/route.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep "console.log.*配置模式检测:" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log 配置模式检测: ... in $tsfile"
        mv -v "$buildir/$tsfile" "$buildir/$tsfile".orig
        # 多行
        awk '
            /^\s*console\.log.*配置模式检测:/ {
                in_console=1
            }
            in_console {
                sub(/^    /, "    //")
                if (/\}\);\s*$/) {
                    in_console=0
                }
            }
            {print}
            ' "$buildir/$tsfile".orig >"$buildir/$tsfile"
    fi
    if grep "console.log.*请求参数:" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log 请求参数: ... in $tsfile"
        sed -i "s|\(console.log.*请求参数:.*;$\)|//\1|" "$buildir/$tsfile"
    fi
fi
tsfile="src/app/api/favorites/route.ts"
if [ -f "$buildir/$tsfile" ]; then
    if grep "性能良好.*的收藏查询耗时" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log 性能良好.*的收藏查询耗时 ... in $tsfile"
        mv -v "$buildir/$tsfile" "$buildir/$tsfile".orig
        # 三行缓冲区
        awk '
            BEGIN {buffer=""}
            /^\s*console\.log\(/ {
              in_block=1
              buffer=$0
              next
            }
            in_block && /^\s*\);/ {
              buffer=buffer "\n" $0
              if (buffer ~ /性能良好.*收藏查询耗时/) {
                gsub(/\n   /, "\n //", buffer)
                print " //" buffer
              } else {
                print buffer
              }
              buffer=""
              in_block=0
              next
            }
            in_block {
              buffer=buffer "\n" $0
              next
            }
            {print}
            ' "$buildir/$tsfile".orig >"$buildir/$tsfile"
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
tsfile="src/components/UserMenu.tsx"
if [ -f "$buildir/$tsfile" ]; then
    if grep "console.log.*更新提醒调试:" "$buildir/$tsfile" >/dev/null; then
        echo "[I] //comment log 更新提醒调试 ... in $tsfile"
        mv -v "$buildir/$tsfile" "$buildir/$tsfile".orig
        # 多行
        awk '
            /^\s*console\.log.*更新提醒调试:/ {
                in_console=1
            }
            in_console {
                sub(/^  /, "  //")
                if (/\}\);\s*$/) {
                    in_console=0
                }
            }
            {print}
            ' "$buildir/$tsfile".orig >"$buildir/$tsfile"
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
        mv -v "$buildir/$tsfile" "$buildir/$tsfile".orig
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
            ' "$buildir/$tsfile".orig >"$buildir/$tsfile"
    fi
fi
