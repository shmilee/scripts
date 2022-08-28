#!/bin/bash

for Season in 1 2; do
    if [[ $Season == 1 ]]; then
        N=43
    else
        N=34
    fi
    collection="巴塔木流行儿歌-第$Season季"
    src="$collection.html"
    cmd="you-get %s -O %s"
    for i in `seq 1 $N`; do
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
        titles=($(grep "$url\" title=\"" $src | sed "s|.*$url\" title=\"\([^\"]*\)\" .*|\1|g" | sed "/^$i$/d" | sed 's| |_|g'))
        if [[ ${#titles[@]} -ge 2 &&  ${titles[0]} != ${titles[1]} ]]; then
            echo "-----------> 第$i集 title 出错 <----------"
            echo "${titles[@]}"
            echo "-----------> <-----------"
            continue
        fi
        title=${titles[0]}
        echo "==> 第$i集 ${#titles[@]} titles: ${titles[@]}"
        echo "==> pick $title"
        out="$(printf "$collection-%s-%s.mp4" "第$i集" "$title")"
        if [ -f "$out" ]; then
            echo "--> !! $out exists! pass! <--"
            continue
        else
            torun="$(printf "$cmd\n" "$url" "$out")"
            echo "==> cmd: $torun"
            $torun
        fi
    done
done
    
