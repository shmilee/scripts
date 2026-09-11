#!/bin/bash
# Copyright (C) 2026 shmilee

# TopSAP version
VERSION="${1:-3.6.3.17.2}"
# TopSAP data repo dir
DATAREPO="${2:-./sangfor}"

TopSAPDir=/opt/TopSAP
HOSTTSAPDIR="${DATAREPO}/TopSAP_x64_v${VERSION}"

deploy_data() {
    # download the deb
    deburl="https://app.topsec.com.cn/linux/general/x86_64/deb/TopSAP-${VERSION}-x86_64.deb"
    if [ ! -d "${DATAREPO}" ]; then
        mkdir -pv "${DATAREPO}"
    fi
    debfile="${DATAREPO}/TopSAP-${VERSION}-x86_64.deb"
    if [ ! -f "${debfile}" ]; then
        wget -c "${deburl}" -O "${debfile}"
    fi
    echo ">> using deb: $debfile"
    # extract deb -> data.tar.* -> opt/TopSAP
    if [ ! -d "${HOSTTSAPDIR}" ]; then
        rm -rf /tmp/ts-tmp && mkdir /tmp/ts-tmp
        bsdtar -x -f "$debfile" -C /tmp/ts-tmp
        local datatar
        datatar="$(ls /tmp/ts-tmp/data.tar.* 2>/dev/null | head -1)"
        if [ -z "$datatar" ]; then
            echo ">> no data.tar.* found in deb!" >&2
            exit 1
        fi
        bsdtar -x -f "$datatar" -C /tmp/ts-tmp
        mv -v /tmp/ts-tmp/opt/TopSAP "${HOSTTSAPDIR}"
        rm -rf /tmp/ts-tmp/
    fi

    # misc files
    echo -n "$VERSION" >"${HOSTTSAPDIR}/tsversion"
    for fsh in hook_TopSAP.sh hook_common.sh start.sh; do
        if [ ! -f "${HOSTTSAPDIR}/$fsh" ]; then
            cp -v "./$fsh" "${HOSTTSAPDIR}/"
        fi
    done
    if [ ! -x "${HOSTTSAPDIR}/start.sh" ]; then
        chmod +x "${HOSTTSAPDIR}/start.sh"
    fi
    if [ ! -f "${DATAREPO}/ts-$VERSION.desktop" ]; then
        echo "add desktop file: ${DATAREPO}/ts-$VERSION.desktop"
        realHOSTTSAPDIR="$(realpath ${HOSTTSAPDIR})"
        sed -e "s|{{VERSION}}|$VERSION|" \
            -e "s|{{HOSTTSAPDIR}}|${realHOSTTSAPDIR}|" \
            ./ts-example.desktop >"${DATAREPO}/ts-$VERSION.desktop"
    fi
    echo ">> deployed TopSAP ${VERSION} to ${HOSTTSAPDIR}"
}

deploy_data
