#!/bin/bash
# Copyright (C) 2021 shmilee

# image tag
tag="${1:-210223}"

# params, like -p, -e etc.
params="${@:2}"

if [ x"$1" = x"-h" -o  x"$1" = x"--help" ]; then
    cat <<EOF
>> Usage:
    $0 <image tag> <params>
    TYPE=VNC $0 <image tag> <params>
>> params example:
# iptable  :  -e IPTABLES=1 -e IPTABLES_LEGACY=1
# danted   :  -e NODANTED=1 OR -p 127.0.0.1:1080:1080
# TYPE=VNC :  -e TYPE=VNC -e PASSWORD=x -e ECPASSWORD= -p 127.0.0.1:5901:5901
# sshd     :  -e SSHD=1 -e ROOTPASSWD=x1 -p 127.0.0.1:2222:22
EOF
    exit 0
fi

EasyConnectDir=/usr/share/sangfor/EasyConnect
HOSTECDIR="$(dirname $(realpath $0))"
echo ">>> Host Dir to mount: ${HOSTECDIR}"

use="${TYPE:-X11}"
if [ x"$use" = xX11 ]; then
    xhost +LOCAL:
    docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -i -t \
        -v ${HOSTECDIR}:${EasyConnectDir} \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v $HOME/.Xauthority:/root/.Xauthority \
        -e DISPLAY=$DISPLAY \
        $params \
        shmilee/easyconnect:$tag
    xhost -LOCAL:
else
    docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -i -t \
        -v ${HOSTECDIR}:${EasyConnectDir} \
        $params \
        shmilee/easyconnect:$tag
fi
