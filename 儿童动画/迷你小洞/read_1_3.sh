#!/bin/bash

src=${1:-"迷你小洞-第一季.gz"}
season=${src%.*}
cmd="you-get %s -O ${season}-%s.mp4"
##m3u8="${season}.m3u8"
##echo "#EXTM3U" > $m3u8
youmpvlist="${season}.txt"
echo -n > $youmpvlist

n=1
zcat $src | sed 's|<!---->|\n|g' | sed -n "/href=.*html/p" | while read line; do
    url=$(echo $line | sed "s|.*href=\"\(//.*.html\)\".*title=.*|\1|g")
    if [[ x$url == x ]]; then
        echo "-----------> $line  No url <----------"
        continue
    fi
    url="https:$url"
    echo "==> 第$n集 url: $url"
    title=$(echo $line | sed "s|.*\" title=\"\(.*\)\" class=\"album.*|\1|g")
    if [[ x$title == x ]]; then
        title="第$n集"
        echo "-----------> 第$n集 title: 出错 <----------"
    fi
    ##echo "#EXTINF:$n, $title" >> $m3u8
    ##echo "$url" >> $m3u8
    echo "$url" >> $youmpvlist
    n=$((n+1))
    torun="$(printf "$cmd\n" "$url" "$title")"
    echo $torun
    #$torun
    #break
done
