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
  - NEXT_PUBLIC_STORAGE_TYPE=upstash or redis, valkey
  - UPSTASH_URL=Your HTTPS ENDPOINT
  - UPSTASH_TOKEN=Your TOKEN
  - and NEXT_PUBLIC_SITE_NAME, KVROCKS_URL,
        REDIS_URL, VALKEY_PORT=16379 etc.

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
}

try_umount_dir() {
    if mountpoint -q "$1"; then
        echo "[!] umount $1 ..." && umount "$1" && rmdir "$1"
    fi
}

try_mount_squashfs() {
    try_umount_dir "$2" && mkdir -pv "$2" && squashfuse "$1" "$2"
}

# when NEXT_PUBLIC_STORAGE_TYPE=valkey -> redis
VALKEYDIR="${WORKDIR}"
start_valkey_server() {
    local name="$1"
    local vkport="${VALKEY_PORT:-16379}"
    local vkdbfile="$(get_valkeydbfile $name)"
    export REDIS_URL="redis://127.0.0.1:$vkport"
    echo -e "\nStarting valkey-server $REDIS_URL ..."
    echo "
bind 127.0.0.1
port $vkport
daemonize yes
pidfile ${VALKEYDIR}/valkey-$name.pid
dir ${VALKEYDIR}
dbfilename $vkdbfile
logfile valkey-$name.log
" | valkey-server - || exit 4
    while true; do
        if [ -f "${VALKEYDIR}/valkey-$name.pid" ]; then
            break
        fi
        sleep 1
    done
    echo "Valkey:"
    echo "  - pid: $(cat ${VALKEYDIR}/valkey-$name.pid)"
    echo "  - dir: ${VALKEYDIR}"
    echo "  - logfile: valkey-$name.log"
    echo "  - dbfile:  $vkdbfile"
    echo "  - connect: PING <-> $(valkey-cli -h 127.0.0.1 -p ${vkport} ping)"
    export NEXT_PUBLIC_STORAGE_TYPE=redis
}


if in_array "$1" ${AppNames[@]}; then
    Name="$1"
    Appdir="$(get_appdir $Name)"
    # main squashfs
    Appsquashfs="${WORKDIR}/${Appdir}.squashfs"
    if [ ! -f "$Appsquashfs" ]; then
        echo "[E] $Appsquashfs not found!"
        exit 2
    fi
    try_mount_squashfs "$Appsquashfs" "${WORKDIR}/${Appdir}"
    StartJS="${WORKDIR}/${Appdir}/start.js"
    # node_modules squashfs
    Modsquashfs="${WORKDIR}/$(get_nodemodsquashfs $Name)"
    if [ ! -f "$Modsquashfs" ]; then
        echo "[E] $Modsquashfs not found!"
        exit 2
    fi
    Modsdir="${Appdir}-node_modules"
    try_mount_squashfs "$Modsquashfs" "${WORKDIR}/${Modsdir}"
    export NODE_PATH="${WORKDIR}/${Modsdir}"

    umount_squashf() {
        try_umount_dir "${WORKDIR}/${Appdir}"
        try_umount_dir "${WORKDIR}/${Modsdir}"
    }

elif [ -f "$1" -a "$(basename "$1")" == "start.js" ]; then
    AppPath="$(dirname "$(readlink -f "$1")")"
    Name="$(basename "$AppPath")"
    StartJS="$1"
    umount_squashf() { :; }
    if [ "$NEXT_PUBLIC_STORAGE_TYPE" == "valkey" ]; then
        VALKEYDIR="$AppPath"
    fi
else
    usage
    exit 1
fi

trap "echo; umount_squashf" EXIT # exit 0-255
if [ "$NEXT_PUBLIC_STORAGE_TYPE" == "valkey" ]; then
    start_valkey_server $Name
    stop_valkey_server() {
        valkey_pid="$(cat ${VALKEYDIR}/valkey-$Name.pid)"
        echo "[!] Stop valkey-server($valkey_pid) $REDIS_URL ..."
        kill $valkey_pid
    }
    trap "echo; stop_valkey_server; umount_squashf" EXIT # exit 0-255
fi

echo -e "\n[$Name] Running ${StartJS} ...\n"
node "${StartJS}"
exit 0
