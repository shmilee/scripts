#!/bin/bash
# Copyright (C) 2025-2026 shmilee
#
# depends:
#   nodejs valkey(redis) curl
# depends for squashfs:
#   .BY. squashfuse fusermount
#   .OR. squashfs-tools
#       - `unsquashfs -d <path>`, https://github.com/plougher/squashfs-tools
#   .OR. squashfs-tools-ng in Termux & internal storage
#      - `rdsquashfs -p <path>`, https://github.com/AgentD/squashfs-tools-ng
#      - https://github.com/termux/termux-packages/issues/6537
#      - about special files such as symlinks:
#          + https://www.reddit.com/r/termux/comments/152dstc
#          + https://wiki.termux.com/wiki/Internal_and_external_storage

#set -e

WORKDIR="$(dirname $(readlink -f "$0"))"
source "$WORKDIR/github-repos.conf"
set -o allexport  # 或 set -a
if [ -f "$WORKDIR/env.conf" ]; then
    source "$WORKDIR/env.conf"
else
    source "$WORKDIR/env-example.conf"
fi
set +o allexport  # 或 set +a

in_array() {
    local s
    for s in ${@:2}; do
        [[ $s == $1 ]] && return 0
    done
    return 1
}

usage() {
    cat <<EOF
usage: [env_vars] $(basename "$0") [versions | /app/path[/xx.js]]

env-variable-file:
  - app  default: env-example.conf
  - user default: env.conf

versions:
EOF
    for name in ${AppNames[@]}; do
        local appsquashfs="${WORKDIR}/$(get_appdir $name).squashfs"
        local modsquashfs="${WORKDIR}/$(get_nodemodsquashfs $name)"
        printf "  - %-4s: %-23s of %-12s (%04s + %04s)\n" \
            "$name" "$(get_appver $name)" "$(get_showrepo $name)" \
            "$(du -h $appsquashfs 2>/dev/null | awk '/squashfs/{print $1}')" \
            "$(du -h $modsquashfs 2>/dev/null | awk '/squashfs/{print $1}')"
    done
}

# how to mount / extract squashfs file
FUSERMOUNT_CMD=$(command -v fusermount3 || command -v fusermount)
if [ -n "$FUSERMOUNT_CMD" ] && command -v squashfuse &>/dev/null; then
    SQUASHFS_MODE='MOUNT'
else
    SQUASHFS_MODE='EXTRACT'
    if command -v unsquashfs &>/dev/null; then
        EXTRACT_SQUASHFS='unsquashfs -d'  # $1=dir $2=squashfs-file
    elif command -v rdsquashfs &>/dev/null; then
        EXTRACT_SQUASHFS='rdsquashfs -u / -p' # $1=dir $2=squashfs-file
    else
        echo "[E] No SquashFS processing tool found!"
        echo "[E] Requires one of the following combinations:"
        echo "[E]   1. squashfuse + fusermount/fusermount3"
        echo "[E]   2. unsquashfs"
        echo "[E]   3. rdsquashfs"
        exit 2
    fi
fi

try_umount_dir() {
    # $1=dir
    if [[ "$SQUASHFS_MODE" == "MOUNT" ]]; then
        if mountpoint -q "$1"; then
            echo "[!] umount $1 ..." && $FUSERMOUNT_CMD -u "$1"
        fi
        if [ -d "$1" ]; then
            rmdir "$1"
        fi
    elif [[ "$SQUASHFS_MODE" == "EXTRACT" ]]; then
        if [ -d "$1"  -a ! -L "$1/MOON-EXTRACTED-SQUASHFS" ]; then
            rm -rv "$1/"
        fi
    fi
}

try_mount_squashfs() {
    # $1=squashfs-file, $2=dir
    if [[ "$SQUASHFS_MODE" == "MOUNT" ]]; then
        try_umount_dir "$2" && mkdir -pv "$2" && squashfuse "$1" "$2"
    elif [[ "$SQUASHFS_MODE" == "EXTRACT" ]]; then
        if [ -L "$2/MOON-EXTRACTED-SQUASHFS" ]; then
            : # do nothing
        else
            try_umount_dir "$2" && $EXTRACT_SQUASHFS "$2" "$1" && {
                # test special file: symlink
                echo "$(basename "$1")" >"$2/.MOON-EXTRACTED-SQUASHFS"
                ln -sv .MOON-EXTRACTED-SQUASHFS "$2/MOON-EXTRACTED-SQUASHFS" \
                    || exit 2
            }
        fi
    fi
}

# when NEXT_PUBLIC_STORAGE_TYPE=valkey -> redis
VALKEYDIR="${WORKDIR}" # default
VALKEY_SRVCMD="${VALKEY_SRVCMD:-valkey-server}" # or redis-server
_VALKEY="${VALKEY_SRVCMD/%-server/}" # valkey or redis
VALKEY_CLICMD="${VALKEY_CLICMD:-${_VALKEY}-cli}" # valkey-cli or redis-cli
start_valkey_server() {
    local name="$1"
    local vkport="${VALKEY_PORT:-16379}"
    local vkdbfile="$(get_valkeydbfile $name)"
    export REDIS_URL="redis://127.0.0.1:$vkport"
    echo -e "\nStarting $VALKEY_SRVCMD $REDIS_URL ..."
    echo "
bind 127.0.0.1
port $vkport
daemonize yes
pidfile ${VALKEYDIR}/${_VALKEY}-$name.pid
dir ${VALKEYDIR}
logfile ${_VALKEY}-$name.log
save 600 1 90 10 20 50
dbfilename $vkdbfile
" | $VALKEY_SRVCMD - || exit 4
    for i in $(seq 0 15); do
        if [ -f "${VALKEYDIR}/${_VALKEY}-$name.pid" ]; then
            valkey_pid="$(cat ${VALKEYDIR}/${_VALKEY}-$Name.pid)"
            #echo "'$(ps -q $valkey_pid -o comm=)' == '$VALKEY_SRVCMD'"
            if ps -q $valkey_pid -o comm= >/dev/null; then
                break
            else
                echo -e "\n[E] Failed to start $VALKEY_SRVCMD!" && exit 4
            fi
        fi
        if [ "$i" -ge 15 ]; then
            echo -e "\n[E] Failed to start $VALKEY_SRVCMD!" && exit 4
        fi
        echo -n -e "\\r[I] Waiting for $VALKEY_SRVCMD ... ${i}s ..."
        sleep 1
    done
    export NEXT_PUBLIC_STORAGE_TYPE=redis
    echo
    echo "${_VALKEY^}:"
    echo "  - pid: $(cat ${VALKEYDIR}/${_VALKEY}-$name.pid)"
    echo "  - dir: ${VALKEYDIR}"
    echo "  - logfile: ${_VALKEY}-$name.log"
    echo "  - dbfile:  $vkdbfile"
    #echo "  - connect: PING <-> $(${VALKEY_CLICMD} -u $REDIS_URL ping)"
}

# start
if in_array "$1" ${AppNames[@]}; then
    Name="$1"
    Appdir="$(get_appdir $Name)"
    echo "[I] Using SquashFS mode: $SQUASHFS_MODE"
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

elif [ -f "$1" -o -d "$1" ]; then
    if [ -f "$1" ]; then
        AppPath="$(dirname "$(readlink -f "$1")")"
    else
        AppPath="$(readlink -f "$1")"
    fi
    for dir in .next/{server,static} public scripts node_modules; do
        if [ ! -d "$AppPath/$dir" ]; then
            echo "[E] Dir $dir not found in $AppPath!"
            exit 3
        fi
    done
    for file in package.json server.js start.js public/manifest.json \
            .next/{BUILD_ID,server/app-paths-manifest.json}; do
        if [ ! -f "$AppPath/$file" ]; then
            echo "[E] File $file not found in $AppPath!"
            exit 3
        fi
    done
    Name="$(basename "$AppPath")"
    StartJS="$AppPath/start.js"
    umount_squashf() { :; }
    if [[ "$NEXT_PUBLIC_STORAGE_TYPE" == "valkey" ]]; then
        VALKEYDIR="$AppPath"
    fi
else
    if [ -n "$1" ]; then
        echo -e "[E] '$1' not found!\n"
    fi
    usage
    exit 1
fi

trap "echo; umount_squashf" EXIT # exit 0-255
if [[ "$NEXT_PUBLIC_STORAGE_TYPE" == "valkey" ]]; then
    start_valkey_server $Name
    stop_valkey_server() {
        valkey_pid="$(cat ${VALKEYDIR}/${_VALKEY}-$Name.pid)"
        echo "[!] Stop $VALKEY_SRVCMD($valkey_pid) $REDIS_URL ..."
        kill $valkey_pid
        if [ -f "${VALKEYDIR}/${_VALKEY}-$Name.pid" ]; then
            rm ${VALKEYDIR}/${_VALKEY}-$Name.pid
        fi
    }
    trap "echo; stop_valkey_server; umount_squashf" EXIT # exit 0-255
fi

if [[ "$NEXT_PUBLIC_STORAGE_TYPE" == "redis" ]]; then
    pong="$(${VALKEY_CLICMD} -u "$REDIS_URL" ping)"
    if [ -n "$pong" ]; then
        echo "$REDIS_URL connection: PING <-> $pong"
    else
        echo -e "\n[E] Failed to connect $REDIS_URL!"
        exit 5
    fi
fi

if [[ "${UPDATE_COLLECTIONS:-false}" == "true" ]]; then
    for conf in ${!ConfigCollections[@]}; do
        echo "=> Updating $conf from ${ConfigCollections[$conf]} ..."
        $CURLCMD -o "$WORKDIR/config-collections/$conf" \
            "${ConfigCollections[$conf]}"
    done
fi

echo -e "\n[$Name] Running ${StartJS} ...\n"
node "${StartJS}"
exit 0
