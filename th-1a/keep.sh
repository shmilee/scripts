#!/bin/bash

try=0
target=${1:-th1aln2.local}

while [ $try -lt 20 ]; do
    date
    ssh $target
    if [[ $? == 0 ]]; then
        try=20 #正常退出
    else
        ((try++))
        sleep 60s
    fi
done

date
