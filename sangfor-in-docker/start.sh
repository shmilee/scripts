#!/bin/bash
# Copyright (C) 2021-2026 shmilee

# image tag
TAG="${TAG:-260221}"
# X11, VNC, CLI
UI="${UI:-X11}"
HOSTDIR="$(dirname $(realpath $0))"
SHOSTNAME=${SHOSTNAME:-e666181fe505}
SMACADDR=${SMACADDR:-9a:9d:df:f8:06:33}

if [ x"$1" = x"-h" -o  x"$1" = x"--help" ]; then
    cat <<EOF
>> Usage:
    $0 <params>
    TAG=<image tag> UI=<X11,VNC,CLI> $0 <params>
>> default TAG: ${TAG}
>> default  UI: ${UI}
>> default SHOSTNAME: ${SHOSTNAME}
>> default  SMACADDR: ${SMACADDR}
>> params example:
# iptable :  -e IPTABLES=1 -e IPTABLES_LEGACY=1
# danted  :  -e NODANTED=1 OR -p 127.0.0.1:1080:1080
# sshd    :  -e SSHD=1 -e ROOTPASSWD=x1 -p 127.0.0.1:2222:22
# UI=VNC  :  -e PASSWORD=x -e ECPASSWORD=xx -p 127.0.0.1:5901:5901
# UI=CLI for EasyConnect :  -e ECADDRESS=x:p -e ECUSER= -e ECPASSWORD=xx
EOF
    exit 0
fi

if echo "$(basename $HOSTDIR)" | grep EasyConnect >/dev/null 2>&1; then
    VPN=EasyConnect
    VPN_DIR=/usr/share/sangfor/EasyConnect
elif echo "$(basename $HOSTDIR)" | grep aTrust >/dev/null 2>&1; then
    VPN=aTrust
    VPN_DIR=/usr/share/sangfor/aTrust
else
    echo "!!! can't set VPN: EasyConnect or aTrust!"
    exit 1
fi

echo ">>> $VPN Host Dir to mount: ${HOSTDIR}"

common_opts="--rm --device /dev/net/tun \
    --cap-add NET_ADMIN \
    --hostname ${SHOSTNAME} --mac-address ${SMACADDR} \
    --ulimit nofile=65535:65535 \
    -v ${HOSTDIR}:${VPN_DIR} \
    -e VPN=$VPN -e UI=$UI"

# params, like -p, -e etc.
params="${@}"
if [ x"$UI" = xVNC ]; then
    if echo "$params" | grep "5901:5901" >/dev/null 2>&1; then
        params="$params -p 127.0.0.1:5901:5901"
    fi
fi
if [ x"$UI" = xX11 ]; then
    params="$params \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v $HOME/.Xauthority:/root/.Xauthority \
        -e DISPLAY=$DISPLAY"
fi

watch_url() {
    echo "Start watching url."
    echo >"${HOSTDIR}"/tmp-url
    while true; do
        tail -n 0 -f "${HOSTDIR}"/tmp-url | grep 'NEWURL:' -m1 >/dev/null
        if grep '#BREAK#' "${HOSTDIR}"/tmp-url >/dev/null; then
            break
        fi
        xdg-open "$(tail -n1 ${HOSTDIR}/tmp-url)"
    done
    echo "Stop watching url."
    rm "${HOSTDIR}"/tmp-url
}

case "$VPN" in
    EasyConnect)
        if [ x"$UI" = xCLI ]; then
            docker run $common_opts $params -i -t shmilee/sangfor:$TAG
        elif [ x"$UI" = xVNC ]; then
            watch_url &
            docker run $common_opts $params -t shmilee/sangfor:$TAG
            echo 'NEWURL: #BREAK#' >>"${HOSTDIR}"/tmp-url
        else
            # default UI=X11
            watch_url &
            xhost +LOCAL:
            docker run $common_opts $params shmilee/sangfor:$TAG
            xhost -LOCAL:
            echo 'NEWURL: #BREAK#' >>"${HOSTDIR}"/tmp-url
        fi
        ;;
    aTrust)
        ROOT_DATADIR="$(dirname $HOSTDIR)/atrust-root-data"
        params="$params -v $ROOT_DATADIR:/root"
        if [ x"$UI" = xVNC ]; then
            docker run $common_opts $params -t shmilee/sangfor:$TAG
        else
            # default UI=X11
            xhost +LOCAL:
            docker run $common_opts $params shmilee/sangfor:$TAG
            xhost -LOCAL:
        fi
        ;;
esac
exit 0
