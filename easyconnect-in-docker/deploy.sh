#!/bin/bash
# Copyright (C) 2021 shmilee

# EC version to run, 7.6.3, 7.6.7
VERSION="${1:-7.6.3}"
# EC data repo dir
DATAREPO="${2:-./ECDATA}"

EasyConnectDir=/usr/share/sangfor/EasyConnect
HOSTECDIR="${DATAREPO}/EasyConnect_x64_v$VERSION"

deploy_data() {
    # deb url
    urlprefix='http://download.sangfor.com.cn/download/product/sslvpn/pkg'
    if [ x"$VERSION" = x"7.6.3" ]; then
        deburl="$urlprefix/linux_01/EasyConnect_x64.deb"
    elif [ x"$VERSION" = x"7.6.7" ]; then
        deburl="$urlprefix/linux_767/EasyConnect_x64_7_6_7_3.deb"
    else
        echo ">> Not supported EC version: $VERSION"
        exit 1
    fi
    # download & extract deb
    if [ ! -d "${DATAREPO}" ]; then
        mkdir -pv "${DATAREPO}"
    fi
    debfile="${DATAREPO}/EasyConnect_x64_v$VERSION.deb"
    if [ ! -f "${debfile}" ]; then
        wget -c "${deburl}" -O "${debfile}"
    fi
    if [ ! -d "${HOSTECDIR}" ]; then
        mkdir /tmp/ec-tmp
        bsdtar -v -x -f "${debfile}" -C /tmp/ec-tmp
        bsdtar -v -x -f /tmp/ec-tmp/data.tar.gz -C /tmp/ec-tmp
        mv -v /tmp/ec-tmp/${EasyConnectDir} "${HOSTECDIR}"
        rm -r /tmp/ec-tmp/
        mv -v "${HOSTECDIR}/resources/bin" "${HOSTECDIR}/resources/bin-orig"
        ln -s -v bin-orig "${HOSTECDIR}/resources/bin"
    fi
    # download & extract cli768 deb bin data
    urlprefix='https://github.com/shmilee/scripts/releases/download/v0.0.1'
    debfile="easyconn_7.6.8.2-ubuntu_amd64.deb"
    if [ ! -f "${DATAREPO}/${debfile}" ]; then
        wget -c "$urlprefix/${debfile}" -O "${DATAREPO}/${debfile}"
    fi
    if [ ! -d "${HOSTECDIR}/resources/bin-cli768" ]; then
        mkdir /tmp/ec-tmp
        bsdtar -v -x -f "${DATAREPO}/${debfile}" -C /tmp/ec-tmp
        bsdtar -v -x -f /tmp/ec-tmp/data.tar.xz -C /tmp/ec-tmp
        mv -v /tmp/ec-tmp/${EasyConnectDir}/resources/bin "${HOSTECDIR}/resources/bin-cli768"
        rm -r /tmp/ec-tmp/
    fi
    # misc files
    echo -n $VERSION >"${HOSTECDIR}/ecversion"
    if [ ! -f "${HOSTECDIR}/hook_script.sh" ]; then
        cp -v ./hook_script.sh "${HOSTECDIR}/hook_script.sh"
    fi
    if [ ! -f "${HOSTECDIR}/start.sh" ]; then
        cp -v ./start.sh "${HOSTECDIR}/start.sh"
    fi
    if [ ! -x "${HOSTECDIR}/start.sh" ]; then
        chmod +x "${HOSTECDIR}/start.sh"
    fi
    openurl="${HOSTECDIR}/resources/shell/open_browser.sh"
    if ! grep 'NEWURL' "$openurl" >/dev/null; then
        echo "edit resources/shell/open_browser.sh"
        sed -i "2iexit 0" "$openurl"
        sed -i "2iecho \"\$2\" >>${EasyConnectDir}/tmp-url" "$openurl"
        sed -i "2iecho 'NEWURL:' >>${EasyConnectDir}/tmp-url" "$openurl"
    fi
    if [ ! -f "${DATAREPO}/ec-$VERSION.desktop" ]; then
        echo "add desktop file: ${DATAREPO}/ec-$VERSION.desktop"
        realHOSTECDIR="$(realpath ${HOSTECDIR})"
        sed -e "s|{{VERSION}}|$VERSION|" \
            -e "s|{{HOSTECDIR}}|${realHOSTECDIR}|" \
            ./ec-example.desktop >"${DATAREPO}/ec-$VERSION.desktop"
    fi
}

deploy_data
