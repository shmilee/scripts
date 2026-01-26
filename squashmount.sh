#!/bin/bash
# Copyright (C) 2026 shmilee

set -euo pipefail

print_help() {
    cat <<EOF
Usage: $0 [options] <file_or_mountpoint> [...]

Options:
 -h            print this help
 -o opt[,...]  mount options for squashfuse
 -u            unmount mode
 -z            lazy unmount (only valid with -u)
EOF
}

MODE="mount"
MOUNT_OPTS=""
LAZY=0

# 解析选项
while getopts ":huo:z" opt; do
    case "$opt" in
        h)
            print_help
            exit 0
            ;;
        u)
            MODE="umount"
            ;;
        o)
            MOUNT_OPTS="$OPTARG"
            ;;
        z)
            LAZY=1
            ;;
        \?)
            echo "Unknown option: -$OPTARG"
            print_help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

if [[ $# -eq 0 ]]; then
    echo "Error: no files or mountpoints specified"
    print_help
    exit 1
fi

BASE="/media/squashfs"
if [ ! -d "$BASE" ]; then
    mkdir -p "$BASE"
fi

# 获取挂载点
get_mount_point() {
    local arg="$1"
    local mp=""
    if [[ -f "$arg" ]]; then
        local basename="$(basename "$arg" .squashfs)"
        mp="$BASE/$basename"
    elif [[ -d "$arg" ]]; then
        mp="$arg"
    else
        mp="$BASE/$arg"
    fi
    echo "$mp"
}

# 挂载
mount_sqf() {
    local file="$1"
    local mp="$BASE/$(basename "$file" .squashfs)"
    if mountpoint -q "$mp"; then
        echo "跳过已挂载: $mp"
        return
    fi
    mkdir -p "$mp"
    if [[ -n "$MOUNT_OPTS" ]]; then
        squashfuse -o "$MOUNT_OPTS" "$file" "$mp"
    else
        squashfuse "$file" "$mp"
    fi
    echo "已挂载: $file → $mp"
}

# 卸载
umount_sqf() {
    local arg="$1"
    local mp
    mp="$(get_mount_point "$arg")"
    if ! mountpoint -q "$mp"; then
        echo "跳过未挂载: $mp"
        return
    fi
    if [[ "$LAZY" -eq 1 ]]; then
        fusermount -uz "$mp"
    else
        fusermount -u "$mp"
    fi
    rmdir "$mp" || true
    echo "已卸载: $mp"
}

# main
for f in "$@"; do
    if [[ "$MODE" == "mount" ]]; then
        if [[ ! -f "$f" ]]; then
            echo "挂载失败: 不是 squashfs 文件: $f"
            continue
        fi
        mount_sqf "$f"
    else
        umount_sqf "$f"
    fi
done
