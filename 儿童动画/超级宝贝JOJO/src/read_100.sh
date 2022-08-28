#!/bin/bash

# https://www.iqiyi.com/a_19rrhzqjm9.html

#src="1-50.html"
src="51-69.html"
cmd="you-get %s -O 超级宝贝JOJO-%s-%s.mp4"

#for i in `seq 1 50`; do
for i in `seq 51 69`; do
    urls=($(grep "第$i集" $src | sed 's|.*<a.*href="//\(.*.html\)" .*|\1|g'))
    if [[ ${#urls[@]} -ge 2 ]] && [[ ${urls[0]} != ${urls[1]} ]]; then
        echo "-----------> 第$i集 url 出错 <----------"
        echo "${urls[@]}"
        echo "-----------> <-----------"
        continue
    fi
    url=${urls[0]}
    echo "==> 第$i集 ${#urls[@]} urls: ${urls[@]}"
    echo "==> pick $url"
    titles=($(grep "$url\" title=\".*tuwenplay" $src | sed "s|.*$url\" title=\"\(.*\)\" rseat=.*|\1|g" | sed 's|" target="_blank||'| sed "/^$i$/d" | sed 's| |_|g'))
    if [[ ${#titles[@]} -ge 2 &&  ${titles[0]} != ${titles[1]} ]]; then
        echo "-----------> 第$i集 title 出错 <----------"
        echo "${titles[@]}"
        echo "-----------> <-----------"
        continue
    fi
    title=${titles[0]}
    echo "==> 第$i集 ${#titles[@]} titles: ${titles[@]}"
    echo "==> pick $title"
    torun="$(printf "$cmd\n" "$url" "第$i集" "$title")"
    $torun
done
