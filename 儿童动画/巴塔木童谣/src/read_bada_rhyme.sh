#!/bin/bash

for Season in 1 2; do
    if [[ $Season == 1 ]]; then
        N=12
    else
        N=14
    fi
    collection="巴塔木童谣-第$Season季"
    src="$collection.html"
    cmd="you-get %s -O %s"
    for i in `seq 1 $N`; do
        urls=($(grep "html\".*第$i集" $src | sed 's|.*<a.*href="//\(.*.html\)" .*|\1|g'))
        if [[ ${#urls[@]} -ge 2 ]] && [[ ${urls[0]} != ${urls[1]} ]]; then
            echo "-----------> 第$i集 url 出错 <----------"
            echo "${urls[@]}"
            echo "-----------> <-----------"
            continue
        fi
        url=${urls[0]}
        echo "==> 第$i集 ${#urls[@]} urls: ${urls[@]}"
        echo "==> pick $url"
        out1="$(printf "$collection-%s.mp4" "第$i集")"
        title=$(grep $out1 titles|sed "s/$out1 //"|sed 's| |_|g')
        out2="$(printf "$collection-%s-%s.mp4" "第$i集" "$title")"
        if [ -f $out1 ]; then
            mv -v $out1 $out2
        elif [ -f $out2 ]; then
            echo "--> !! $out2 exists! pass! <--"
            continue
        else
            torun="$(printf "$cmd\n" "$url" "$out2")"
            echo "==> cmd: $torun"
            $torun
        fi
    done
done
    
