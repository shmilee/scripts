#!/bin/bash
# Copyright (C) 2025 shmilee

set -e

WORKDIR="$(dirname $(readlink -f "$0"))"
source "$WORKDIR/github-repos.conf"

export NODE_ENV=production
export USERNAME=${USERNAME:-admin}
export PASSWORD=${PASSWORD:-admin_password}
export PORT=${PORT:-3000}
export NEXT_PUBLIC_STORAGE_TYPE=${NEXT_PUBLIC_STORAGE_TYPE:-upstash}

in_array() {
    local s
    for s in ${@:2}; do
        [[ $s == $1 ]] && return 0
    done
    return 1
}

usage() {
    cat <<EOF
usage: [env_vars] $(basename "$0") [versions | or/path/to/start.js]

env-variables:
  - USERNAME=admin
  - PASSWORD=admin_password
  - PORT=3000
  - NEXT_PUBLIC_STORAGE_TYPE=upstash
  - UPSTASH_URL=Your HTTPS ENDPOINT
  - UPSTASH_TOKEN=Your TOKEN
  - and NEXT_PUBLIC_SITE_NAME, KVROCKS_URL, REDIS_URL, etc.

versions:
EOF
    for name in ${AppNames[@]}; do
        local appsquashfs="${WORKDIR}/$(get_appdir $name).squashfs"
        local modsquashfs="${WORKDIR}/$(get_nodemodsquashfs $name)"
        printf "  - %-4s: %-21s of %-16s (%s + %s)\n" \
            "$name" "$(get_appver $name)" "$(get_showrepo $name)" \
            "$(du -h $appsquashfs 2>/dev/null | awk '/squashfs/{print $1}')" \
            "$(du -h $modsquashfs 2>/dev/null | awk '/squashfs/{print $1}')"
    done
    exit 1
}

try_umount_dir() {
    if mountpoint -q "$1"; then
        echo "[!] umount $1 ..." && umount "$1" && rmdir "$1"
    fi
}

try_mount_squashfs() {
    try_umount_dir "$2" && mkdir -pv "$2" && squashfuse "$1" "$2"
}

Name="$1"

if in_array "$Name" ${AppNames[@]}; then
    Appdir="$(get_appdir $Name)"
    # main squashfs
    Appsquashfs="${WORKDIR}/${Appdir}.squashfs"
    if [ ! -f "$Appsquashfs" ]; then
        echo "[E] $Appsquashfs not found!"
        exit 2
    fi
    try_mount_squashfs "$Appsquashfs" "${WORKDIR}/${Appdir}"
    # node_modules squashfs
    Modsquashfs="${WORKDIR}/$(get_nodemodsquashfs $Name)"
    if [ ! -f "$Modsquashfs" ]; then
        echo "[E] $Modsquashfs not found!"
        exit 2
    fi
    Modsdir="${Appdir}-node_modules"
    try_mount_squashfs "$Modsquashfs" "${WORKDIR}/${Modsdir}"

    umount_squashf() {
        try_umount_dir "${WORKDIR}/${Appdir}"
        try_umount_dir "${WORKDIR}/${Modsdir}"
    }
    trap umount_squashf EXIT # exit 0-255

    export NODE_PATH="${WORKDIR}/${Modsdir}"
    echo -e "\n[$Name] Running ${WORKDIR}/${Appdir}/start.js ...\n"
    node "${WORKDIR}/${Appdir}/start.js"

elif [ -f "$1" -a "$(basename "$1")" == "start.js" ]; then
    node "$1"
else
    usage
fi
