#!/bin/bash
# Copyright (C) 2025 shmilee

WORKDIR="$(dirname $(readlink -f "$0"))"
source "$WORKDIR/github-repos.conf"
mkdir -pv "$WORKDIR/pkg"

# copy squashfs & manifest
package_app() {
    local name="$1"
    local appdir="$(get_appdir $name)"
    local modsname="$(get_nodemodsname $name)"
    local modsqfs0="$(get_nodemodsquashfs $name)"
    local modsqfs1="$(get_nodemodsquashfs $modsname)"
    local appsqfs="${appdir}.squashfs"
    local manifest="${appdir}-manifest.json"

    if [ "$name" == "$modsname" ]; then
        echo "[$name] 1) node_modules: $modsqfs0"
        cp -v "$WORKDIR/dist/$modsqfs0" "$WORKDIR/pkg/"
    else
        echo "[$name] 1) node_modules link to: $modsqfs1"
        ln -sfv "$modsqfs1" "$WORKDIR/pkg/$modsqfs0"
    fi
    echo "[$name] 2) app: $appsqfs"
    cp -v "$WORKDIR/dist/$appsqfs" "$WORKDIR/pkg/"
    echo "[$name] 3) manifest: $manifest"
    cp -v "$WORKDIR/dist/$manifest" "$WORKDIR/pkg/"
}

for name in ${AppNames[@]}; do
    echo && package_app "$name"
done
cp -v "${WORKDIR}/github-repos.conf" "${WORKDIR}/pkg/"
cp -v "${WORKDIR}/moontv-start.sh" "${WORKDIR}/pkg/"
cp -rv "$WORKDIR/dist/config-collections" "${WORKDIR}/pkg/"
cp -rv "$WORKDIR/dist/next-cache" "${WORKDIR}/pkg/"
echo && ls -lh "$WORKDIR/pkg/"
