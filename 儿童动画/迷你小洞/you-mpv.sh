#!/bin/bash
# Copyright (C) 2023 shmilee

cat $1 | while read url; do
    echo $url
    you-get -p mpv $url
done
