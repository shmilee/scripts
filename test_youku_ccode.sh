#!/bin/bash

URL='https://ups.youku.com/ups/get.json?vid=XMTU0MzA4MDUyNA==&ccode={CCODE}&client_ip=192.168.1.1&utid=3yE%2BE3F5KEMCAT2xOYJYiCX8&client_ts=1521955818'

for c in `seq 0 99`; do
    ccode="05$c"
    #ccode="08$c"
    url="$(echo $URL | sed "s|{CCODE}|$ccode|")"
    out=$(curl "$url" 2>/dev/null | sed '/ccode参数错误/d')
    if [[ x"$out" != x ]]; then
        echo $ccode : $out
    fi
done

#0590
