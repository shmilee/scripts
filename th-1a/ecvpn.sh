#!/bin/bash
# Copyright (C) 2021 shmilee

tag=210223

if [ x"$1" = x"th" ]; then
    # tianhe
    $HOME/.ECDATA/EasyConnect_x64_v7.6.7/start.sh $tag \
        -p 127.0.0.1:8413:1080
else
    # rvpn
    $HOME/.ECDATA/EasyConnect_x64_v7.6.3/start.sh $tag \
        -p 127.0.0.1:3600:1080
fi
