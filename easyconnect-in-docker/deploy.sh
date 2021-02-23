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
    fi
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
}

deploy_data
