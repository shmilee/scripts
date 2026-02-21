#!/bin/bash
# Copyright (C) 2026 shmilee

VERSION="${1:-2.5.16.20}"
# aTrust data repo dir
DATAREPO="${2:-./sangfor}"

aTrustDir=/usr/share/sangfor/aTrust
HOSTATDIR="${DATAREPO}/aTrust_amd64_v$VERSION"

deploy_data() {
    case "$VERSION" in
        2.4.10.50|2.5.16.20)
            deburl="https://atrustcdn.sangfor.com/standard/linux/$VERSION/uos/amd64/aTrustInstaller_amd64.deb"
            ;;
        *)
            echo ">> Not supported aTrust version: $VERSION"
            exit 1
            ;;
    esac
    # download & extract deb
    if [ ! -d "${DATAREPO}" ]; then
        mkdir -pv "${DATAREPO}"
    fi
    debfile="${DATAREPO}/aTrust_amd64_v$VERSION.deb"
    if [ ! -f "${debfile}" ]; then
        wget -c "${deburl}" -O "${debfile}"
    fi
    if [ ! -d "${HOSTATDIR}" ]; then
        mkdir /tmp/at-tmp
        bsdtar -v -x -f "${debfile}" -C /tmp/at-tmp
        bsdtar -v -x -f /tmp/at-tmp/data.tar.xz -C /tmp/at-tmp
        mv -v /tmp/at-tmp/${aTrustDir} "${HOSTATDIR}"
        rm -r /tmp/at-tmp/
    fi
    # misc files
    echo -n $VERSION >"${HOSTATDIR}/atversion"
    for fsh in hook_aTrust.sh hook_common.sh start.sh; do
        if [ ! -f "${HOSTATDIR}/$fsh" ]; then
            cp -v ./$fsh "${HOSTATDIR}/"
        fi
    done
    if [ ! -x "${HOSTATDIR}/start.sh" ]; then
        chmod +x "${HOSTATDIR}/start.sh"
    fi
    if [ ! -f "${DATAREPO}/at-$VERSION.desktop" ]; then
        echo "add desktop file: ${DATAREPO}/at-$VERSION.desktop"
        realHOSTATDIR="$(realpath ${HOSTATDIR})"
        sed -e "s|{{VERSION}}|$VERSION|" \
            -e "s|{{HOSTATDIR}}|${realHOSTATDIR}|" \
            ./at-example.desktop >"${DATAREPO}/at-$VERSION.desktop"
    fi
}

deploy_data
