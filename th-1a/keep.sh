#!/bin/bash

try=0

while [ $try -lt 20 ]; do
    date
    ssh th2
    if [[ $? == 0 ]]; then
        try=20 #正常退出
    else
        ((try++))
    fi
    date
    sleep 60s
done
