#!/bin/bash
# Copyright (C) 2021 shmilee

# image tag
TAG="${TAG:-210306}"
# X11, VNC, CLI
USEUI="${USEUI:-X11}"

if [ x"$1" = x"-h" -o  x"$1" = x"--help" ]; then
    cat <<EOF
>> Usage:
    $0 <params>
    TAG=<image tag> USEUI=<X11,VNC,CLI> $0 <params>
>> default TAG: ${TAG}
>> default USEUI: ${USEUI}
>> params example:
# iptable   :  -e IPTABLES=1 -e IPTABLES_LEGACY=1
# danted    :  -e NODANTED=1 OR -p 127.0.0.1:1080:1080
# USEUI=VNC :  -e PASSWORD=x -e ECPASSWORD= -p 127.0.0.1:5901:5901
# sshd      :  -e SSHD=1 -e ROOTPASSWD=x1 -p 127.0.0.1:2222:22
# USEUI=CLI :  -e ECADDRESS=x:p -e ECUSER= -e ECPASSWORD=
EOF
    exit 0
fi

EasyConnectDir=/usr/share/sangfor/EasyConnect
HOSTECDIR="$(dirname $(realpath $0))"
echo ">>> Host Dir to mount: ${HOSTECDIR}"

watch_url() {
    echo "Start watching url."
    echo >"${HOSTECDIR}"/tmp-url
    while true; do
        tail -n 0 -f "${HOSTECDIR}"/tmp-url | grep 'NEWURL:' -m1 >/dev/null
        if grep '#BREAK#' "${HOSTECDIR}"/tmp-url >/dev/null; then
            break
        fi
        xdg-open "$(tail -n1 ${HOSTECDIR}/tmp-url)"
    done
    echo "Stop watching url."
    rm "${HOSTECDIR}"/tmp-url
}

common_opts="--rm --device /dev/net/tun \
    --cap-add NET_ADMIN \
    --ulimit nofile=65535:65535 \
    -v ${HOSTECDIR}:${EasyConnectDir}"
# params, like -p, -e etc.
params="-e USEUI=$USEUI ${@}"
if [ x"$USEUI" = xVNC ]; then
    watch_url &
    docker run $common_opts $params -t \
        shmilee/easyconnect:$TAG
    echo 'NEWURL: #BREAK#' >>"${HOSTECDIR}"/tmp-url
elif [ x"$USEUI" = xCLI ]; then
    docker run $common_opts $params -i -t \
        shmilee/easyconnect:$TAG
else
    # default USEUI=X11
    watch_url &
    xhost +LOCAL:
    docker run $common_opts $params \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v $HOME/.Xauthority:/root/.Xauthority \
        -e DISPLAY=$DISPLAY \
        shmilee/easyconnect:$TAG
    xhost -LOCAL:
    echo 'NEWURL: #BREAK#' >>"${HOSTECDIR}"/tmp-url
fi

exit 0
