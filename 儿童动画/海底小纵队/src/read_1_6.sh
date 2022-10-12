#!/bin/bash

src=${1:-"第1季.html.gz"}
season=${src%.*}
cmd="you-get %s -O 海底小纵队-${season}-%s" # rm .mp4?

n=1
zcat $src | sed -n "/href=.*html/p" | while read line; do
    url=$(echo $line | sed "s|.*href=\"\(https://.*.html\)\".*title=.*|\1|g")
    if [[ x$url == x ]]; then
        echo "-----------> $line  No url <----------"
        continue
    fi
    echo "==> 第$n集 url: $url"
    title=$(echo $line | sed "s|.*\" title=\"\(.*\)\" dt-eid=.*|\1|g")
    if [[ x$title == x ]]; then
        title="第$n集"
        echo "-----------> 第$n集 title: 出错 <----------"
    else
        if [[ $n -ge 10 ]]; then
            sn=$n
        else
            sn="0$n"
        fi
        # 5-6-特别
        if echo $title | grep "第$sn话" >/dev/null; then
            title=$(echo $title | sed -e "s/第$sn话//" -e 's/^[ ]*//')
        elif echo $title | grep "海底小纵队特别篇" >/dev/null; then
            title=$(echo $title | sed -e "s/海底小纵队特别篇$n：//")
        fi
        if [[ x$title == x"海底小纵队第五季" ]]; then
            title="第$n集"
        else
            title="第$n集-$title"
        fi
        echo "==> 第$n集 title: $title"
    fi
    n=$((n+1))
    torun="$(printf "$cmd\n" "$url" "$title")"
    echo $torun
    $torun
    #break
done
