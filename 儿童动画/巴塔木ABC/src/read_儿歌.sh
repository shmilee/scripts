#!/bin/bash

# https://www.iqiyi.com/a_19rrhaw9hl.html

src="巴塔木儿歌.html"
cmd="you-get %s -O 巴塔木儿歌-%s-%s.mp4"

for i in `seq 1 81`; do
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
    titles=($(grep "$url\" title=\"" $src | sed "s|.*$url\" title=\"\(.*\)\" target.*|\1|g" | sed "/^$i$/d" | sed 's| |_|g'))
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
    #$torun
done

    
